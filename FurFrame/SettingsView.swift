//
//  SettingsView.swift
//  FurFrame
//
//  Created by FurFrame on 2026/3/14.
//

import SwiftUI
import SwiftData
import Photos

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var assets: [PetAsset]
    @Query(filter: #Predicate<PetAsset> { $0.isFavorite == true }) private var favoriteAssets: [PetAsset]
    @State private var showPaywall = false
    @State private var isScanning = false
    @State private var scanProgress = 0.0
    @State private var showFavorites = false
    @AppStorage("isPro", store: UserDefaults(suiteName: "group.com.furframe.app")) var isPro: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F2F2F7").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Pro Banner
                        if !isPro {
                            ProBanner {
                                showPaywall = true
                            }
                        }
                        
                        // LIBRARY Section
                        SettingsSection(title: "LIBRARY") {
                            if isScanning {
                                HStack {
                                    ProgressView(value: scanProgress)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .appOrange))
                                    Text("\(Int(scanProgress * 100))%")
                                        .font(.appCaption)
                                        .foregroundColor(.appTextSecondary)
                                        .frame(width: 40)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            } else {
                                SettingsRow(title: "Rescan Photo Library", icon: nil) {
                                    self.startRescan()
                                }
                            }
                            
                            Divider().padding(.leading, 16)
                            
                            SettingsRow(title: "Favorites", value: "\(favoriteAssets.count)") {
                                showFavorites = true
                            }
                            
                            Divider().padding(.leading, 16)
                            
                            SettingsRow(title: "Hidden Pets", value: "0") {
                                // Hidden pets action
                            }
                        }
                        
                        Text("Re-scanning securely processes photos locally on your device without using the internet.")
                            .font(.appCaption)
                            .foregroundColor(.appTextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.top, -12)
                        
                        // ACCOUNT Section
                        SettingsSection(title: "ACCOUNT") {
                            SettingsRow(title: "Restore Purchases", icon: nil) {
                                // Restore action
                            }
                            
                            Divider().padding(.leading, 16)
                            
                            SettingsRow(title: "Manage Subscription", icon: nil) {
                                if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        
                        // ABOUT Section
                        SettingsSection(title: "ABOUT") {
                            SettingsRow(title: "Contact Support", icon: nil) {
                                // Contact action
                            }
                            
                            Divider().padding(.leading, 16)
                            
                            SettingsRow(title: "Privacy Policy", icon: nil) {
                                // Privacy action
                            }
                        }
                        
                        // Version
                        Text("FurFrame v1.0.0")
                            .font(.appCaption)
                            .foregroundColor(.appTextTertiary)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.appCalloutMedium)
                    .foregroundColor(.appOrange)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFavorites) {
            FavoritesSheetView()
        }
    }
    
    private func startRescan() {
        guard !isScanning else { return }
        
        isScanning = true
        scanProgress = 0.0
        
        Task { [self] in
            let scanner = PetScanner(modelContext: modelContext)
            
            // 监听进度
            let progressTask = Task { [self] in
                while isScanning {
                    await MainActor.run {
                        self.scanProgress = scanner.progress
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                }
            }
            
            await scanner.startScan(incremental: false)
            
            // 扫描完成
            progressTask.cancel()
            await MainActor.run {
                self.isScanning = false
                self.scanProgress = 1.0
            }
        }
    }
}

// MARK: - Pro Banner
struct ProBanner: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("FurFrame Pro")
                        .font(.appCalloutMedium)
                        .foregroundColor(.white)
                    
                    Text("Unlock premium themes")
                        .font(.appCaption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FF6B35"), Color(hex: "EC4899")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.appCaptionMedium)
                .foregroundColor(.appTextSecondary)
                .padding(.horizontal, 8)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let title: String
    var value: String? = nil
    var icon: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(.appCallout)
                        .foregroundColor(.appTextSecondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Favorites Sheet View
struct FavoritesSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<PetAsset> { $0.isFavorite == true }, sort: \.creationDate, order: .reverse) private var favoriteAssets: [PetAsset]
    @State private var selectedAsset: PetAsset?
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if favoriteAssets.isEmpty {
                    EmptyFavoritesView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(favoriteAssets) { asset in
                                FavoriteThumbnail(asset: asset) {
                                    selectedAsset = asset
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 34)
                    }
                }
            }
            .navigationTitle("Favorites (\(favoriteAssets.count))")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.appCalloutMedium)
                    .foregroundColor(.appOrange)
                }
            }
            .fullScreenCover(item: $selectedAsset) { asset in
                FullScreenImageView(
                    asset: asset,
                    namespace: Namespace().wrappedValue,
                    onSetAsHero: {
                        for hero in favoriteAssets.filter({ $0.isHero }) {
                            hero.isHero = false
                        }
                        asset.isHero = true
                        try? modelContext.save()
                    },
                    onClose: {
                        selectedAsset = nil
                    }
                )
            }
        }
    }
}

// MARK: - Favorite Thumbnail
struct FavoriteThumbnail: View {
    let asset: PetAsset
    let onTap: () -> Void
    
    var body: some View {
        PHAssetImage(
            localIdentifier: asset.localIdentifier,
            targetSize: CGSize(width: 300, height: 300)
        )
        .aspectRatio(contentMode: .fit)
        .frame(minWidth: 0, maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Empty Favorites View
struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 100)
            
            Image(systemName: "heart.slash")
                .font(.system(size: 70))
                .foregroundColor(.appTextTertiary)
            
            Text("No Favorites Yet")
                .font(.appHeadline3)
                .foregroundColor(.appTextSecondary)
            
            Text("Tap the heart icon on photos\nto add them here.")
                .font(.appCallout)
                .foregroundColor(.appTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
}
