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
    @State private var showPaywall = false
    @AppStorage("isPro", store: UserDefaults(suiteName: "group.com.furframe.app")) var isPro: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                // Pro Banner
                if !isPro {
                    ProBanner {
                        showPaywall = true
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.bottom, 8)
                }
                
                // LIBRARY Section
                Section {
                    NavigationLink {
                        Text("Rescan View")
                    } label: {
                        HStack {
                            Text("Rescan Photo Library")
                                .font(.appBody)
                            Spacer()
                        }
                    }
                    
                    NavigationLink {
                        Text("Hidden Pets View")
                    } label: {
                        HStack {
                            Text("Hidden Pets")
                                .font(.appBody)
                            Spacer()
                            Text("0")
                                .font(.appCallout)
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                } header: {
                    Text("LIBRARY")
                        .font(.appCaptionMedium)
                        .foregroundColor(.appTextSecondary)
                } footer: {
                    Text("Re-scanning securely processes photos locally on your device without using the internet.")
                        .font(.appCaption)
                        .foregroundColor(.appTextSecondary)
                        .padding(.top, 4)
                }
                
                // ACCOUNT Section
                Section {
                    Button("Restore Purchases") {
                        // Restore logic
                    }
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                    
                    Button("Manage Subscription") {
                        // Open App Store subscription management
                        if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                } header: {
                    Text("ACCOUNT")
                        .font(.appCaptionMedium)
                        .foregroundColor(.appTextSecondary)
                }
                
                // ABOUT Section
                Section {
                    Button("Contact Support") {
                        // Open support
                    }
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                    
                    Button("Privacy Policy") {
                        // Open privacy policy
                    }
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                } header: {
                    Text("ABOUT")
                        .font(.appCaptionMedium)
                        .foregroundColor(.appTextSecondary)
                }
                
                // Version
                Section {
                    HStack {
                        Spacer()
                        Text("FurFrame v1.0.0")
                            .font(.appCaption)
                            .foregroundColor(.appTextTertiary)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.appSecondaryBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.appCalloutMedium)
                    .foregroundColor(.appOrange)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .presentationDetents([.fraction(0.75)])
        }
    }
}

// MARK: - Pro Banner
struct ProBanner: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("FurFrame Pro")
                        .font(.appCalloutMedium)
                        .foregroundColor(.white)
                    
                    Text("Unlock premium themes")
                        .font(.appCaption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, .appSpacingLarge)
            .padding(.vertical, .appSpacingMedium)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FF6B35"), Color(hex: "EC4899")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(.appRadiusXLarge)
            .padding(.horizontal, .appSpacingLarge)
        }
    }
}

#Preview {
    SettingsView()
}
