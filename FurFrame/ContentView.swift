//
//  ContentView.swift
//  FurFrame
//
//  Created by Adward on 2026/3/14.
//

import SwiftUI
import SwiftData
import Photos

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var photoStatus: PHAuthorizationStatus = .notDetermined
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingFlowView {
                    hasCompletedOnboarding = true
                }
            } else {
                MainTabView()
            }
        }
        .onAppear {
            photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        }
    }
}

// MARK: - Onboarding Flow View
struct OnboardingFlowView: View {
    let onComplete: () -> Void
    
    @State private var currentStep: OnboardingStep = .welcome
    @StateObject private var scanner: PetScanner
    
    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        let schema = Schema([PetAsset.self])
        let config = ModelConfiguration(schema: schema, groupContainer: .identifier("group.com.furframe.app"))
        let container = try! ModelContainer(for: schema, configurations: [config])
        _scanner = StateObject(wrappedValue: PetScanner(modelContext: ModelContext(container)))
    }
    
    enum OnboardingStep {
        case welcome           // 初始页面
        case scanning          // 扫描中
        case empty            // 扫描完成但没找到宠物
        case denied           // 权限被拒绝
    }
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .welcome:
                OnboardingView(
                    onRequestPermission: {
                        Task {
                            await requestPermissionAndScan()
                        }
                    }
                )
                .transition(.opacity)
                
            case .scanning:
                ScanningView(scanner: scanner)
                    .transition(.opacity)
                    .onChange(of: scanner.hasScanned) { _, hasScanned in
                        if hasScanned {
                            if scanner.foundCount == 0 {
                                withAnimation {
                                    currentStep = .empty
                                }
                            } else {
                                onComplete()
                            }
                        }
                    }
                
            case .empty:
                EmptyStateView {
                    Task {
                        withAnimation {
                            currentStep = .scanning
                        }
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        await scanner.startScan()
                    }
                }
                .transition(.opacity)
                
            case .denied:
                DeniedStateView()
                    .transition(.opacity)
            }
        }
    }
    
    private func requestPermissionAndScan() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            // First switch to scanning page
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .scanning
            }
            // Wait for animation to complete before starting scan
            try? await Task.sleep(nanoseconds: 350_000_000)
            await scanner.startScan()
            
        case .denied, .restricted:
            withAnimation {
                currentStep = .denied
            }
            
        case .notDetermined:
            break
            
        @unknown default:
            break
        }
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    let onRequestPermission: () -> Void
    @State private var showContent = false
    @State private var illustrationScale: CGFloat = 0.9
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Illustration Area
                ZStack {
                    Circle()
                        .fill(Color.appOrange.opacity(0.08))
                        .frame(width: 280, height: 280)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 180, height: 180)
                        .shadow(color: .black.opacity(0.06), radius: 40, x: 0, y: 10)
                    
                    Image(systemName: "dog.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.appTextPrimary)
                    
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
                
                // Bottom Section - Button
                VStack(spacing: 16) {
                    Button(action: onRequestPermission) {
                        Text("Allow Photo Access")
                            .font(.appBodySemibold)
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .padding(.horizontal, .appSpacingXXLarge)
                    
                    Text("Photos never leave your device")
                        .font(.appCaption)
                        .foregroundColor(.appTextTertiary)
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
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                ProgressRing(
                    progress: scanner.progress,
                    lineWidth: 8,
                    color: .appOrange
                )
                .frame(width: 140, height: 140)
                
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
                
                Spacer()
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    var body: some View {
        MemoriesView()
    }
}

// Helper
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PetAsset.self, inMemory: true)
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
