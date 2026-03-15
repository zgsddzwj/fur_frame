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
        
        isScanning = true
        progress = 0
        foundCount = 0
        
        let fetchOptions = PHFetchOptions()
        if incremental {
            let lastScanDate = UserDefaults.standard.object(forKey: "lastScanDate") as? Date ?? Date.distantPast
            fetchOptions.predicate = NSPredicate(format: "creationDate > %@", lastScanDate as NSDate)
        }
        
        let allAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let total = allAssets.count
        
        guard total > 0 else {
            isScanning = false
            hasScanned = true
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
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .fastFormat
        requestOptions.isNetworkAccessAllowed = true
        
        let phraseUpdateInterval = max(total / 8, 1)
        
        for i in 0..<total {
            let asset = allAssets.object(at: i)
            
            if i % phraseUpdateInterval == 0 {
                phraseIndex = (phraseIndex + 1) % phrases.count
                progressText = phrases[phraseIndex]
            }
            
            if !incremental {
                let id = asset.localIdentifier
                let descriptor = FetchDescriptor<PetAsset>(predicate: #Predicate { $0.localIdentifier == id })
                if (try? modelContext.fetchCount(descriptor)) ?? 0 > 0 {
                    progress = Double(i + 1) / Double(total)
                    continue
                }
            }
            
            await analyzeAsset(asset, imageManager: imageManager, requestOptions: requestOptions)
            progress = Double(i + 1) / Double(total)
        }
        
        UserDefaults.standard.set(Date(), forKey: "lastScanDate")
        isScanning = false
        hasScanned = true
    }
    
    private func analyzeAsset(_ asset: PHAsset, imageManager: PHImageManager, requestOptions: PHImageRequestOptions) async {
        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 300, height: 300),
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, _ in
                guard let image = image, let cgImage = image.cgImage else {
                    continuation.resume()
                    return
                }
                
                let request = VNRecognizeAnimalsRequest { request, error in
                    guard let results = request.results as? [VNRecognizedObjectObservation], error == nil else {
                        continuation.resume()
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
                        Task { @MainActor in
                            let petAsset = PetAsset(
                                localIdentifier: asset.localIdentifier,
                                isFavorite: false,
                                creationDate: asset.creationDate ?? Date(),
                                petType: type
                            )
                            self.modelContext.insert(petAsset)
                            self.foundCount += 1
                        }
                    }
                    continuation.resume()
                }
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
        }
    }
}
