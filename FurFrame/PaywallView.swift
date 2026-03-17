//
//  PaywallView.swift
//  FurFrame
//
//  Created by Adward on 2026/3/14.
//

import SwiftUI
import StoreKit
import Combine

@MainActor
class PurchaseManager: ObservableObject {
    @Published var isPro: Bool {
        didSet {
            UserDefaults(suiteName: "group.com.furframe.app")?.set(isPro, forKey: "isPro")
        }
    }
    
    init() {
        self.isPro = UserDefaults(suiteName: "group.com.furframe.app")?.bool(forKey: "isPro") ?? false
    }
    
    func purchase() async {
        withAnimation(.spring()) {
            isPro = true
        }
    }
    
    func restore() async {
        // Mock restore
    }
}

struct PaywallView: View {
    @StateObject private var purchaseManager = PurchaseManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        PaywallSheetContent(purchaseManager: purchaseManager, dismiss: dismiss)
            .background(Color.white)
            .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Paywall Sheet Content (底部弹窗样式)
struct PaywallSheetContent: View {
    @ObservedObject var purchaseManager: PurchaseManager
    var dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .padding(8)
                        .background(Color.appTextTertiary.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, .appSpacingLarge)
            .padding(.top, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 2) // 额外顶部间距
                    
                    // Header Card with Aurora
                    AuroraHeaderCard()
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow2(icon: "checkmark.circle.fill", text: "Premium widget themes (Film, Neon)")
                        FeatureRow2(icon: "checkmark.circle.fill", text: "Unlimited pet tracking requests")
                        FeatureRow2(icon: "checkmark.circle.fill", text: "Smart album organization")
                        FeatureRow2(icon: "checkmark.circle.fill", text: "Support indie development")
                    }
                    .padding(.horizontal, .appSpacingLarge)
                    
                    Spacer().frame(height: 8)
                }
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            
            // Bottom CTA
            VStack(spacing: 12) {
                Button {
                    Task {
                        await purchaseManager.purchase()
                        dismiss()
                    }
                } label: {
                    Text("Unlock Forever — $9.99")
                        .font(.appBodySemibold)
                }
                .buttonStyle(AppPrimaryButtonStyle())
                .padding(.horizontal, .appSpacingLarge)
                
                // Footer links
                HStack(spacing: 24) {
                    Button("Restore Purchases") {
                        Task { await purchaseManager.restore() }
                    }
                    .font(.appFootnote)
                    .foregroundColor(.appTextSecondary)
                    
                    Text("|")
                        .font(.appFootnote)
                        .foregroundColor(.appTextTertiary)
                    
                    Button("Terms of Use") {
                        // Open terms
                    }
                    .font(.appFootnote)
                    .foregroundColor(.appTextSecondary)
                }
            }
            .padding(.bottom, 34)
            .padding(.top, 16)
            .background(
                LinearGradient(
                    colors: [.white.opacity(0), .white],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .background(Color.white)
        .cornerRadius(.appRadiusXXLarge, corners: [.topLeft, .topRight])
    }
}

// MARK: - Aurora Header Card
struct AuroraHeaderCard: View {
    var body: some View {
        ZStack {
            // Aurora gradient background
            RoundedRectangle(cornerRadius: .appRadiusXLarge)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FF6B35"),
                            Color(hex: "FF8C61"),
                            Color(hex: "A855F7")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Particle effects overlay
            ParticleEffectView()
            
            VStack(spacing: 8) {
                Text("FurFrame Pro")
                    .font(.appHeadline)
                    .foregroundColor(.white)
                
                Text("Unlock all widget themes forever.")
                    .font(.appCallout)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.vertical, 24)
        }
        .padding(.horizontal, .appSpacingLarge)
    }
}

// MARK: - Particle Effect View
struct ParticleEffectView: View {
    @State private var particles: [Particle] = []
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var speed: CGFloat
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.white)
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                }
            }
            .onReceive(timer) { _ in
                updateParticles(in: geo.size)
            }
            .onAppear {
                createInitialParticles(in: geo.size)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: .appRadiusXLarge))
    }
    
    private func createInitialParticles(in size: CGSize) {
        particles = (0..<15).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.3...0.8),
                speed: CGFloat.random(in: 0.3...1.0)
            )
        }
    }
    
    private func updateParticles(in size: CGSize) {
        for i in particles.indices {
            particles[i].y -= particles[i].speed
            particles[i].opacity -= 0.005
            
            // Reset particle when it goes off screen or fades out
            if particles[i].y < 0 || particles[i].opacity <= 0 {
                particles[i].y = size.height + 10
                particles[i].x = CGFloat.random(in: 0...size.width)
                particles[i].opacity = Double.random(in: 0.3...0.8)
                particles[i].size = CGFloat.random(in: 2...6)
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow2: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.appSuccess)
            
            Text(text)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)
            
            Spacer()
        }
    }
}

#Preview {
    PaywallView()
}
