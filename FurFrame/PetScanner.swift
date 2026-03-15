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
    
    private var modelContext: ModelContext
    private var scanTask: Task<Void, Never>?
    
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
        
        // Cancel any existing scan
        scanTask?.cancel()
        
        isScanning = true
        progress = 0
        foundCount = 0
        
        // Create a new background task for scanning
        scanTask = Task { [weak self] in
            guard let self = self else { return }
            
            // Get all assets on background thread
            let assets = await self.fetchAssets(incremental: incremental)
            let total = assets.count
            
            guard total > 0 else {
                await MainActor.run {
                    self.isScanning = false
                    self.hasScanned = true
                }
                return
            }
            
            let phrases = [
                "Sniffing for dogs...",
                "Looking for cats...",
                "Organizing memories...",
                "Finding fur babies..."
            ]
            var phraseIndex = 0
            
            await MainActor.run {
                self.progressText = phrases[0]
            }
            
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .fastFormat
            requestOptions.isNetworkAccessAllowed = true
            
            let phraseUpdateInterval = max(total / 8, 1)
            
            for i in 0..<total {
                // Check for cancellation
                if Task.isCancelled { break }
                
                let asset = assets[i]
                let currentProgress = Double(i + 1) / Double(total)
                
                // Update text periodically
                if i % phraseUpdateInterval == 0 {
                    phraseIndex = (phraseIndex + 1) % phrases.count
                    let text = phrases[phraseIndex]
                    await MainActor.run {
                        self.progressText = text
                    }
                }
                
                // Check if already in database
                if !incremental {
                    let id = asset.localIdentifier
                    let exists = await MainActor.run { self.assetExists(id: id) }
                    if exists {
                        await MainActor.run {
                            self.progress = currentProgress
                        }
                        continue
                    }
                }
                
                // Analyze asset
                let foundPet = await self.analyzeAsset(asset, imageManager: imageManager, requestOptions: requestOptions)
                
                if foundPet {
                    await MainActor.run {
                        self.foundCount += 1
                    }
                }
                
                await MainActor.run {
                    self.progress = currentProgress
                }
                
                // Small delay to allow UI updates
                if i % 5 == 0 {
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                }
            }
            
            await MainActor.run {
                UserDefaults.standard.set(Date(), forKey: "lastScanDate")
                self.isScanning = false
                self.hasScanned = true
            }
        }
        
        // Wait for scan to complete
        await scanTask?.value
    }
    
    private func fetchAssets(incremental: Bool) async -> [PHAsset] {
        await Task.detached(priority: .userInitiated) {
            let fetchOptions = PHFetchOptions()
            if incremental {
                let lastScanDate = UserDefaults.standard.object(forKey: "lastScanDate") as? Date ?? Date.distantPast
                fetchOptions.predicate = NSPredicate(format: "creationDate > %@", lastScanDate as NSDate)
            }
            
            let allAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var assets: [PHAsset] = []
            for i in 0..<allAssets.count {
                assets.append(allAssets.object(at: i))
            }
            return assets
        }.value
    }
    
    private func assetExists(id: String) -> Bool {
        let descriptor = FetchDescriptor<PetAsset>(predicate: #Predicate { $0.localIdentifier == id })
        return (try? modelContext.fetchCount(descriptor)) ?? 0 > 0
    }
    
    private func analyzeAsset(_ asset: PHAsset, imageManager: PHImageManager, requestOptions: PHImageRequestOptions) async -> Bool {
        await Task.detached(priority: .userInitiated) { [weak self] () -> Bool in
            guard let self = self else { return false }
            
            return await withCheckedContinuation { continuation in
                imageManager.requestImage(
                    for: asset,
                    targetSize: CGSize(width: 300, height: 300),
                    contentMode: .aspectFill,
                    options: requestOptions
                ) { image, _ in
                    guard let image = image, let cgImage = image.cgImage else {
                        continuation.resume(returning: false)
                        return
                    }
                    
                    let request = VNRecognizeAnimalsRequest { request, error in
                        guard let results = request.results as? [VNRecognizedObjectObservation], error == nil else {
                            continuation.resume(returning: false)
                            return
                        }
                        
                        var petType: String? = nil
                        for result in results {
                            if result.labels.contains(where: { $0.identifier == "Cat" }) {
                                petType = "cat"
                                break
                            } else if result.labels.contains(where: { $0.identifier == "Dog" }) {
                                petType = "dog"
                                break
                            }
                        }
                        
                        if let type = petType {
                            // Return true, insertion will be done on main actor
                            continuation.resume(returning: true)
                            // Insert on main actor
                            Task { @MainActor in
                                let petAsset = PetAsset(
                                    localIdentifier: asset.localIdentifier,
                                    isFavorite: false,
                                    creationDate: asset.creationDate ?? Date(),
                                    petType: type
                                )
                                self.modelContext.insert(petAsset)
                            }
                        } else {
                            continuation.resume(returning: false)
                        }
                    }
                    
                    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    try? handler.perform([request])
                }
            }
        }.value
    }
}
