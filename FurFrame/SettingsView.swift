//
//  SettingsView.swift
//  FurFrame
//
//  Created by FurFrame on 2026/3/14.
//

import SwiftUI
import SwiftData
import Photos

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var assets: [PetAsset]
    
    @State private var photoStatus: PHAuthorizationStatus = .notDetermined
    @State private var showResetConfirmation = false
    @State private var showClearConfirmation = false
    @AppStorage("lastScanDate") private var lastScanDate: Date?
    
    var body: some View {
        NavigationStack {
            List {
                // Photo Library Section
                Section {
                    HStack {
                        Label("Photo Access", systemImage: "photo.on.rectangle")
                        Spacer()
                        Text(statusText)
                            .foregroundColor(statusColor)
                            .font(.subheadline)
                    }
                    
                    if photoStatus == .limited {
                        Button("Allow Full Access") {
                            openAppSettings()
                        }
                        .foregroundColor(.orange)
                    }
                    
                    Button {
                        Task { await rescanPhotos() }
                    } label: {
                        HStack {
                            Label("Re-scan Photos", systemImage: "arrow.clockwise")
                            Spacer()
                            if let date = lastScanDate {
                                Text("Last: \(date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                } header: {
                    Text("Photo Library")
                } footer: {
                    Text("Scan your entire photo library to find all pet photos. This process uses on-device AI and never uploads your photos.")
                }
                
                // Stats Section
                Section("Statistics") {
                    StatRow(title: "Total Pets Found", value: "\(assets.count)", icon: "pawprint.fill", color: .orange)
                    StatRow(title: "Favorites", value: "\(assets.filter(\.isFavorite).count)", icon: "heart.fill", color: .red)
                    StatRow(title: "Cats", value: "\(assets.filter { $0.petType == "cat" }.count)", icon: "tortoise.fill", color: .blue)
                    StatRow(title: "Dogs", value: "\(assets.filter { $0.petType == "dog" }.count)", icon: "hare.fill", color: .green)
                }
                
                // Pro Section
                Section {
                    NavigationLink(destination: PaywallView()) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                            Text("FurFrame Pro")
                            Spacer()
                            Text(isPro ? "Active" : "Upgrade")
                                .foregroundColor(isPro ? .green : .orange)
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Text("Premium")
                }
                
                // Data Management Section
                Section {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                    }
                    
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Clearing data removes all pet references from the app. Your original photos remain untouched in the Photos app.")
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    Link(destination: URL(string: "https://www.apple.com")!) {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                    
                    Link(destination: URL(string: "https://www.apple.com")!) {
                        Label("Terms of Use", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkPhotoStatus()
            }
            .alert("Clear All Data?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will remove all \(assets.count) pet references from the app. Your original photos in the Photos app will not be affected.")
            }
            .alert("Reset Onboarding?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetOnboarding()
                }
            } message: {
                Text("This will take you back to the onboarding screen. Your data will be preserved.")
            }
        }
    }
    
    private var isPro: Bool {
        UserDefaults(suiteName: "group.com.furframe.app")?.bool(forKey: "isPro") ?? false
    }
    
    private var statusText: String {
        switch photoStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorized: return "Full Access"
        case .limited: return "Limited Access"
        @unknown default: return "Unknown"
        }
    }
    
    private var statusColor: Color {
        switch photoStatus {
        case .authorized: return .green
        case .limited: return .orange
        case .denied, .restricted: return .red
        default: return .gray
        }
    }
    
    private func checkPhotoStatus() {
        photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func rescanPhotos() async {
        // Trigger a scan from the main app
        NotificationCenter.default.post(name: .init("RescanPhotos"), object: nil)
        dismiss()
    }
    
    private func clearAllData() {
        for asset in assets {
            modelContext.delete(asset)
        }
        lastScanDate = nil
    }
    
    private func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        dismiss()
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundColor(color)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    SettingsView()
}
