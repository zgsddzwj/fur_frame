//
//  WidgetStudioView.swift
//  FurFrame
//
//  Created by Adward on 2026/3/14.
//

import SwiftUI
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
    
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    @State private var showStandByPreview = false
    @State private var animatePreview = false
    @State private var selectedTab = 0 // 0: Themes, 1: Source
    
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
                    PreviewArea(size: selectedSize, theme: selectedTheme, animate: animatePreview)
                        .onChange(of: selectedSize) { _, _ in
                            triggerPreviewAnimation()
                        }
                        .onChange(of: selectedTheme) { _, _ in
                            triggerPreviewAnimation()
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.appCalloutMedium)
                    .foregroundColor(.appOrange)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showStandByPreview = true
                    } label: {
                        Text("StandBy")
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
    let animate: Bool
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.appSecondaryBackground
                
                // Widget Preview
                WidgetPreviewCard(size: size, theme: theme, maxHeight: geo.size.height)
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
    var maxHeight: CGFloat = .infinity
    
    var body: some View {
        let frameSize = getFrameSize()
        
        ZStack {
            switch theme {
            case .minimal:
                MinimalWidgetPreview()
            case .polaroid:
                PolaroidWidgetPreview()
            case .film:
                FilmWidgetPreview()
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
    var body: some View {
        ZStack {
            Image(systemName: "dog.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.appOrange.opacity(0.8))
                .padding(20)
                .background(Color.appOrange.opacity(0.2))
            
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
        .background(Color.appOrange.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: .appRadiusLarge))
    }
}

struct PolaroidWidgetPreview: View {
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // 图片区域 - 根据高度自适应
                ZStack {
                    Image(systemName: "dog.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.appOrange)
                        .padding(geo.size.height > 200 ? 30 : 15)
                        .background(Color.appOrange.opacity(0.15))
                }
                .frame(height: geo.size.height * 0.75) // 图片占75%高度
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
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
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                
                // 主图片区域
                ZStack {
                    Image(systemName: "cat.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(geo.size.height > 200 ? 40 : 20)
                        .background(Color.gray.opacity(0.3))
                    
                    // Vignette
                    RadialGradient(
                        colors: [.clear, .black.opacity(0.5)],
                        center: .center,
                        startRadius: geo.size.height * 0.2,
                        endRadius: geo.size.height * 0.5
                    )
                }
                .padding(.horizontal, geo.size.height > 200 ? 30 : 16)
                .padding(.vertical, geo.size.height > 200 ? 20 : 12)
                
                // Film holes - 根据高度调整数量
                HStack {
                    VStack(spacing: geo.size.height > 200 ? 12 : 6) {
                        ForEach(0..<(geo.size.height > 200 ? 6 : 4)) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.appGold.opacity(0.8))
                                .frame(width: 5, height: 8)
                        }
                    }
                    Spacer()
                    VStack(spacing: geo.size.height > 200 ? 12 : 6) {
                        ForEach(0..<(geo.size.height > 200 ? 6 : 4)) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.appGold.opacity(0.8))
                                .frame(width: 5, height: 8)
                        }
                    }
                }
                .padding(.horizontal, 6)
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
            MinimalWidgetPreview()
        case .polaroid:
            PolaroidWidgetPreview()
        case .film:
            FilmWidgetPreview()
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
