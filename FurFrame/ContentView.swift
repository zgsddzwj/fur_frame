//
//  ContentView.swift
//  FurFrame
//
//  Created by Adward on 2026/3/14.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    init() {
        // Customize TabBar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Remove top border
        appearance.shadowImage = nil
        appearance.shadowColor = nil
        
        // Set item colors
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.orange
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.orange]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MemoriesView()
                .tabItem {
                    Label("Memories", systemImage: "photo.stack.fill")
                }
                .tag(0)
            
            WidgetStudioView()
                .tabItem {
                    Label("Studio", systemImage: "square.grid.2x2.fill")
                }
                .tag(1)
        }
        .tint(.orange)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PetAsset.self, inMemory: true)
}
