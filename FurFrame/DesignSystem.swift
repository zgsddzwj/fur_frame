//
//  DesignSystem.swift
//  FurFrame
//
//  Design System for FurFrame
//

import SwiftUI

// MARK: - Colors
extension Color {
    // Background
    static let appBackground = Color(hex: "F9F9F7")
    static let appSecondaryBackground = Color(hex: "F2F2F7")
    static let appSheetBackground = Color.white
    
    // Brand
    static let appOrange = Color(hex: "FF6B35")
    static let appOrangeLight = Color(hex: "FF8C61")
    
    // Text
    static let appTextPrimary = Color(hex: "1C1C1E")
    static let appTextSecondary = Color(hex: "8E8E93")
    static let appTextTertiary = Color(hex: "C7C7CC")
    
    // Semantic
    static let appSuccess = Color(hex: "34C759")
    static let appWarning = Color(hex: "FFCC00")
    static let appError = Color(hex: "FF3B30")
    
    // Special
    static let appAuroraStart = Color(hex: "FF6B35")
    static let appAuroraEnd = Color(hex: "5856D6")
    static let appNeon = Color(hex: "FF453A")
    static let appGold = Color(hex: "FFD60A")
    
    // Glassmorphism
    static let appGlassLight = Color.white.opacity(0.7)
    static let appGlassDark = Color.black.opacity(0.4)
}

// MARK: - Typography
extension Font {
    // Display
    static let appDisplay = Font.system(size: 32, weight: .bold, design: .default)
    
    // Headlines
    static let appHeadline = Font.system(size: 28, weight: .bold, design: .default)
    static let appHeadline2 = Font.system(size: 22, weight: .bold, design: .default)
    static let appHeadline3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // Body
    static let appBody = Font.system(size: 17, weight: .regular, design: .default)
    static let appBodyMedium = Font.system(size: 17, weight: .medium, design: .default)
    static let appBodySemibold = Font.system(size: 17, weight: .semibold, design: .default)
    
    // Callout
    static let appCallout = Font.system(size: 16, weight: .regular, design: .default)
    static let appCalloutMedium = Font.system(size: 16, weight: .medium, design: .default)
    
    // Footnote
    static let appFootnote = Font.system(size: 13, weight: .regular, design: .default)
    static let appFootnoteMedium = Font.system(size: 13, weight: .medium, design: .default)
    
    // Caption
    static let appCaption = Font.system(size: 12, weight: .regular, design: .default)
    static let appCaptionMedium = Font.system(size: 12, weight: .medium, design: .default)
}

// MARK: - Radius
extension CGFloat {
    static let appRadiusSmall: CGFloat = 8
    static let appRadiusMedium: CGFloat = 12
    static let appRadiusLarge: CGFloat = 16
    static let appRadiusXLarge: CGFloat = 20
    static let appRadiusXXLarge: CGFloat = 24
    static let appRadiusCapsule: CGFloat = 999
}

// MARK: - Spacing
extension CGFloat {
    static let appSpacingXSmall: CGFloat = 4
    static let appSpacingSmall: CGFloat = 8
    static let appSpacingMedium: CGFloat = 12
    static let appSpacingLarge: CGFloat = 16
    static let appSpacingXLarge: CGFloat = 20
    static let appSpacingXXLarge: CGFloat = 24
    static let appSpacingXXXLarge: CGFloat = 32
}

// MARK: - Shadow Styles
struct AppShadow {
    static let small = ShadowStyle(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    static let medium = ShadowStyle(color: .black.opacity(0.1), radius: 16, x: 0, y: 4)
    static let large = ShadowStyle(color: .black.opacity(0.12), radius: 24, x: 0, y: 8)
    static let button = ShadowStyle(color: .appOrange.opacity(0.3), radius: 16, x: 0, y: 6)
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    func apply<V: View>(_ view: V) -> some View {
        view.shadow(color: color, radius: radius, x: x, y: y)
    }
}

// MARK: - Glassmorphism Modifier
struct GlassmorphismModifier: ViewModifier {
    let isDark: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    (isDark ? Color.appGlassDark : Color.appGlassLight)
                        .background(.ultraThinMaterial)
                }
            )
            .cornerRadius(.appRadiusLarge)
    }
}

extension View {
    func glassmorphism(isDark: Bool = false) -> some View {
        modifier(GlassmorphismModifier(isDark: isDark))
    }
}

// MARK: - Aurora Gradient
extension LinearGradient {
    static let appAurora = LinearGradient(
        colors: [.appAuroraStart, .appAuroraEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Button Styles
struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBodyMedium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.appOrange)
            .cornerRadius(.appRadiusCapsule)
            .shadow(color: .appOrange.opacity(configuration.isPressed ? 0.2 : 0.3), 
                    radius: configuration.isPressed ? 8 : 16, x: 0, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appCalloutMedium)
            .foregroundColor(.appTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.appSecondaryBackground)
            .cornerRadius(.appRadiusCapsule)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AppGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appCalloutMedium)
            .foregroundColor(.appOrange)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: .appRadiusCapsule)
                    .stroke(Color.appOrange.opacity(0.3), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AppGoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBodyMedium)
            .foregroundColor(.appTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.appGold)
            .cornerRadius(.appRadiusCapsule)
            .shadow(color: .appGold.opacity(configuration.isPressed ? 0.3 : 0.5), 
                    radius: configuration.isPressed ? 8 : 16, x: 0, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appTextTertiary.opacity(0.3), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            
            VStack(spacing: 0) {
                Text("\(Int(progress * 100))")
                    .font(.appHeadline)
                    .foregroundColor(.appTextPrimary)
                + Text("%")
                    .font(.appCallout)
                    .foregroundColor(.appTextSecondary)
            }
        }
    }
}

// MARK: - Illustration Placeholder
struct IllustrationPlaceholder: View {
    let name: String
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.appOrange.opacity(0.1))
                .frame(width: size, height: size)
            
            Text("[\(name)]")
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
        }
    }
}
