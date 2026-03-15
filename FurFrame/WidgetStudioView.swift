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
    
    @State private var showPaywall = false
    @State private var showStandByPreview = false
    @State private var animatePreview = false
    @State private var selectedTab = 0 // 0: Themes, 1: Source
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appSecondaryBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Navigation
                    HStack {
                        Text("Done")
                            .font(.appCalloutMedium)
                            .foregroundColor(.appOrange)
                        
                        Spacer()
                        
                        Text("Widget Studio")
                            .font(.appHeadline3)
                        
                        Spacer()
                        
                        Button {
                            showStandByPreview = true
                        } label: {
                            Text("StandBy")
                                .font(.appCalloutMedium)
                                .foregroundColor(.appOrange)
                        }
                    }
                    .padding(.horizontal, .appSpacingLarge)
                    .padding(.top, .appSpacingMedium)
                    
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
                    
                    // Bottom Sheet
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
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showStandByPreview) {
                StandByPreviewView()
                    .presentationDetents([.large])
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
        ZStack {
            Color.appSecondaryBackground
            
            // Widget Preview
            WidgetPreviewCard(size: size, theme: theme)
                .shadow(color: .black.opacity(0.1), radius: 30, x: 0, y: 15)
                .scaleEffect(animate ? 1.0 : 0.95)
                .opacity(animate ? 1.0 : 0.7)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: animate)
                .rotationEffect(.degrees(theme == .polaroid ? -2 : 0))
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Widget Preview Card
struct WidgetPreviewCard: View {
    let size: WidgetSize
    let theme: WidgetTheme
    
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
        .frame(width: frameSize.width, height: frameSize.height)
    }
    
    private func getFrameSize() -> CGSize {
        switch size {
        case .small: return CGSize(width: 160, height: 160)
        case .medium: return CGSize(width: 340, height: 160)
        case .large: return CGSize(width: 340, height: 340)
        }
    }
}

// MARK: - Theme Previews
struct MinimalWidgetPreview: View {
    var body: some View {
        ZStack {
            Image(systemName: "dog.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .foregroundColor(.appOrange.opacity(0.8))
                .padding(40)
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
        .background(Color.appOrange.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: .appRadiusLarge))
    }
}

struct PolaroidWidgetPreview: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Image(systemName: "dog.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .foregroundColor(.appOrange)
                    .padding(20)
                    .background(Color.appOrange.opacity(0.15))
            }
            .padding(12)
            .padding(.top, 12)
            
            Spacer()
            
            Text("memories")
                .font(.system(size: 14, design: .serif))
                .foregroundColor(.appTextSecondary)
                .padding(.bottom, 16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: .appRadiusMedium))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

struct FilmWidgetPreview: View {
    var body: some View {
        ZStack {
            Color.black
            
            ZStack {
                Image(systemName: "cat.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(30)
                    .background(Color.gray.opacity(0.3))
                
                // Vignette
                RadialGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    center: .center,
                    startRadius: 50,
                    endRadius: 120
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            // Film holes
            HStack {
                VStack(spacing: 8) {
                    ForEach(0..<5) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.appGold.opacity(0.8))
                            .frame(width: 5, height: 8)
                    }
                }
                Spacer()
                VStack(spacing: 8) {
                    ForEach(0..<5) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.appGold.opacity(0.8))
                            .frame(width: 5, height: 8)
                    }
                }
            }
            .padding(.horizontal, 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: .appRadiusMedium))
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
