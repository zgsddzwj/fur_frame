//
//  StandByPreviewView.swift
//  FurFrame
//
//  Created by FurFrame on 2026/3/14.
//

import SwiftUI
import Combine

struct StandByPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro", store: UserDefaults(suiteName: "group.com.furframe.app")) var isPro: Bool = false
    @State private var showPaywall = false
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation
                HStack {
                    Button("Cancel Focus") {
                        dismiss()
                    }
                    .font(.appCallout)
                    .foregroundColor(.appTextSecondary)
                    
                    Spacer()
                }
                .padding(.horizontal, .appSpacingLarge)
                .padding(.top, .appSpacingLarge)
                
                Spacer()
                
                // StandBy Widget Card
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color(hex: "1C1C1E"))
                        .frame(width: 340, height: 160)
                    
                    HStack(spacing: 20) {
                        // Pet Avatar with name
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.appOrange.opacity(0.3))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "dog.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.appOrange)
                                .frame(width: 100, height: 100)
                            
                            // Name tag
                            Text("Toby")
                                .font(.appCaptionMedium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(6)
                                .padding(8)
                        }
                        
                        Spacer()
                        
                        // Clock
                        HStack(spacing: 4) {
                            let timeString = currentTime.formatted(date: .omitted, time: .shortened)
                            let components = timeString.split(separator: ":")
                            if components.count >= 2 {
                                Text(String(components[0]))
                                    .font(.system(size: 64, weight: .bold, design: .rounded))
                                    .foregroundColor(.appNeon)
                                
                                Text(String(components[1]))
                                    .font(.system(size: 64, weight: .bold, design: .rounded))
                                    .foregroundColor(.appNeon)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .frame(width: 340, height: 160)
                }
                .shadow(color: .appNeon.opacity(0.3), radius: 20, x: 0, y: 10)
                
                // Description
                Text("Preview of landscape StandBy mode on iOS 17.")
                    .font(.appCallout)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                
                Spacer()
                
                // Unlock Button
                if !isPro {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 8) {
                            Text("Unlock with Pro")
                                .font(.appBodySemibold)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.appTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.appGold)
                        .cornerRadius(.appRadiusCapsule)
                    }
                    .padding(.horizontal, .appSpacingXXLarge)
                    .shadow(color: .appGold.opacity(0.4), radius: 16, x: 0, y: 6)
                }
            }
            .padding(.bottom, 48)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .presentationDetents([.fraction(0.75)])
        }
    }
}

#Preview {
    StandByPreviewView()
}
