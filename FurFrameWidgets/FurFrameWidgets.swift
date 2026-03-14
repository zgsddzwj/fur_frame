//
//  FurFrameWidgets.swift
//  FurFrameWidgets
//
//  Created by Adward on 2026/3/14.
//

import WidgetKit
import SwiftUI
import SwiftData
import Photos

enum WidgetTheme: String, CaseIterable, Identifiable {
    case minimal, polaroid, film, polaroidDate, standbyClock
    var id: String { self.rawValue }
    
    var label: String {
        switch self {
        case .minimal: return "Minimal"
        case .polaroid: return "Polaroid"
        case .film: return "Film"
        case .polaroidDate: return "Polaroid + Date"
        case .standbyClock: return "StandBy Clock"
        }
    }
    
    var isPro: Bool {
        switch self {
        case .minimal, .polaroid: return false
        default: return true
        }
    }
}

struct PetEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
    let asset: PetAsset?
    let theme: WidgetTheme
    let albumSource: String
}

struct Provider: TimelineProvider {
    @MainActor
    private var modelContainer: ModelContainer = {
        let schema = Schema([PetAsset.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.furframe.app")
        )
        return try! ModelContainer(for: schema, configurations: [config])
    }()
    
    func placeholder(in context: Context) -> PetEntry {
        PetEntry(date: Date(), image: nil, asset: nil, theme: .minimal, albumSource: "All Pets")
    }

    func getSnapshot(in context: Context, completion: @escaping (PetEntry) -> ()) {
        Task { @MainActor in
            let entry = await fetchNextEntry(for: Date())
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetEntry>) -> ()) {
        Task { @MainActor in
            var entries: [PetEntry] = []
            let currentDate = Date()
            
            // Create 24 hourly entries for the next day
            for i in 0..<24 {
                let entryDate = Calendar.current.date(byAdding: .hour, value: i, to: currentDate)!
                let entry = await fetchNextEntry(for: entryDate)
                entries.append(entry)
            }
            
            completion(Timeline(entries: entries, policy: .atEnd))
        }
    }
    
    @MainActor
    private func fetchNextEntry(for date: Date) async -> PetEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.furframe.app")
        let themeRaw = userDefaults?.string(forKey: "widgetTheme") ?? "minimal"
        let theme = WidgetTheme(rawValue: themeRaw) ?? .minimal
        let albumSource = userDefaults?.string(forKey: "widgetAlbumSource") ?? "All Pets"
        
        let descriptor = FetchDescriptor<PetAsset>(
            predicate: albumSource == "Favorites Only" ? #Predicate { $0.isFavorite == true } : nil,
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
        
        let assets = (try? modelContainer.mainContext.fetch(descriptor)) ?? []
        guard !assets.isEmpty else {
            return PetEntry(date: date, image: nil, asset: nil, theme: theme, albumSource: albumSource)
        }
        
        // Rotate through assets based on hour
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let assetIndex = hour % assets.count
        let selectedAsset = assets[assetIndex]
        
        let image = await loadThumbnail(for: selectedAsset.localIdentifier)
        
        return PetEntry(date: date, image: image, asset: selectedAsset, theme: theme, albumSource: albumSource)
    }
    
    private func loadThumbnail(for localId: String) async -> UIImage? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }
        
        // Memory limit optimization - 30MB limit
        let targetSize = CGSize(width: 500, height: 500)
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}

struct FurFrameWidgetsEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Base image
            if let image = entry.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Empty state
                ZStack {
                    Color(hex: "F5F5F3")
                    
                    VStack(spacing: 12) {
                        Image(systemName: "pawprint.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange.opacity(0.5))
                        
                        Text("FurFrame")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Theme overlay
            ThemeOverlay(entry: entry, family: family)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct ThemeOverlay: View {
    let entry: PetEntry
    let family: WidgetFamily
    
    var body: some View {
        switch entry.theme {
        case .minimal:
            MinimalOverlay()
        case .polaroid:
            PolaroidOverlay(family: family, showDate: false, date: nil)
        case .polaroidDate:
            PolaroidOverlay(family: family, showDate: true, date: entry.asset?.creationDate)
        case .film:
            FilmOverlay()
        case .standbyClock:
            StandbyClockOverlay(entry: entry, family: family)
        }
    }
}

// MARK: - Minimal Theme
struct MinimalOverlay: View {
    var body: some View {
        ZStack {
            // Small watermark in corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(8)
                }
            }
        }
    }
}

// MARK: - Polaroid Theme
struct PolaroidOverlay: View {
    let family: WidgetFamily
    let showDate: Bool
    let date: Date?
    
    var bottomPadding: CGFloat {
        family == .systemSmall ? 25 : 35
    }
    
    var body: some View {
        ZStack {
            // White border effect
            VStack(spacing: 0) {
                Color.clear
                    .padding(8)
                    .padding(.top, 8)
                
                ZStack {
                    Color.white.frame(height: bottomPadding)
                    
                    if showDate, let date = date {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.custom("Bradley Hand", size: family == .systemSmall ? 10 : 12, relativeTo: .caption))
                            .foregroundColor(.black.opacity(0.7))
                            .rotationEffect(.degrees(-3))
                    }
                }
            }
            .padding(4)
        }
    }
}

// MARK: - Film Theme
struct FilmOverlay: View {
    var body: some View {
        ZStack {
            // Black frame
            Color.black
            
            // Photo area with vignette
            GeometryReader { geo in
                ZStack {
                    // Vignette effect
                    RadialGradient(
                        colors: [.clear, .black.opacity(0.4)],
                        center: .center,
                        startRadius: geo.size.width * 0.3,
                        endRadius: geo.size.width * 0.7
                    )
                    
                    // Noise overlay (simulated with pattern)
                    Image(systemName: "circle.grid.2x2.fill")
                        .resizable()
                        .opacity(0.03)
                        .blendMode(.overlay)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            
            // Film sprocket holes
            HStack {
                // Left holes
                VStack(spacing: 10) {
                    ForEach(0..<6) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.yellow.opacity(0.8))
                            .frame(width: 5, height: 8)
                    }
                }
                
                Spacer()
                
                // Right holes
                VStack(spacing: 10) {
                    ForEach(0..<6) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.yellow.opacity(0.8))
                            .frame(width: 5, height: 8)
                    }
                }
            }
            .padding(.horizontal, 5)
        }
    }
}

// MARK: - StandBy Clock Theme
struct StandbyClockOverlay: View {
    let entry: PetEntry
    let family: WidgetFamily
    
    var body: some View {
        ZStack {
            Color.black
            
            HStack(spacing: family == .systemSmall ? 12 : 20) {
                // Pet avatar placeholder
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: avatarSize, height: avatarSize)
                    
                    if entry.image == nil {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: avatarSize * 0.4))
                            .foregroundColor(.orange)
                    }
                }
                
                if family != .systemSmall {
                    Spacer()
                }
                
                // Clock
                VStack(alignment: .trailing, spacing: -5) {
                    let components = entry.date.formatted(date: .omitted, time: .shortened).split(separator: ":")
                    if components.count >= 2 {
                        Text(String(components[0]))
                            .font(.system(size: family == .systemSmall ? 40 : 60, weight: .black, design: .rounded))
                            .foregroundColor(neonColor)
                            .shadow(color: neonColor.opacity(0.6), radius: 10)
                        
                        HStack(spacing: 2) {
                            Text(":")
                            Text(String(components[1]))
                        }
                        .font(.system(size: family == .systemSmall ? 40 : 60, weight: .black, design: .rounded))
                        .foregroundColor(neonColor)
                        .shadow(color: neonColor.opacity(0.6), radius: 10)
                    }
                }
            }
            .padding()
        }
    }
    
    private var avatarSize: CGFloat {
        switch family {
        case .systemSmall: return 60
        case .systemMedium: return 80
        case .systemLarge: return 100
        default: return 70
        }
    }
    
    private var neonColor: Color {
        Color(hex: "39FF14") // Neon green
    }
}

// MARK: - Widget Configuration
struct FurFrameWidgets: Widget {
    let kind: String = "FurFrameWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FurFrameWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Pet Frame")
        .description("Display your fur babies on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Helper Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
@available(iOS 17.0, *)
#Preview(as: .systemSmall, widget: { FurFrameWidgets() }) {
    PetEntry(
        date: Date(),
        image: nil,
        asset: nil,
        theme: .minimal,
        albumSource: "All Pets"
    )
}

@available(iOS 17.0, *)
#Preview(as: .systemMedium, widget: { FurFrameWidgets() }) {
    PetEntry(
        date: Date(),
        image: nil,
        asset: nil,
        theme: .standbyClock,
        albumSource: "All Pets"
    )
}
