//
//  PetScanner.swift
//  FurFrame
//
//  Created by Adward on 2026/3/14.
//

import Photos
import Vision
import SwiftData
import SwiftUI
import Combine
import os.log

enum PhotoAccessStatus {
    case notDetermined
    case authorized
    case limited
    case denied
}

@MainActor
class PetScanner: ObservableObject {
    @Published var isScanning = false
    @Published var progressText = ""
    @Published var progress: Double = 0.0
    @Published var foundCount = 0
    @Published var hasScanned = false
    @Published var accessStatus: PhotoAccessStatus = .notDetermined
    @Published var debugLog: String = "" // 调试用日志
    
    private var modelContext: ModelContext
    private var scanTask: Task<Void, Never>?
    private let logger = Logger(subsystem: "com.furframe.app", category: "PetScanner")
    
    // 识别配置
    private let targetSize = CGSize(width: 600, height: 600) // 增大尺寸提高识别率
    private let confidenceThreshold: Float = 0.5 // 置信度阈值 50%
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkAccessStatus()
    }
    
    func checkAccessStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:
            accessStatus = .notDetermined
        case .authorized:
            accessStatus = .authorized
        case .limited:
            accessStatus = .limited
        case .denied, .restricted:
            accessStatus = .denied
        @unknown default:
            accessStatus = .notDetermined
        }
    }
    
    func requestPermissionAndStartScan() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        checkAccessStatus()
        
        if status == .authorized || status == .limited {
            await startScan()
        }
    }
    
    func startScan(incremental: Bool = false) async {
        guard accessStatus == .authorized || accessStatus == .limited else { return }
        guard !isScanning else { return }
        
        // Cancel any existing scan
        scanTask?.cancel()
        
        // Reset state
        isScanning = true
        hasScanned = false
        progress = 0
        foundCount = 0
        debugLog = "开始扫描...\n"
        
        logger.info("开始扫描照片库")
        
        // Fetch assets first
        let assets = await fetchAssets(incremental: incremental)
        let total = assets.count
        
        debugLog += "找到 \(total) 张照片\n"
        logger.info("找到 \(total) 张照片")
        
        guard total > 0 else {
            isScanning = false
            hasScanned = true
            debugLog += "没有照片需要扫描\n"
            return
        }
        
        let phrases = [
            "Sniffing for dogs...",
            "Looking for cats...",
            "Organizing memories...",
            "Finding fur babies..."
        ]
        var phraseIndex = 0
        progressText = phrases[0]
        
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false // 改为异步避免阻塞
        requestOptions.deliveryMode = .fastFormat // 先用快速格式
        requestOptions.isNetworkAccessAllowed = false // 先不下载iCloud照片
        
        let phraseUpdateInterval = max(total / 8, 1)
        var processedCount = 0
        var foundPetsCount = 0
        
        for i in 0..<total {
            // Check for cancellation
            if Task.isCancelled { break }
            
            let asset = assets[i]
            let currentProgress = Double(i + 1) / Double(total)
            
            // Update text periodically
            if i % phraseUpdateInterval == 0 {
                phraseIndex = (phraseIndex + 1) % phrases.count
                progressText = phrases[phraseIndex]
            }
            
            // Update UI progress
            progress = currentProgress
            
            // Check if already in database
            if !incremental {
                let id = asset.localIdentifier
                if assetExists(id: id) {
                    processedCount += 1
                    continue
                }
            }
            
            // Analyze asset - 每5张照片yield一次让UI更新
            let (foundPet, debugInfo) = await analyzeAsset(asset, imageManager: imageManager, requestOptions: requestOptions)
            
            if foundPet {
                foundPetsCount += 1
                foundCount += 1
            }
            
            processedCount += 1
            
            // Update debug log
            if i % 10 == 0 || foundPet {
                debugLog += debugInfo + "\n"
            }
            
            // 每5张照片让出时间片给UI
            if i % 5 == 0 {
                try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
            }
        }
        
        UserDefaults.standard.set(Date(), forKey: "lastScanDate")
        isScanning = false
        hasScanned = true
        progress = 1.0
        debugLog += "\n扫描完成！处理了 \(processedCount) 张照片，找到 \(foundPetsCount) 个宠物\n"
        logger.info("扫描完成！处理了 \(processedCount) 张照片，找到 \(foundPetsCount) 个宠物")
    }
    
    private func fetchAssets(incremental: Bool) async -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        if incremental {
            let lastScanDate = UserDefaults.standard.object(forKey: "lastScanDate") as? Date ?? Date.distantPast
            fetchOptions.predicate = NSPredicate(format: "creationDate > %@", lastScanDate as NSDate)
        }
        
        let allAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var assets: [PHAsset] = []
        for i in 0..<allAssets.count {
            assets.append(allAssets.object(at: i))
            // 每100张照片让出一次时间片
            if i % 100 == 0 {
                await Task.yield()
            }
        }
        return assets
    }
    
    private func assetExists(id: String) -> Bool {
        let descriptor = FetchDescriptor<PetAsset>(predicate: #Predicate { $0.localIdentifier == id })
        return (try? modelContext.fetchCount(descriptor)) ?? 0 > 0
    }
    
    // 返回 (是否找到宠物, 调试信息)
    private func analyzeAsset(_ asset: PHAsset, imageManager: PHImageManager, requestOptions: PHImageRequestOptions) async -> (Bool, String) {
        let assetID = asset.localIdentifier.prefix(20)
        
        // 使用 continuation 处理异步回调
        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: self.targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            ) { [weak self] image, info in
                guard let self = self else {
                    continuation.resume(returning: (false, "[\(assetID)] scanner released"))
                    return
                }
                
                // 检查是否有错误
                if let error = info?[PHImageErrorKey] as? Error {
                    self.logger.error("图片加载错误: \(error.localizedDescription)")
                    continuation.resume(returning: (false, "[\(assetID)] 加载失败"))
                    return
                }
                
                guard let image = image, let cgImage = image.cgImage else {
                    continuation.resume(returning: (false, "[\(assetID)] 无法获取图片"))
                    return
                }
                
                // 使用 Vision 框架识别动物
                let request = VNRecognizeAnimalsRequest { [weak self] request, error in
                    guard let self = self else {
                        continuation.resume(returning: (false, "[\(assetID)] scanner released"))
                        return
                    }
                    
                    if let error = error {
                        self.logger.error("Vision识别错误: \(error.localizedDescription)")
                        continuation.resume(returning: (false, "[\(assetID)] 识别错误"))
                        return
                    }
                    
                    guard let results = request.results as? [VNRecognizedObjectObservation] else {
                        continuation.resume(returning: (false, "[\(assetID)] 无识别结果"))
                        return
                    }
                    
                    // 详细检查每个识别结果
                    var bestPet: (type: String, confidence: Float)? = nil
                    var allLabels: [String] = []
                    
                    for result in results {
                        for label in result.labels {
                            allLabels.append("\(label.identifier)(\(String(format: "%.2f", label.confidence)))")
                            
                            let confidence = label.confidence
                            let identifier = label.identifier
                            
                            // 检查是否是猫或狗，并且置信度超过阈值
                            if (identifier == "Cat" || identifier == "Dog") && confidence >= self.confidenceThreshold {
                                if bestPet == nil || confidence > bestPet!.confidence {
                                    bestPet = (identifier.lowercased(), confidence)
                                }
                            }
                        }
                    }
                    
                    if let pet = bestPet {
                        // 找到宠物，保存到数据库（需要回主线程）
                        Task { @MainActor in
                            let petAsset = PetAsset(
                                localIdentifier: asset.localIdentifier,
                                isFavorite: false,
                                creationDate: asset.creationDate ?? Date(),
                                petType: pet.type
                            )
                            self.modelContext.insert(petAsset)
                            try? self.modelContext.save()
                        }
                        
                        let logMsg = "[\(assetID)] 找到 \(pet.type) 置信度: \(String(format: "%.2f", pet.confidence)) | 所有标签: \(allLabels.joined(separator: ", "))"
                        self.logger.info("\(logMsg)")
                        continuation.resume(returning: (true, logMsg))
                    } else {
                        // 没有找到宠物
                        let logMsg = allLabels.isEmpty 
                            ? "[\(assetID)] 未识别到动物"
                            : "[\(assetID)] 识别到但置信度不足或不是猫狗: \(allLabels.joined(separator: ", "))"
                        continuation.resume(returning: (false, logMsg))
                    }
                }
                
                // 执行识别请求
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    self.logger.error("Vision请求执行错误: \(error.localizedDescription)")
                    continuation.resume(returning: (false, "[\(assetID)] Vision执行失败"))
                }
            }
        }
    }
}
