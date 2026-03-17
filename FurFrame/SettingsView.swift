//
//  SettingsView.swift
//  FurFrame
//
//  Created by FurFrame on 2026/3/14.
//

import SwiftUI
import SwiftData
import Photos
import Combine

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var assets: [PetAsset]
    @Query(filter: #Predicate<PetAsset> { $0.isFavorite == true }) private var favoriteAssets: [PetAsset]
    @Query(filter: #Predicate<PetAsset> { $0.isHidden == true }) private var hiddenAssets: [PetAsset]
    @State private var showPaywall = false
    @State private var showScanningView = false
    @StateObject private var scanner = PetScanner(modelContext: ModelContext(try! ModelContainer(for: Schema([PetAsset.self]))))
    @State private var showFavorites = false
    @State private var showHiddenPets = false
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
                            SettingsRow(title: "Rescan Photo Library", icon: nil) {
                                self.startRescan()
                            }
                            
                            Divider().padding(.leading, 16)
                            
                            SettingsRow(title: "Favorites", value: "\(favoriteAssets.count)") {
                                showFavorites = true
                            }
                            
                            Divider().padding(.leading, 16)
                            
                            SettingsRow(title: "Hidden Pets", value: "\(hiddenAssets.count)") {
                                showHiddenPets = true
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
        .sheet(isPresented: $showHiddenPets) {
            HiddenPetsSheetView()
        }
        .fullScreenCover(isPresented: $showScanningView) {
            ScanningPageView(scanner: scanner, onComplete: {
                showScanningView = false
            })
        }
    }
    
    private func startRescan() {
        showScanningView = true
        
        Task {
            await scanner.startScan(incremental: false)
        }
    }
}

// MARK: - Scanning Page View
struct ScanningPageView: View {
    @ObservedObject var scanner: PetScanner
    let onComplete: () -> Void
    
    @State private var pawOffset: CGFloat = 0
    @State private var dotCount = 0
    @State private var timerCancellable: Cancellable?
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(hex: "F9F9F7"),
                    Color(hex: "FFF8F5")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 48) {
                Spacer()
                
                // Animated paw print
                ZStack {
                    // Outer glow circles
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.appOrange.opacity(0.1), lineWidth: 1)
                            .frame(width: 160 + CGFloat(i * 40), height: 160 + CGFloat(i * 40))
                            .scaleEffect(1 + pawOffset * 0.05)
                            .animation(
                                .easeInOut(duration: 2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3),
                                value: pawOffset
                            )
                    }
                    
                    // Main paw icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appOrange, Color.appOrange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    .offset(y: pawOffset)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            pawOffset = -8
                        }
                    }
                }
                
                // Progress info
                VStack(spacing: 20) {
                    // Progress bar
                    VStack(spacing: 12) {
                        HStack {
                            Text("\(Int(scanner.progress * 100))%")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                            
                            Spacer()
                            
                            Text("\(scanner.foundCount) pets found")
                                .font(.appCallout)
                                .foregroundColor(.appOrange)
                        }
                        
                        // Progress track
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.appOrange.opacity(0.15))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.appOrange, Color(hex: "FF8C61")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * scanner.progress, height: 8)
                                    .animation(.easeInOut(duration: 0.3), value: scanner.progress)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 40)
                    
                    // Status text with animated dots
                    VStack(spacing: 8) {
                        Text(displayText)
                            .font(.appHeadline3)
                            .foregroundColor(.appTextPrimary)
                        
                        Text("Photos never leave your device")
                            .font(.appCaption)
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 60)
        }
        .onAppear {
            // Start timer for dots animation
            let timer = Timer.publish(every: 0.5, on: .main, in: .common)
            timerCancellable = timer.sink { _ in
                if !scanner.hasScanned {
                    dotCount = (dotCount + 1) % 4
                }
            }
            timer.connect()
        }
        .onChange(of: scanner.hasScanned) { _, hasScanned in
            if hasScanned {
                // Stop timer and trigger completion
                timerCancellable?.cancel()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    onComplete()
                }
            }
        }
        .onDisappear {
            timerCancellable?.cancel()
        }
    }
    
    private var displayText: String {
        if scanner.hasScanned {
            return "Done!"
        } else {
            return scanner.progressText + String(repeating: ".", count: dotCount)
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

// MARK: - Hidden Pets Sheet View
struct HiddenPetsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<PetAsset> { $0.isHidden == true }, sort: \.creationDate, order: .reverse) private var hiddenAssets: [PetAsset]
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if hiddenAssets.isEmpty {
                    EmptyHiddenPetsView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(hiddenAssets) { asset in
                                HiddenPetThumbnail(asset: asset) {
                                    // Unhide action
                                    withAnimation(.spring()) {
                                        asset.isHidden = false
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 34)
                    }
                }
            }
            .navigationTitle("Hidden Pets (\(hiddenAssets.count))")
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
        }
    }
}

// MARK: - Hidden Pet Thumbnail
struct HiddenPetThumbnail: View {
    let asset: PetAsset
    let onUnhide: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            PHAssetImage(
                localIdentifier: asset.localIdentifier,
                targetSize: CGSize(width: 300, height: 300)
            )
            .aspectRatio(contentMode: .fit)
            .frame(minWidth: 0, maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(0.6) // Dimmed to indicate hidden status
            
            // Unhide button
            Button {
                onUnhide()
            } label: {
                Image(systemName: "eye")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.appOrange)
                    .clipShape(Circle())
            }
            .padding(8)
        }
    }
}

// MARK: - Empty Hidden Pets View
struct EmptyHiddenPetsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 100)
            
            Image(systemName: "eye")
                .font(.system(size: 70))
                .foregroundColor(.appTextTertiary)
            
            Text("No Hidden Pets")
                .font(.appHeadline3)
                .foregroundColor(.appTextSecondary)
            
            Text("Tap the eye icon on photos\nto hide them from the main view.")
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
