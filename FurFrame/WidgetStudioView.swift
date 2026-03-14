//
//  WidgetStudioView.swift
//  FurFrame
//
//  Created by Adward on 2026/3/14.
//

import SwiftUI
import WidgetKit

enum WidgetSize: String, CaseIterable, Identifiable {
    case small, medium, large, standby
    var id: String { self.rawValue }
    var label: String { self.rawValue.capitalized }
    
    var description: String {
        switch self {
        case .small: return "1x1"
        case .medium: return "2x1"
        case .large: return "2x2"
        case .standby: return "StandBy"
        }
    }
}

enum WidgetTheme: String, CaseIterable, Identifiable {
    case minimal, polaroid, film, polaroidDate, standbyClock
    var id: String { self.rawValue }
    
    var label: String {
        switch self {
        case .minimal: return "Minimal"
        case .polaroid: return "Polaroid"
        case .film: return "Film"
        case .polaroidDate: return "Polaroid + Date"
        case .standbyClock: return "StandBy Clock"
        }
    }
    
    var description: String {
        switch self {
        case .minimal: return "Clean & Simple"
        case .polaroid: return "Classic Frame"
        case .film: return "Vintage Kodak"
        case .polaroidDate: return "Handwritten Date"
        case .standbyClock: return "Nightstand Mode"
        }
    }
    
    var isPro: Bool {
        switch self {
        case .minimal, .polaroid: return false
        default: return true
        }
    }
}

struct WidgetStudioView: View {
    @AppStorage("widgetSize", store: UserDefaults(suiteName: "group.com.furframe.app")) var selectedSize: WidgetSize = .small
    @AppStorage("widgetTheme", store: UserDefaults(suiteName: "group.com.furframe.app")) var selectedTheme: WidgetTheme = .minimal
    @AppStorage("widgetAlbumSource", store: UserDefaults(suiteName: "group.com.furframe.app")) var albumSource: String = "All Pets"
    @AppStorage("isPro", store: UserDefaults(suiteName: "group.com.furframe.app")) var isPro: Bool = false
    
    @State private var showPaywall = false
    @State private var animatePreview = false
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "F5F5F3").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                StudioHeader()
                
                // Size Picker
                SizePicker(selectedSize: $selectedSize)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Preview area
                PreviewArea(size: selectedSize, theme: selectedTheme, animate: animatePreview)
                    .onChange(of: selectedSize) { _, _ in
                        triggerPreviewAnimation()
                    }
                    .onChange(of: selectedTheme) { _, _ in
                        triggerPreviewAnimation()
                    }
                
                // Configuration Card
                ConfigurationCard(
                    albumSource: $albumSource,
                    selectedTheme: $selectedTheme,
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
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func triggerPreviewAnimation() {
        animatePreview = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            animatePreview = true
        }
    }
}

// MARK: - Studio Header
struct StudioHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Widget Studio")
                    .font(.title2.weight(.bold))
                Text("Customize your home screen")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Size Picker
struct SizePicker: View {
    @Binding var selectedSize: WidgetSize
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(WidgetSize.allCases) { size in
                SizeButton(size: size, isSelected: selectedSize == size) {
                    withAnimation(.spring()) {
                        selectedSize = size
                    }
                }
            }
        }
    }
}

struct SizeButton: View {
    let size: WidgetSize
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(size.label)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
                Text(size.description)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isSelected ? Color.orange : Color.white.opacity(0.8))
            .cornerRadius(14)
            .shadow(color: isSelected ? .orange.opacity(0.3) : .black.opacity(0.05), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
        }
    }
}

// MARK: - Preview Area
struct PreviewArea: View {
    let size: WidgetSize
    let theme: WidgetTheme
    let animate: Bool
    
    var body: some View {
        ZStack {
            // Grid background
            GridBackground()
            
            // Widget Preview
            WidgetPreview(size: size, theme: theme)
                .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 15)
                .scaleEffect(animate ? 1.0 : 0.9)
                .opacity(animate ? 1.0 : 0.5)
                .rotation3DEffect(
                    .degrees(animate ? 0 : 10),
                    axis: (x: 1, y: 0, z: 0)
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animate)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Grid Background
struct GridBackground: View {
    var body: some View {
        ZStack {
            // Base color
            Color.gray.opacity(0.08)
            
            // Grid dots
            VStack(spacing: 24) {
                ForEach(0..<12) { _ in
                    HStack(spacing: 24) {
                        ForEach(0..<8) { _ in
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 3, height: 3)
                        }
                    }
                }
            }
            
            // Subtle radial gradient for depth
            RadialGradient(
                colors: [.clear, .black.opacity(0.03)],
                center: .center,
                startRadius: 100,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Configuration Card
struct ConfigurationCard: View {
    @Binding var albumSource: String
    @Binding var selectedTheme: WidgetTheme
    let isPro: Bool
    let onThemeTap: (WidgetTheme) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Album Source
            VStack(alignment: .leading, spacing: 12) {
                Label("Album Source", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    SourceButton(
                        title: "All Pets",
                        icon: "pawprint",
                        isSelected: albumSource == "All Pets"
                    ) {
                        albumSource = "All Pets"
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    
                    SourceButton(
                        title: "Favorites",
                        icon: "heart.fill",
                        isSelected: albumSource == "Favorites Only"
                    ) {
                        albumSource = "Favorites Only"
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            }
            
            Divider()
            
            // Themes
            VStack(alignment: .leading, spacing: 12) {
                Label("Themes", systemImage: "paintpalette")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(WidgetTheme.allCases) { theme in
                            ThemeButton(
                                theme: theme,
                                isSelected: selectedTheme == theme,
                                isPro: isPro,
                                action: { onThemeTap(theme) }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(24)
        .background(
            Color(uiColor: .systemBackground)
                .clipShape(RoundedCorner(radius: 32, corners: [.topLeft, .topRight]))
        )
        .shadow(color: .black.opacity(0.08), radius: 30, x: 0, y: -10)
    }
}

struct SourceButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isSelected ? Color.orange : Color.gray.opacity(0.12))
            .cornerRadius(16)
        }
    }
}

struct ThemeButton: View {
    let theme: WidgetTheme
    let isSelected: Bool
    let isPro: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Thumbnail
                ZStack(alignment: .topTrailing) {
                    ThemeThumbnail(theme: theme)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    
                    if theme.isPro && !isPro {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.orange)
                            .clipShape(Circle())
                            .shadow(color: .orange.opacity(0.4), radius: 4, x: 0, y: 2)
                            .offset(x: 6, y: -6)
                    }
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                            .background(Color.white.clipShape(Circle()))
                            .offset(x: 4, y: 4)
                    }
                }
                
                // Labels
                VStack(spacing: 2) {
                    Text(theme.label)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(isSelected ? .orange : .primary)
                    
                    Text(theme.description)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .frame(width: 90)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Theme Thumbnail
struct ThemeThumbnail: View {
    let theme: WidgetTheme
    
    var body: some View {
        ZStack {
            switch theme {
            case .minimal:
                Color.orange.opacity(0.2)
                    .overlay(
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange.opacity(0.5))
                    )
                
            case .polaroid:
                Color.white
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.3))
                            .padding(8)
                            .padding(.bottom, 20)
                    )
                
            case .polaroidDate:
                Color.white
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.3))
                            .padding(8)
                            .padding(.bottom, 24)
                    )
                    .overlay(
                        Text("Oct 12")
                            .font(.system(size: 8, design: .serif))
                            .rotationEffect(.degrees(-5))
                            .offset(y: 28)
                    )
                
            case .film:
                Color.black
                    .overlay(
                        Rectangle()
                            .fill(Color.orange.opacity(0.4))
                            .padding(.horizontal, 12)
                    )
                    .overlay(
                        HStack {
                            VStack(spacing: 6) {
                                ForEach(0..<4) { _ in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.yellow)
                                        .frame(width: 4, height: 6)
                                }
                            }
                            Spacer()
                            VStack(spacing: 6) {
                                ForEach(0..<4) { _ in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.yellow)
                                        .frame(width: 4, height: 6)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    )
                
            case .standbyClock:
                Color.black
                    .overlay(
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.orange.opacity(0.3))
                                .frame(width: 28, height: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.green)
                                    .frame(width: 20, height: 8)
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.green)
                                    .frame(width: 20, height: 8)
                            }
                        }
                    )
            }
        }
    }
}

// MARK: - Widget Preview
struct WidgetPreview: View {
    let size: WidgetSize
    let theme: WidgetTheme
    
    var body: some View {
        let frameSize = getFrameSize()
        
        ZStack {
            // Theme rendering
            switch theme {
            case .minimal:
                MinimalPreview()
                
            case .polaroid:
                PolaroidPreview(size: size, showDate: false)
                
            case .polaroidDate:
                PolaroidPreview(size: size, showDate: true)
                
            case .film:
                FilmPreview()
                
            case .standbyClock:
                StandbyClockPreview(size: size)
            }
        }
        .frame(width: frameSize.width, height: frameSize.height)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 40, x: 0, y: 20)
        )
    }
    
    private func getFrameSize() -> CGSize {
        switch size {
        case .small: return CGSize(width: 160, height: 160)
        case .medium: return CGSize(width: 340, height: 160)
        case .large: return CGSize(width: 340, height: 350)
        case .standby: return CGSize(width: 320, height: 150)
        }
    }
}

// MARK: - Preview Styles
struct MinimalPreview: View {
    var body: some View {
        ZStack {
            // Sample pet image placeholder
            LinearGradient(
                colors: [Color.orange.opacity(0.6), Color.orange.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "hare.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.9))
            
            // Small watermark
            Image(systemName: "pawprint.fill")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct PolaroidPreview: View {
    let size: WidgetSize
    let showDate: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [Color.orange.opacity(0.5), Color.orange.opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                Image(systemName: "tortoise.fill")
                    .font(.system(size: showDate ? 50 : 55))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(10)
            .padding(.top, 10)
            
            if showDate {
                Spacer()
                
                Text("Oct 12, 2023")
                    .font(.system(size: size == .small ? 11 : 14, design: .serif))
                    .foregroundColor(.black.opacity(0.7))
                    .rotationEffect(.degrees(-3))
                    .padding(.bottom, 12)
            } else {
                Color.white.frame(height: size == .small ? 25 : 35)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct FilmPreview: View {
    var body: some View {
        ZStack {
            Color.black
            
            // Photo area
            ZStack {
                LinearGradient(
                    colors: [Color.brown.opacity(0.6), Color.orange.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                
                // Vignette
                RadialGradient(
                    colors: [.clear, .black.opacity(0.4)],
                    center: .center,
                    startRadius: 40,
                    endRadius: 100
                )
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                
                // Noise texture simulation
                Image(systemName: "circle.grid.2x2.fill")
                    .resizable()
                    .opacity(0.03)
                    .blendMode(.overlay)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                
                Image(systemName: "hare.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Film holes
            HStack {
                VStack(spacing: 10) {
                    ForEach(0..<6) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.yellow.opacity(0.9))
                            .frame(width: 6, height: 10)
                    }
                }
                Spacer()
                VStack(spacing: 10) {
                    ForEach(0..<6) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.yellow.opacity(0.9))
                            .frame(width: 6, height: 10)
                    }
                }
            }
            .padding(.horizontal, 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct StandbyClockPreview: View {
    let size: WidgetSize
    
    var body: some View {
        HStack(spacing: 20) {
            // Pet avatar
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: size == .small ? 70 : 100, height: size == .small ? 70 : 100)
                
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size == .small ? 35 : 50))
                    .foregroundColor(.orange)
            }
            
            if size != .small {
                Spacer()
            }
            
            // Clock
            VStack(alignment: .trailing, spacing: 0) {
                Text("12")
                    .font(.system(size: size == .small ? 48 : 72, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "00FF44"))
                    .shadow(color: Color(hex: "00FF44").opacity(0.5), radius: 10)
                
                Text("30")
                    .font(.system(size: size == .small ? 48 : 72, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "00FF44"))
                    .shadow(color: Color(hex: "00FF44").opacity(0.5), radius: 10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Helper Extensions
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
