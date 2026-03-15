//
//  MemoriesView.swift
//  FurFrame
//
//  Created by Adward on 2026/3/14.
//

import SwiftUI
import SwiftData
import Photos

struct MemoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PetAsset.creationDate, order: .reverse) private var assets: [PetAsset]
    @State private var heroAsset: PetAsset?
    @Namespace private var animation
    @State private var selectedAsset: PetAsset?
    @State private var isPhotoLibraryLimited = false
    @State private var showSettings = false
    @State private var scrollOffset: CGFloat = 0
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 0)
                    
                    VStack(spacing: 0) {
                        // Limited access banner
                        if isPhotoLibraryLimited {
                            LimitedAccessBanner()
                                .padding(.horizontal, .appSpacingLarge)
                                .padding(.top, .appSpacingMedium)
                        }
                        
                        // Hero Section
                        if let hero = heroAsset ?? assets.randomElement() {
                            let heroIsSelected = selectedAsset?.localIdentifier == hero.localIdentifier
                            HeroSection(
                                asset: hero,
                                namespace: animation,
                                isSelected: heroIsSelected,
                                onTap: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        selectedAsset = hero
                                    }
                                }
                            )
                            .padding(.horizontal, .appSpacingLarge)
                            .padding(.top, .appSpacingMedium)
                        }
                        
                        // Section Title
                        HStack {
                            Text("All Pets")
                                .font(.appHeadline3)
                            Spacer()
                        }
                        .padding(.horizontal, .appSpacingLarge)
                        .padding(.top, .appSpacingXLarge)
                        .padding(.bottom, .appSpacingMedium)
                        
                        // Masonry Grid
                        if assets.isEmpty {
                            EmptyGridView()
                        } else {
                            MasonryGrid(
                                assets: assets,
                                namespace: animation,
                                selectedAssetId: selectedAsset?.localIdentifier,
                                validateAsset: { asset in
                                    validateAsset(asset)
                                },
                                onTap: { asset in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        selectedAsset = asset
                                    }
                                }
                            )
                        }
                    }
                    .padding(.bottom, .appSpacingLarge)
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
            }
            .navigationTitle("Memories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            // Widget grid view
                        } label: {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 20))
                                .foregroundColor(.appTextPrimary)
                        }
                        
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .font(.system(size: 20))
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                }
            }
            .toolbarBackground(scrollOffset < -100 ? .visible : .hidden, for: .navigationBar)
            .toolbarBackground(.white, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .overlay {
                if let selected = selectedAsset {
                    FullScreenImageView(
                        asset: selected,
                        namespace: animation,
                        onSetAsHero: {
                            withAnimation(.spring()) {
                                heroAsset = selected
                            }
                        },
                        onClose: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                selectedAsset = nil
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            checkPhotoLibraryStatus()
            if heroAsset == nil && !assets.isEmpty {
                heroAsset = assets.randomElement()
            }
        }
    }
    
    private func checkPhotoLibraryStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        isPhotoLibraryLimited = (status == .limited)
    }
    
    private func validateAsset(_ asset: PetAsset) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [asset.localIdentifier], options: nil)
        if fetchResult.firstObject == nil {
            modelContext.delete(asset)
        }
    }
}

// MARK: - Scroll Offset Preference
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Limited Access Banner
struct LimitedAccessBanner: View {
    var body: some View {
        Button {
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                
                Text("Tap to allow full photo access")
                    .font(.appCalloutMedium)
                    .lineLimit(1)
                
                Spacer()
            }
            .foregroundColor(.appTextPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appWarning)
            .cornerRadius(.appRadiusXLarge)
        }
    }
}

// MARK: - Hero Section
struct HeroSection: View {
    let asset: PetAsset
    var namespace: Namespace.ID
    var isSelected: Bool
    var onTap: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                // Image
                PHAssetImage(
                    localIdentifier: asset.localIdentifier,
                    targetSize: CGSize(width: geo.size.width * 2, height: geo.size.height * 2)
                )
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipShape(RoundedRectangle(cornerRadius: .appRadiusXXLarge))
                .matchedGeometryEffect(id: asset.localIdentifier, in: namespace, isSource: !isSelected)
                .onTapGesture(perform: onTap)
                
                // Gradient overlay
                LinearGradient(
                    colors: [.black.opacity(0.6), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
                .frame(height: geo.size.height * 0.4)
                .clipShape(RoundedRectangle(cornerRadius: .appRadiusXXLarge))
                
                // Content
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Golden Hour")
                            .font(.appHeadline2)
                            .foregroundColor(.white)
                        
                        Text(asset.creationDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.appCallout)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Favorite button
                    Button {
                        withAnimation(.spring()) {
                            asset.isFavorite.toggle()
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        Image(systemName: asset.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(asset.isFavorite ? .appError : .white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(20)
            }
        }
        .frame(height: UIScreen.main.bounds.height / 3)
    }
}

// MARK: - Empty Grid View
struct EmptyGridView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)
            
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 70))
                .foregroundColor(.appTextTertiary)
            
            Text("No Photos Found")
                .font(.appHeadline3)
                .foregroundColor(.appTextSecondary)
            
            Text("Photos of your pets will appear here once scanned.")
                .font(.appCallout)
                .foregroundColor(.appTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Masonry Grid
struct MasonryGrid: View {
    let assets: [PetAsset]
    var namespace: Namespace.ID
    var selectedAssetId: String?
    var validateAsset: (PetAsset) -> Void
    var onTap: (PetAsset) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            let leftColumn = assets.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element }
            let rightColumn = assets.enumerated().filter { $0.offset % 2 != 0 }.map { $0.element }
            
            VStack(spacing: 8) {
                ForEach(leftColumn) { asset in
                    PetCard(
                        asset: asset,
                        namespace: namespace,
                        isSelected: selectedAssetId == asset.localIdentifier,
                        validateAsset: validateAsset,
                        onTap: onTap
                    )
                }
            }
            
            VStack(spacing: 8) {
                ForEach(rightColumn) { asset in
                    PetCard(
                        asset: asset,
                        namespace: namespace,
                        isSelected: selectedAssetId == asset.localIdentifier,
                        validateAsset: validateAsset,
                        onTap: onTap
                    )
                }
            }
        }
        .padding(.horizontal, .appSpacingLarge)
    }
}

// MARK: - Pet Card
struct PetCard: View {
    let asset: PetAsset
    var namespace: Namespace.ID
    var isSelected: Bool
    var validateAsset: (PetAsset) -> Void
    var onTap: (PetAsset) -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var height: CGFloat = 0
    
    init(asset: PetAsset, namespace: Namespace.ID, isSelected: Bool, validateAsset: @escaping (PetAsset) -> Void, onTap: @escaping (PetAsset) -> Void) {
        self.asset = asset
        self.namespace = namespace
        self.isSelected = isSelected
        self.validateAsset = validateAsset
        self.onTap = onTap
        let seed = asset.localIdentifier.hashValue
        self._height = State(initialValue: CGFloat(160 + (abs(seed) % 120)))
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PHAssetImage(localIdentifier: asset.localIdentifier, targetSize: CGSize(width: 400, height: 400))
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: .appRadiusLarge))
                .matchedGeometryEffect(id: asset.localIdentifier, in: namespace, isSource: !isSelected)
                .onTapGesture {
                    onTap(asset)
                }
                .onAppear {
                    validateAsset(asset)
                }
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    asset.isFavorite.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } label: {
                Image(systemName: asset.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(asset.isFavorite ? .appError : .white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(10)
        }
    }
}

// MARK: - Full Screen Image View
struct FullScreenImageView: View {
    let asset: PetAsset
    var namespace: Namespace.ID
    var onSetAsHero: () -> Void
    let onClose: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Image
            PHAssetImage(localIdentifier: asset.localIdentifier, targetSize: PHImageManagerMaximumSize)
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale *= delta
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            if scale < 1.0 {
                                withAnimation(.spring()) {
                                    scale = 1.0
                                }
                            }
                        }
                )
                .matchedGeometryEffect(id: asset.localIdentifier, in: namespace, isSource: true)
            
            // Top Bar
            VStack {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(asset.creationDate.formatted(date: .long, time: .omitted))
                        .font(.appCalloutMedium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                Spacer()
                
                // Bottom Glass Bar
                HStack(spacing: 0) {
                    Button {
                        shareAsset(asset)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.square")
                            Text("Share")
                        }
                        .font(.appCalloutMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .frame(height: 24)
                    
                    Button {
                        onSetAsHero()
                        onClose()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Set as Hero")
                        }
                        .font(.appCalloutMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: .appRadiusXLarge))
                .padding(.horizontal, .appSpacingLarge)
                .padding(.bottom, 34)
            }
        }
    }
    
    private func shareAsset(_ asset: PetAsset) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [asset.localIdentifier], options: nil)
        guard let phAsset = fetchResult.firstObject else { return }
        
        PHImageManager.default().requestImage(for: phAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil) { image, _ in
            if let image = image {
                let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(av, animated: true)
                }
            }
        }
    }
}

// MARK: - PH Asset Image
struct PHAssetImage: View {
    let localIdentifier: String
    let targetSize: CGSize
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else {
                ZStack {
                    Color.appSecondaryBackground
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.appOrange)
                }
                .onAppear {
                    loadImage()
                }
            }
        }
    }
    
    private func loadImage() {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        if let asset = fetchResult.firstObject {
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { result, _ in
                self.image = result
            }
        }
    }
}

#Preview {
    MemoriesView()
}
