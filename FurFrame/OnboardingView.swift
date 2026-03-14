//
//  OnboardingView.swift
//  FurFrame
//
//  Created by Adward on 2026/3/14.
//

import SwiftUI
import SwiftData
import Photos

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var scanner: PetScanner
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Animation states
    @State private var showContent = false
    @State private var pawScale: CGFloat = 0.8
    @State private var pawRotation: Double = 0
    
    init() {
        let schema = Schema([PetAsset.self])
        let config = ModelConfiguration(schema: schema, groupContainer: .identifier("group.com.furframe.app"))
        let container = try! ModelContainer(for: schema, configurations: [config])
        _scanner = StateObject(wrappedValue: PetScanner(modelContext: ModelContext(container)))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "F9F9F7")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Animated mascot area
                ZStack {
                    // Background circles
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 220, height: 220)
                        .scaleEffect(pawScale)
                    
                    Circle()
                        .fill(Color.orange.opacity(0.05))
                        .frame(width: 280, height: 280)
                        .scaleEffect(pawScale * 0.9)
                    
                    // Main icon with animation
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(pawRotation))
                        .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer().frame(height: 50)
                
                // Title section
                VStack(spacing: 16) {
                    Text("Find Your Fur Babies")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    Text("Apple's on-device AI privately finds every cat & dog in your library. Nothing ever leaves your phone.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                
                // Bottom section with button or loading
                VStack(spacing: 24) {
                    if scanner.isScanning {
                        // Loading state
                        VStack(spacing: 20) {
                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * CGFloat(scanner.progress), height: 8)
                                        .animation(.easeInOut(duration: 0.3), value: scanner.progress)
                                }
                            }
                            .frame(height: 8)
                            .padding(.horizontal, 40)
                            
                            // Animated text
                            Text(scanner.progressText)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.gray)
                                .id(scanner.progressText)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: scanner.progressText)
                        }
                    } else if scanner.hasScanned && scanner.foundCount == 0 {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.orange.opacity(0.6))
                            
                            Text("No fur babies found yet!")
                                .font(.headline)
                            
                            Text("Try adding some pet photos to your library first.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button {
                                Task { await scanner.startScan() }
                            } label: {
                                Text("Scan Again")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(20)
                            }
                            .padding(.top, 8)
                        }
                    } else {
                        // Main CTA button
                        Button {
                            Task {
                                await scanner.requestPermissionAndStartScan()
                                if scanner.foundCount > 0 {
                                    withAnimation(.spring()) {
                                        hasCompletedOnboarding = true
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Allow Photo Access")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
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
                        .padding(.horizontal, 40)
                        
                        // Privacy note
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                                .font(.caption2)
                            Text("100% Private • On-Device Only")
                                .font(.caption2)
                        }
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Entry animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
            
            // Continuous floating animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pawScale = 1.0
            }
            
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                pawRotation = 360
            }
        }
    }
}



#Preview {
    OnboardingView()
}
