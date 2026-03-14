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
        // Mock purchase - in real app, use StoreKit
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
    
    // Particle animation state
    @State private var particles: [Particle] = []
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "FFF8F0"),
                    Color(hex: "FFF0E6")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Particle effects
            ParticleView(particles: $particles)
            
            // Content
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .padding()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Header with crown icon
                        VStack(spacing: 16) {
                            ZStack {
                                // Glow effect
                                Circle()
                                    .fill(Color.orange.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 20)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .orange.opacity(0.5), radius: 15, x: 0, y: 5)
                            }
                            
                            VStack(spacing: 8) {
                                Text("FurFrame Pro")
                                    .font(.system(size: 38, weight: .black, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text("Unlock everything forever")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Features list
                        VStack(alignment: .leading, spacing: 20) {
                            FeatureRow(
                                icon: "film.fill",
                                iconColor: .purple,
                                title: "Unlock all premium aesthetics",
                                subtitle: "Film, Y2K, and exclusive themes"
                            )
                            
                            FeatureRow(
                                icon: "calendar.badge.clock",
                                iconColor: .blue,
                                title: "Polaroid with handwritten dates",
                                subtitle: "Personal touch for every memory"
                            )
                            
                            FeatureRow(
                                icon: "deskclock.fill",
                                iconColor: .green,
                                title: "StandBy mode exclusive faces",
                                subtitle: "Perfect bedside pet frame"
                            )
                            
                            FeatureRow(
                                icon: "lock.shield.fill",
                                iconColor: .orange,
                                title: "100% private, runs locally",
                                subtitle: "Your data never leaves your phone"
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        Spacer().frame(height: 30)
                    }
                }
                
                // Bottom section with CTA
                VStack(spacing: 16) {
                    // Price tag
                    HStack(spacing: 8) {
                        Text("One-time payment")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                        
                        Text("No subscriptions")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    // Buy button
                    Button {
                        Task {
                            await purchaseManager.purchase()
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                            Text("Unlock Forever — $9.99")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .orange.opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .padding(.horizontal, 24)
                    
                    // Restore purchases
                    Button {
                        Task { await purchaseManager.restore() }
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.orange)
                    }
                    
                    // Terms & Privacy
                    HStack(spacing: 24) {
                        Button("Terms of Use") {
                            // Open terms
                        }
                        
                        Text("•")
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Button("Privacy Policy") {
                            // Open privacy
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFF8F0").opacity(0),
                            Color(hex: "FFF8F0")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            }
        }
        .onAppear {
            startParticleAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startParticleAnimation() {
        // Create initial particles
        for _ in 0..<15 {
            particles.append(Particle.random())
        }
        
        // Update particles periodically
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                for i in particles.indices {
                    particles[i].update()
                    
                    // Reset particle if it goes off screen
                    if particles[i].y < -50 {
                        particles[i] = Particle.random(startAtBottom: true)
                    }
                }
            }
        }
    }
}

// MARK: - Particle Model
struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: CGFloat
    var wobble: CGFloat
    var wobbleSpeed: CGFloat
    var wobbleOffset: CGFloat
    
    init(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double, speed: CGFloat) {
        self.x = x
        self.y = y
        self.size = size
        self.opacity = opacity
        self.speed = speed
        self.wobble = CGFloat.random(in: -30...30)
        self.wobbleSpeed = CGFloat.random(in: 0.02...0.05)
        self.wobbleOffset = CGFloat.random(in: 0...(.pi * 2))
    }
    
    static func random(startAtBottom: Bool = false) -> Particle {
        Particle(
            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            y: startAtBottom ? UIScreen.main.bounds.height + 50 : CGFloat.random(in: 0...UIScreen.main.bounds.height),
            size: CGFloat.random(in: 4...12),
            opacity: Double.random(in: 0.1...0.4),
            speed: CGFloat.random(in: 0.5...2)
        )
    }
    
    mutating func update() {
        y -= speed
        wobbleOffset += wobbleSpeed
        x += sin(wobbleOffset) * 0.5
    }
}

// MARK: - Particle View
struct ParticleView: View {
    @Binding var particles: [Particle]
    
    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.x - particle.size / 2,
                    y: particle.y - particle.size / 2,
                    width: particle.size,
                    height: particle.size
                )
                
                // Draw star shape
                var path = Path()
                let center = CGPoint(x: rect.midX, y: rect.midY)
                let radius = particle.size / 2
                
                for i in 0..<5 {
                    let angle = CGFloat(i) * .pi * 2 / 5 - .pi / 2
                    let point = CGPoint(
                        x: center.x + cos(angle) * radius,
                        y: center.y + sin(angle) * radius
                    )
                    
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                    
                    // Inner point
                    let innerAngle = angle + .pi / 5
                    let innerPoint = CGPoint(
                        x: center.x + cos(innerAngle) * (radius * 0.4),
                        y: center.y + sin(innerAngle) * (radius * 0.4)
                    )
                    path.addLine(to: innerPoint)
                }
                path.closeSubpath()
                
                context.fill(
                    path,
                    with: .color(.orange.opacity(particle.opacity))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
        )
    }
}

#Preview {
    PaywallView()
}
