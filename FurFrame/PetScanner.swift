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

@MainActor
class PetScanner: ObservableObject {
    @Published var isScanning = false
    @Published var progressText = ""
    @Published var progress: Double = 0.0
    @Published var foundCount = 0
    @Published var hasScanned = false
    @Published var currentPhase: ScanPhase = .initial
    
    enum ScanPhase {
        case initial, requestingPermission, scanning, completed, error
    }
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func requestPermissionAndStartScan() async {
        currentPhase = .requestingPermission
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        if status == .authorized || status == .limited {
            await startScan()
        } else {
            currentPhase = .error
        }
    }
    
    func startScan(incremental: Bool = false) async {
        isScanning = true
        currentPhase = .scanning
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
            currentPhase = .completed
            return
        }
        
        // Progress text
        let phrases = [
            "Sniffing for dogs...",
            "Looking for cats...",
            "Organizing memories...",
            "Finding fur babies..."
        ]
        progressText = phrases[0]
        
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .fastFormat
        requestOptions.isNetworkAccessAllowed = true
        
        var phraseIndex = 0
        let phraseUpdateInterval = max(total / 10, 1)
        
        for i in 0..<total {
            let asset = allAssets.object(at: i)
            
            // Update phrase periodically
            if i % phraseUpdateInterval == 0 {
                phraseIndex = (phraseIndex + 1) % phrases.count
                progressText = phrases[phraseIndex]
            }
            
            // Skip if already in database
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
        currentPhase = .completed
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
