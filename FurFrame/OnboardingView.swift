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
    
    @State private var showContent = false
    @State private var illustrationScale: CGFloat = 0.9
    
    init() {
        let schema = Schema([PetAsset.self])
        let config = ModelConfiguration(schema: schema, groupContainer: .identifier("group.com.furframe.app"))
        let container = try! ModelContainer(for: schema, configurations: [config])
        _scanner = StateObject(wrappedValue: PetScanner(modelContext: ModelContext(container)))
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Illustration Area
                ZStack {
                    // Background glow
                    Circle()
                        .fill(Color.appOrange.opacity(0.08))
                        .frame(width: 280, height: 280)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 180, height: 180)
                        .shadow(color: .black.opacity(0.06), radius: 40, x: 0, y: 10)
                    
                    // TODO: Replace with actual dog with magnifying glass illustration
                    Image(systemName: "dog.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.appTextPrimary)
                    
                    // Magnifying glass icon
                    Circle()
                        .fill(Color.appOrange)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .appOrange.opacity(0.4), radius: 12, x: 0, y: 6)
                        .offset(x: 70, y: 60)
                }
                .scaleEffect(illustrationScale)
                .opacity(showContent ? 1 : 0)
                
                Spacer().frame(height: 48)
                
                // Text Content
                VStack(spacing: 12) {
                    Text("Find Your\nFur Babies")
                        .font(.appDisplay)
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("On-device AI privately\nfinds your pets.")
                        .font(.appBody)
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                
                // Bottom Section
                VStack(spacing: 16) {
                    if scanner.isScanning {
                        // Scanning State
                        ScanningView(scanner: scanner)
                    } else {
                        // CTA Button
                        Button {
                            Task {
                                await scanner.requestPermissionAndStartScan()
                                if scanner.foundCount > 0 || scanner.hasScanned {
                                    withAnimation(.spring()) {
                                        hasCompletedOnboarding = true
                                    }
                                }
                            }
                        } label: {
                            Text("Allow Photo Access")
                                .font(.appBodySemibold)
                        }
                        .buttonStyle(AppPrimaryButtonStyle())
                        .padding(.horizontal, .appSpacingXXLarge)
                        
                        // Privacy note
                        Text("Photos never leave your device")
                            .font(.appCaption)
                            .foregroundColor(.appTextTertiary)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                illustrationScale = 1.0
            }
        }
    }
}

// MARK: - Scanning View
struct ScanningView: View {
    @ObservedObject var scanner: PetScanner
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 32) {
            // Progress Ring
            ProgressRing(
                progress: scanner.progress,
                lineWidth: 8,
                color: .appOrange
            )
            .frame(width: 140, height: 140)
            
            // Status Text
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                        .font(.system(size: 16))
                        .foregroundColor(.appOrange)
                        .rotationEffect(.degrees(rotation))
                        .onAppear {
                            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }
                    
                    Text(scanner.progressText)
                        .font(.appCalloutMedium)
                        .foregroundColor(.appTextPrimary)
                }
                
                Text("Organizing memories locally...")
                    .font(.appFootnote)
                    .foregroundColor(.appTextSecondary)
            }
            .id(scanner.progressText)
            .animation(.easeInOut, value: scanner.progressText)
            
            // Skip button (for prototype)
            Button("Skip to Feed (Prototype)") {
                // Skip logic for testing
            }
            .font(.appCallout)
            .foregroundColor(.appTextSecondary)
            .padding(.top, 24)
        }
        .padding(.horizontal, .appSpacingXXLarge)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let onScanAgain: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(Color.appError.opacity(0.08))
                    .frame(width: 180, height: 180)
                
                // TODO: Replace with confused dog illustration
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.appError.opacity(0.6))
            }
            
            // Text
            VStack(spacing: 12) {
                Text("No fur babies\nfound yet!")
                    .font(.appHeadline)
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Try adding some pet photos\nto your library first.")
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Ghost Button
            Button(action: onScanAgain) {
                Text("Scan Again")
                    .font(.appCalloutMedium)
            }
            .buttonStyle(AppGhostButtonStyle())
            .padding(.horizontal, .appSpacingXXLarge)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
    }
}

// MARK: - Denied State View
struct DeniedStateView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Navigation
            HStack {
                Text("Home")
                    .font(.appCalloutMedium)
                    .foregroundColor(.appOrange)
                Spacer()
            }
            .padding(.horizontal, .appSpacingLarge)
            .padding(.top, .appSpacingLarge)
            
            Spacer()
            
            // Content
            VStack(spacing: 32) {
                // Sad illustration
                ZStack {
                    Circle()
                        .fill(Color.appError.opacity(0.08))
                        .frame(width: 120, height: 120)
                    
                    // TODO: Replace with sad puppy illustration
                    Image(systemName: "face.dashed")
                        .font(.system(size: 50))
                        .foregroundColor(.appError)
                }
                
                // Text
                VStack(spacing: 16) {
                    Text("Needs Photo\nAccess")
                        .font(.appHeadline)
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("FurFrame relies on photo access to anonymously scan and locate your pets on-device. We cannot function without it.")
                        .font(.appCallout)
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }
            }
            
            Spacer()
            
            // Bottom Buttons
            VStack(spacing: 12) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(.appBodySemibold)
                }
                .buttonStyle(AppPrimaryButtonStyle())
                
                Text("Settings > Privacy > Photos")
                    .font(.appCaption)
                    .foregroundColor(.appTextTertiary)
            }
            .padding(.horizontal, .appSpacingXXLarge)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
    }
}

#Preview {
    OnboardingView()
}
