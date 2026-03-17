//
//  WidgetStudioView.swift
//  FurFrame
//
//  Created by Adward on 2026/3/14.
//

import SwiftUI
import SwiftData
import Photos
import WidgetKit

enum WidgetSize: String, CaseIterable, Identifiable {
    case small, medium, large
    var id: String { self.rawValue }
    var label: String { self.rawValue.capitalized }
}

enum WidgetTheme: String, CaseIterable, Identifiable {
    case minimal, polaroid, film
    var id: String { self.rawValue }
    
    var label: String {
        switch self {
        case .minimal: return "Minimal"
        case .polaroid: return "Polaroid"
        case .film: return "Film Pro"
        }
    }
    
    var isPro: Bool {
        switch self {
        case .minimal, .polaroid: return false
        case .film: return true
        }
    }
}

struct WidgetStudioView: View {
    @AppStorage("widgetSize", store: UserDefaults(suiteName: "group.com.furframe.app")) var selectedSize: WidgetSize = .medium
    @AppStorage("widgetTheme", store: UserDefaults(suiteName: "group.com.furframe.app")) var selectedTheme: WidgetTheme = .polaroid
    @AppStorage("widgetAlbumSource", store: UserDefaults(suiteName: "group.com.furframe.app")) var albumSource: String = "All Pets"
    @AppStorage("isPro", store: UserDefaults(suiteName: "group.com.furframe.app")) var isPro: Bool = false
    
    @Query(sort: \PetAsset.creationDate, order: .reverse) private var allAssets: [PetAsset]
    @Query(filter: #Predicate<PetAsset> { $0.isFavorite == true }, sort: \.creationDate, order: .reverse) private var favoriteAssets: [PetAsset]
    @Query(filter: #Predicate<PetAsset> { $0.isHero == true }) private var heroAssets: [PetAsset]
    
    @State private var showPaywall = false
    @State private var showStandByPreview = false
    @State private var animatePreview = false
    @State private var selectedTab = 0 // 0: Themes, 1: Source
    @State private var previewImage: UIImage?
    @State private var displayedAssetId: String = ""
    
    var displayedAssets: [PetAsset] {
        albumSource == "Favorites Only" ? favoriteAssets : allAssets
    }
    
    // 计算当前应该显示哪张照片
    var currentDisplayAsset: PetAsset? {
        // 如果当前设置的是 Favorites Only，但收藏列表为空，返回 nil
        if displayedAssets.isEmpty {
            return nil
        }
        // 如果有 Hero 照片且在列表中，优先显示 Hero
        if let hero = heroAssets.first, displayedAssets.contains(where: { $0.localIdentifier == hero.localIdentifier }) {
            return hero
        }
        // 如果之前显示的照片还在列表中，继续显示它
        if !displayedAssetId.isEmpty, let existing = displayedAssets.first(where: { $0.localIdentifier == displayedAssetId }) {
            return existing
        }
        // 否则显示列表中的第一张
        return displayedAssets.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appSecondaryBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Size Picker
                    SizePicker(selectedSize: $selectedSize)
                        .padding(.horizontal, .appSpacingLarge)
                        .padding(.top, .appSpacingMedium)
                    
                    // Preview Area
                    PreviewArea(
                        size: selectedSize,
                        theme: selectedTheme,
                        currentAsset: currentDisplayAsset,
                        previewImage: previewImage,
                        animate: animatePreview
                    )
                    .onChange(of: selectedSize) { _, _ in
                        triggerPreviewAnimation()
                    }
                    .onChange(of: selectedTheme) { _, _ in
                        triggerPreviewAnimation()
                    }
                    .onChange(of: albumSource) { _, _ in
                        loadPreviewImage()
                        triggerPreviewAnimation()
                    }
                    .onChange(of: displayedAssets) { _, _ in
                        // 数据源变化时重新加载预览
                        loadPreviewImage()
                        triggerPreviewAnimation()
                    }
                    .onAppear {
                        loadPreviewImage()
                    }
                    
                    // Bottom Sheet - 贴底显示
                    BottomSheet(
                        selectedTheme: $selectedTheme,
                        albumSource: $albumSource,
                        selectedTab: $selectedTab,
                        isPro: isPro,
                        onThemeTap: { theme in
                            if theme.isPro && !isPro {
                                showPaywall = true
                            } else {
                                withAnimation(.spring()) {
                                    selectedTheme = theme
                                }
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        }
                    )
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .navigationTitle("Widget Studio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showStandByPreview = true
                    } label: {
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 20))
                            .foregroundColor(.appTextPrimary)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $showStandByPreview) {
                StandByPreviewView()
            }
        }
    }
    
    private func triggerPreviewAnimation() {
        animatePreview = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            animatePreview = true
        }
    }
    
    private func loadPreviewImage() {
        guard let asset = currentDisplayAsset else {
            previewImage = nil
            displayedAssetId = ""
            return
        }
        
        // 记录当前显示的照片ID
        displayedAssetId = asset.localIdentifier
        
        // 加载图片
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [asset.localIdentifier], options: nil)
        guard let phAsset = fetchResult.firstObject else {
            previewImage = nil
            return
        }
        
        let targetSize = CGSize(width: 600, height: 600)
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(for: phAsset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                self.previewImage = image
            }
        }
    }
}

// MARK: - Size Picker
struct SizePicker: View {
    @Binding var selectedSize: WidgetSize
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(WidgetSize.allCases) { size in
                Button {
                    withAnimation(.spring()) {
                        selectedSize = size
                    }
                } label: {
                    Text(size.label)
                        .font(.appCalloutMedium)
                        .foregroundColor(selectedSize == size ? .appTextPrimary : .appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(selectedSize == size ? Color.white : Color.clear)
                        .cornerRadius(.appRadiusMedium)
                }
            }
        }
        .padding(4)
        .background(Color.appTextTertiary.opacity(0.2))
        .cornerRadius(.appRadiusLarge)
    }
}

// MARK: - Preview Area
struct PreviewArea: View {
    let size: WidgetSize
    let theme: WidgetTheme
    let currentAsset: PetAsset?
    let previewImage: UIImage?
    let animate: Bool
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.appSecondaryBackground
                
                // Widget Preview
                WidgetPreviewCard(
                    size: size,
                    theme: theme,
                    previewImage: previewImage,
                    maxHeight: geo.size.height
                )
                .shadow(color: .black.opacity(0.1), radius: 30, x: 0, y: 15)
                .scaleEffect(animate ? 1.0 : 0.95)
                .opacity(animate ? 1.0 : 0.7)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: animate)
                .rotationEffect(.degrees(theme == .polaroid ? -2 : 0))
            }
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Widget Preview Card
struct WidgetPreviewCard: View {
    let size: WidgetSize
    let theme: WidgetTheme
    let previewImage: UIImage?
    var maxHeight: CGFloat = .infinity
    
    var body: some View {
        let frameSize = getFrameSize()
        
        ZStack {
            switch theme {
            case .minimal:
                MinimalWidgetPreview(image: previewImage)
            case .polaroid:
                PolaroidWidgetPreview(image: previewImage)
            case .film:
                FilmWidgetPreview(image: previewImage)
            }
        }
        .frame(width: frameSize.width, height: min(frameSize.height, maxHeight * 0.95))
        .id(size) // 强制在size变化时重新创建视图
    }
    
    private func getFrameSize() -> CGSize {
        let screenWidth = UIScreen.main.bounds.width - 40 // 减去边距
        let availableWidth = min(340, screenWidth)
        
        switch size {
        case .small: 
            // Small: 正方形，较小
            return CGSize(width: 140, height: 140)
        case .medium: 
            // Medium: 2x1 矩形，宽度占满，高度为宽度的一半
            return CGSize(width: availableWidth, height: availableWidth * 0.45)
        case .large: 
            // Large: 2x2 正方形，明显比Medium高
            return CGSize(width: availableWidth, height: availableWidth * 0.9)
        }
    }
}

// MARK: - Theme Previews
struct MinimalWidgetPreview: View {
    let image: UIImage?
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Image(systemName: "dog.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.appOrange.opacity(0.8))
                    .padding(20)
                    .background(Color.appOrange.opacity(0.2))
            }
            
            // Small watermark
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(image == nil ? Color.appOrange.opacity(0.3) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: .appRadiusLarge))
    }
}

struct PolaroidWidgetPreview: View {
    let image: UIImage?
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // 图片区域 - 根据高度自适应
                ZStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Image(systemName: "dog.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.appOrange)
                            .padding(geo.size.height > 200 ? 30 : 15)
                            .background(Color.appOrange.opacity(0.15))
                    }
                }
                .frame(height: geo.size.height * 0.75) // 图片占75%高度
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .clipped()
                
                Spacer()
                
                Text("memories")
                    .font(.system(size: min(14, geo.size.height * 0.08), design: .serif))
                    .foregroundColor(.appTextSecondary)
                    .padding(.bottom, geo.size.height > 200 ? 20 : 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: .appRadiusMedium))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
    }
}

struct FilmWidgetPreview: View {
    let image: UIImage?
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                
                // Photo area
                ZStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                    } else {
                        Color.gray.opacity(0.3)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                    }
                    
                    // Vignette
                    RadialGradient(
                        colors: [.clear, .black.opacity(0.4)],
                        center: .center,
                        startRadius: geo.size.width * 0.2,
                        endRadius: geo.size.width * 0.5
                    )
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                }
                
                // Film holes
                HStack {
                    VStack(spacing: geo.size.height > 200 ? 12 : 6) {
                        ForEach(0..<(geo.size.height > 200 ? 6 : 4)) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(hex: "FFD60A").opacity(0.8))
                                .frame(width: 5, height: geo.size.height > 200 ? 8 : 6)
                        }
                    }
                    Spacer()
                    VStack(spacing: geo.size.height > 200 ? 12 : 6) {
                        ForEach(0..<(geo.size.height > 200 ? 6 : 4)) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(hex: "FFD60A").opacity(0.8))
                                .frame(width: 5, height: geo.size.height > 200 ? 8 : 6)
                        }
                    }
                }
                .padding(.horizontal, 5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: .appRadiusMedium))
        }
    }
}

// MARK: - Bottom Sheet
struct BottomSheet: View {
    @Binding var selectedTheme: WidgetTheme
    @Binding var albumSource: String
    @Binding var selectedTab: Int
    let isPro: Bool
    let onThemeTap: (WidgetTheme) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.appTextTertiary)
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            // Tab Selector
            HStack(spacing: 0) {
                TabButton(title: "Themes", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabButton(title: "Source", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
            }
            .padding(.horizontal, .appSpacingXXLarge)
            
            Divider()
                .padding(.top, 12)
            
            // Content
            if selectedTab == 0 {
                ThemesGrid(selectedTheme: $selectedTheme, isPro: isPro, onThemeTap: onThemeTap)
            } else {
                SourceSelector(albumSource: $albumSource)
            }
            
            Spacer()
        }
        .background(Color.appSheetBackground)
        .cornerRadius(.appRadiusXXLarge, corners: [.topLeft, .topRight])
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.appCalloutMedium)
                    .foregroundColor(isSelected ? .appTextPrimary : .appTextSecondary)
                
                if isSelected {
                    Rectangle()
                        .fill(Color.appTextPrimary)
                        .frame(height: 2)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Themes Grid
struct ThemesGrid: View {
    @Binding var selectedTheme: WidgetTheme
    let isPro: Bool
    let onThemeTap: (WidgetTheme) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(WidgetTheme.allCases) { theme in
                    ThemeThumbnailButton(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        isPro: isPro,
                        action: { onThemeTap(theme) }
                    )
                }
            }
            .padding(.horizontal, .appSpacingLarge)
            .padding(.vertical, .appSpacingMedium)
        }
    }
}

struct ThemeThumbnailButton: View {
    let theme: WidgetTheme
    let isSelected: Bool
    let isPro: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    // Thumbnail
                    themeThumbnail
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: .appRadiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: .appRadiusMedium)
                                .stroke(isSelected ? Color.appOrange : Color.clear, lineWidth: 2)
                        )
                    
                    // Pro badge
                    if theme.isPro && !isPro {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.appGold)
                            .clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                }
                
                Text(theme.label)
                    .font(.appCaptionMedium)
                    .foregroundColor(isSelected ? .appOrange : (theme.isPro && !isPro ? .appGold : .appTextPrimary))
            }
        }
    }
    
    @ViewBuilder
    private var themeThumbnail: some View {
        switch theme {
        case .minimal:
            MinimalWidgetPreview(image: nil)
        case .polaroid:
            PolaroidWidgetPreview(image: nil)
        case .film:
            FilmWidgetPreview(image: nil)
        }
    }
}

// MARK: - Source Selector
struct SourceSelector: View {
    @Binding var albumSource: String
    
    var body: some View {
        VStack(spacing: .appSpacingMedium) {
            SourceRow(
                title: "All Pets",
                icon: "photo.on.rectangle",
                isSelected: albumSource == "All Pets"
            ) {
                albumSource = "All Pets"
                WidgetCenter.shared.reloadAllTimelines()
            }
            
            SourceRow(
                title: "Favorites Only",
                icon: "heart.fill",
                isSelected: albumSource == "Favorites Only"
            ) {
                albumSource = "Favorites Only"
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        .padding(.horizontal, .appSpacingLarge)
        .padding(.top, .appSpacingMedium)
    }
}

struct SourceRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .appOrange : .appTextSecondary)
                
                Text(title)
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.appOrange)
                }
            }
            .padding(.horizontal, .appSpacingLarge)
            .padding(.vertical, .appSpacingMedium)
            .background(Color.appSecondaryBackground)
            .cornerRadius(.appRadiusLarge)
        }
    }
}

// MARK: - Corner Radius Helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    WidgetStudioView()
}
