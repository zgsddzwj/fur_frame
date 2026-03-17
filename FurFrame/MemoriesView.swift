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
    @Query(filter: #Predicate<PetAsset> { $0.isHidden == false }, sort: \.creationDate, order: .reverse) private var assets: [PetAsset]
    @Query(filter: #Predicate<PetAsset> { $0.isHero == true && $0.isHidden == false }) private var heroAssets: [PetAsset]
    @Namespace private var animation
    @State private var selectedAsset: PetAsset?
    @State private var heroRefreshTrigger = UUID()
    @State private var isPhotoLibraryLimited = false
    @State private var showSettings = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isScanning = false
    @State private var scanProgress = 0.0
    
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
                        if let hero = heroAssets.first ?? assets.randomElement() {
                            HeroSection(
                                asset: hero,
                                namespace: animation,
                                onTap: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        selectedAsset = hero
                                    }
                                }
                            )
                            .id(heroRefreshTrigger)
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
                        if isScanning {
                            ScanningProgressView(progress: scanProgress)
                        } else if assets.isEmpty {
                            EmptyGridView {
                                self.startRescan()
                            }
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
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.system(size: 20))
                            .foregroundColor(.appTextPrimary)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(item: $selectedAsset) { asset in
                FullScreenImageView(
                    asset: asset,
                    namespace: animation,
                    onSetAsHero: {
                        // 清除之前的 Hero 标记
                        for hero in heroAssets {
                            hero.isHero = false
                        }
                        // 设置新的 Hero
                        asset.isHero = true
                        try? modelContext.save()
                        // 强制刷新 Hero Section
                        heroRefreshTrigger = UUID()
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
        .onAppear {
            checkPhotoLibraryStatus()
            // 配置导航栏外观 - 隐藏底部横线
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            // 如果没有设置 Hero，随机选择一个作为默认 Hero
            if heroAssets.isEmpty && !assets.isEmpty {
                if let randomAsset = assets.randomElement() {
                    randomAsset.isHero = true
                    try? modelContext.save()
                }
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

// MARK: - Scanning Progress View
struct ScanningProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 100)
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(.appOrange)
            
            Text("Scanning Photos...")
                .font(.appHeadline3)
                .foregroundColor(.appTextPrimary)
            
            Text("\(Int(progress * 100))%")
                .font(.appCallout)
                .foregroundColor(.appTextSecondary)
            
            Spacer()
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
    var onTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Image - 固定高度，限制裁剪区域防止长图撑满
            PHAssetImage(
                localIdentifier: asset.localIdentifier,
                targetSize: CGSize(width: 800, height: 600)
            )
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: .appRadiusXXLarge))
            .onTapGesture(perform: onTap)
            
            // Gradient overlay
            LinearGradient(
                colors: [.black.opacity(0.6), .clear],
                startPoint: .bottom,
                endPoint: .center
            )
            .frame(height: 140)
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
        .frame(height: 280)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Empty Grid View
struct EmptyGridView: View {
    var onRescan: () -> Void
    
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
            
            Button {
                onRescan()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Rescan Photo Library")
                }
                .font(.appCalloutMedium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.appOrange)
                .cornerRadius(.appRadiusCapsule)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
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
                .aspectRatio(contentMode: .fit)
                .frame(minWidth: 0, maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: .appRadiusLarge))
                .matchedGeometryEffect(id: asset.localIdentifier, in: namespace, isSource: !isSelected)
                .onTapGesture {
                    onTap(asset)
                }
                .onAppear {
                    validateAsset(asset)
                }
            
            VStack(spacing: 8) {
                // Hide button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        asset.isHidden = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                // Favorite button
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
    @State private var fullImage: UIImage?
    @State private var isLoadingFullImage = false
    
    var body: some View {
        ZStack {
            // 全黑背景，阻止点击穿透
            Color.black
                .ignoresSafeArea()
                .contentShape(Rectangle())
            
            // Image - 使用 aspectFit 模式加载原图
            PHAssetImage(
                localIdentifier: asset.localIdentifier,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit
            )
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
            .onAppear {
                // 预加载高清原图用于分享
                preloadFullImage()
            }
        }
        .overlay(alignment: .top) {
            // Top Bar - 使用 safeAreaInset 布局
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
            .padding(.top, 8)
            .padding(.bottom, 16)
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.5), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .top)
            )
        }
        .overlay(alignment: .bottom) {
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
    
    private func preloadFullImage() {
        guard fullImage == nil, !isLoadingFullImage else { return }
        isLoadingFullImage = true
        
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [asset.localIdentifier], options: nil)
        guard let phAsset = fetchResult.firstObject else {
            isLoadingFullImage = false
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            PHImageManager.default().requestImage(for: phAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { image, _ in
                DispatchQueue.main.async {
                    self.fullImage = image
                    self.isLoadingFullImage = false
                }
            }
        }
    }
    
    private func shareAsset(_ asset: PetAsset) {
        // 优先使用预加载的图片，如果没有则使用当前显示的图片
        if let image = fullImage {
            presentShareController(with: image)
        } else {
            // 后备方案：如果还没加载完，显示加载提示
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [asset.localIdentifier], options: nil)
            guard let phAsset = fetchResult.firstObject else { return }
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            DispatchQueue.global(qos: .userInitiated).async {
                PHImageManager.default().requestImage(for: phAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { image, _ in
                    DispatchQueue.main.async {
                        if let image = image {
                            self.fullImage = image
                            self.presentShareController(with: image)
                        }
                    }
                }
            }
        }
    }
    
    private func presentShareController(with image: UIImage) {
        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}

// MARK: - PH Asset Image
struct PHAssetImage: View {
    let localIdentifier: String
    let targetSize: CGSize
    var contentMode: PHImageContentMode = .aspectFill
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else {
                ZStack {
                    Color.appSecondaryBackground
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.appOrange)
                    }
                }
                .onAppear {
                    loadImage()
                }
            }
        }
    }
    
    private func loadImage() {
        guard !isLoading else { return }
        isLoading = true
        
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else {
            isLoading = false
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { result, _ in
            DispatchQueue.main.async {
                self.image = result
                self.isLoading = false
            }
        }
    }
}

#Preview {
    MemoriesView()
}
