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
            ZStack {
                Color(hex: "F2F2F7").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Pro Banner
                        if !isPro {
                            ProBanner {
                                showPaywall = true
                            }
                        }
                        
                        // LIBRARY Section
                        SettingsSection(title: "LIBRARY") {
                            SettingsRow(title: "Rescan Photo Library", icon: nil) {
                                // Rescan action
                            }
                            
                            Divider().padding(.leading, 16)
                            
                            SettingsRow(title: "Hidden Pets", value: "0") {
                                // Hidden pets action
                            }
                        }
                        
                        Text("Re-scanning securely processes photos locally on your device without using the internet.")
                            .font(.appCaption)
                            .foregroundColor(.appTextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.top, -12)
                        
                        // ACCOUNT Section
                        SettingsSection(title: "ACCOUNT") {
                            SettingsRow(title: "Restore Purchases", icon: nil) {
                                // Restore action
                            }
                            
                            Divider().padding(.leading, 16)
                            
                            SettingsRow(title: "Manage Subscription", icon: nil) {
                                if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        
                        // ABOUT Section
                        SettingsSection(title: "ABOUT") {
                            SettingsRow(title: "Contact Support", icon: nil) {
                                // Contact action
                            }
                            
                            Divider().padding(.leading, 16)
                            
                            SettingsRow(title: "Privacy Policy", icon: nil) {
                                // Privacy action
                            }
                        }
                        
                        // Version
                        Text("FurFrame v1.0.0")
                            .font(.appCaption)
                            .foregroundColor(.appTextTertiary)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 34)
                }
            }
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
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FF6B35"), Color(hex: "EC4899")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.appCaptionMedium)
                .foregroundColor(.appTextSecondary)
                .padding(.horizontal, 8)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let title: String
    var value: String? = nil
    var icon: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(.appCallout)
                        .foregroundColor(.appTextSecondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

#Preview {
    SettingsView()
}
