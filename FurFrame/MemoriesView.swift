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
    
    // Grid layout
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "F9F9F7").ignoresSafeArea()
                
                ScrollView {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 0)
                    
                    VStack(spacing: 16) {
                        // Limited access banner
                        if isPhotoLibraryLimited {
                            LimitedAccessBanner()
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                        
                        // Hero Section
                        if let hero = heroAsset ?? assets.randomElement() {
                            HeroSection(asset: hero, namespace: animation, onTap: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    selectedAsset = hero
                                }
                            })
                            .padding(.horizontal)
                        } else {
                            // Empty hero placeholder
                            EmptyHeroView()
                                .padding(.horizontal)
                        }
                        
                        // Section title
                        HStack {
                            Text("All Memories")
                                .font(.title2.weight(.bold))
                            Spacer()
                            Text("\(assets.count) photos")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Masonry Grid
                        if assets.isEmpty {
                            EmptyGridView()
                        } else {
                            MasonryGrid(assets: assets, namespace: animation) { asset in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    selectedAsset = asset
                                }
                            } validateAsset: { asset in
                                validateAsset(asset)
                            }
                        }
                    }
                    .padding(.bottom, 20)
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
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .toolbarBackground(scrollOffset < -100 ? .visible : .hidden, for: .navigationBar)
            .toolbarBackground(Color(hex: "F9F9F7").opacity(0.95), for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .overlay {
                if let selected = selectedAsset {
                    FullScreenImageView(
                        asset: selected,
                        namespace: animation,
                        allAssets: assets,
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
        .onReceive(NotificationCenter.default.publisher(for: .init("RescanPhotos"))) { _ in
            // Handle rescan notification
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
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.title3)
                
                Text("Want to find more fur babies? Tap here to allow full library access.")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(.orange)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Hero Section
struct HeroSection: View {
    let asset: PetAsset
    var namespace: Namespace.ID
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
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .matchedGeometryEffect(id: asset.localIdentifier, in: namespace)
                .onTapGesture(perform: onTap)
                
                // Gradient overlay
                LinearGradient(
                    colors: [.black.opacity(0.6), .black.opacity(0.2), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
                .frame(height: geo.size.height * 0.4)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
                // Date label
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Memory")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(asset.creationDate.formatted(date: .long, time: .omitted))
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                }
                .padding(20)
            }
        }
        .frame(height: UIScreen.main.bounds.height / 3)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Empty Hero View
struct EmptyHeroView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.orange.opacity(0.1))
            
            VStack(spacing: 16) {
                Image(systemName: "pawprint.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.orange.opacity(0.5))
                
                Text("No memories yet")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("Add some pet photos to get started")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.8))
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
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No Photos Found")
                .font(.title3.weight(.semibold))
                .foregroundColor(.gray)
            
            Text("Photos of your pets will appear here once scanned.")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
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
    var onTap: (PetAsset) -> Void
    var validateAsset: (PetAsset) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            let leftColumn = assets.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element }
            let rightColumn = assets.enumerated().filter { $0.offset % 2 != 0 }.map { $0.element }
            
            VStack(spacing: 8) {
                ForEach(leftColumn) { asset in
                    PetCard(asset: asset, namespace: namespace, onTap: onTap, validateAsset: validateAsset)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(rightColumn) { asset in
                    PetCard(asset: asset, namespace: namespace, onTap: onTap, validateAsset: validateAsset)
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Pet Card
struct PetCard: View {
    let asset: PetAsset
    var namespace: Namespace.ID
    var onTap: (PetAsset) -> Void
    var validateAsset: (PetAsset) -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var height: CGFloat = 0
    
    init(asset: PetAsset, namespace: Namespace.ID, onTap: @escaping (PetAsset) -> Void, validateAsset: @escaping (PetAsset) -> Void) {
        self.asset = asset
        self.namespace = namespace
        self.onTap = onTap
        self.validateAsset = validateAsset
        let seed = asset.localIdentifier.hashValue
        self._height = State(initialValue: CGFloat(160 + (abs(seed) % 120)))
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Image
            PHAssetImage(localIdentifier: asset.localIdentifier, targetSize: CGSize(width: 400, height: 400))
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .matchedGeometryEffect(id: asset.localIdentifier, in: namespace)
                .onTapGesture {
                    onTap(asset)
                }
                .onAppear {
                    validateAsset(asset)
                }
            
            // Pet type badge
            HStack(spacing: 4) {
                Image(systemName: asset.petType == "cat" ? "cat" : "dog")
                    .font(.caption2)
                Text(asset.petType.capitalized)
                    .font(.caption2.weight(.medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Favorite button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    asset.isFavorite.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } label: {
                Image(systemName: asset.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(asset.isFavorite ? .red : .white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding(10)
        }
    }
}

// MARK: - Full Screen Image View
struct FullScreenImageView: View {
    let asset: PetAsset
    var namespace: Namespace.ID
    let allAssets: [PetAsset]
    var onSetAsHero: () -> Void
    let onClose: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var showControls = true
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Image with zoom and pan
            PHAssetImage(localIdentifier: asset.localIdentifier, targetSize: PHImageManagerMaximumSize)
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(dragOffset)
                .matchedGeometryEffect(id: asset.localIdentifier, in: namespace)
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
                                    dragOffset = .zero
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                dragOffset = CGSize(
                                    width: dragOffset.width + value.translation.width,
                                    height: dragOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in }
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls.toggle()
                    }
                }
            
            // Controls overlay
            if showControls {
                VStack {
                    // Top bar
                    HStack {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Share button
                        Button {
                            shareAsset(asset)
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: 16) {
                        // Date display
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                            Text(asset.creationDate.formatted(date: .long, time: .shortened))
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        
                        // Action buttons
                        HStack(spacing: 40) {
                            ActionButton(
                                title: "Share",
                                icon: "square.and.arrow.up",
                                color: .white
                            ) {
                                shareAsset(asset)
                            }
                            
                            ActionButton(
                                title: "Set as Hero",
                                icon: "star.fill",
                                color: .orange
                            ) {
                                onSetAsHero()
                                onClose()
                            }
                        }
                    }
                    .padding(.bottom, 40)
                    .padding(.horizontal)
                }
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.4), .clear, .clear, .black.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
                .transition(.opacity)
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

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(color)
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
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
                    Color.gray.opacity(0.15)
                    ProgressView()
                        .scaleEffect(0.8)
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
