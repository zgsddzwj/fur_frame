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
                // Check photo access status for onboarding flow
                OnboardingFlowView()
            } else {
                // Main app
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
    @StateObject private var scanner: PetScanner
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        let schema = Schema([PetAsset.self])
        let config = ModelConfiguration(schema: schema, groupContainer: .identifier("group.com.furframe.app"))
        let container = try! ModelContainer(for: schema, configurations: [config])
        _scanner = StateObject(wrappedValue: PetScanner(modelContext: ModelContext(container)))
    }
    
    var body: some View {
        Group {
            switch scanner.accessStatus {
            case .denied:
                DeniedStateView()
            case .notDetermined:
                OnboardingView()
            case .authorized, .limited:
                if scanner.isScanning {
                    // Show scanning view
                    ScanningContainerView(scanner: scanner)
                } else if scanner.hasScanned && scanner.foundCount == 0 {
                    // Empty state
                    EmptyStateView {
                        Task {
                            await scanner.startScan()
                        }
                    }
                } else if scanner.hasScanned && scanner.foundCount > 0 {
                    // Go to main app
                    MainTabView()
                        .onAppear {
                            hasCompletedOnboarding = true
                        }
                } else {
                    // Initial state - show onboarding
                    OnboardingView()
                }
            }
        }
    }
}

// MARK: - Scanning Container
struct ScanningContainerView: View {
    @ObservedObject var scanner: PetScanner
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
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
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.appOrange)
                        
                        Text(scanner.progressText)
                            .font(.appCalloutMedium)
                            .foregroundColor(.appTextPrimary)
                    }
                    
                    Text("Organizing memories locally...")
                        .font(.appFootnote)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                // Skip button
                Button("Skip to Feed (Prototype)") {
                    hasCompletedOnboarding = true
                }
                .font(.appCallout)
                .foregroundColor(.appTextSecondary)
                .padding(.bottom, 48)
            }
        }
        .onChange(of: scanner.hasScanned) { _, hasScanned in
            if hasScanned && scanner.foundCount > 0 {
                hasCompletedOnboarding = true
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowImage = nil
        appearance.shadowColor = nil
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(hex: "FF6B35")
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(hex: "FF6B35")]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
            MemoriesView()
                .tabItem {
                    Label("Memories", systemImage: "photo.stack.fill")
                }
            
            WidgetStudioView()
                .tabItem {
                    Label("Studio", systemImage: "square.grid.2x2.fill")
                }
        }
        .tint(.appOrange)
    }
}

// Helper to convert hex to UIColor
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
