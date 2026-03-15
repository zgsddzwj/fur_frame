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
    case minimal, polaroid, film
    var id: String { self.rawValue }
    
    var label: String {
        switch self {
        case .minimal: return "Minimal"
        case .polaroid: return "Polaroid"
        case .film: return "Film Pro"
        }
    }
    
    var isPro: Bool {
        switch self {
        case .minimal, .polaroid: return false
        case .film: return true
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
            if let image = entry.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack {
                    Color(hex: "F5F5F3")
                    VStack(spacing: 8) {
                        Image(systemName: "pawprint.circle")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: "FF6B35").opacity(0.5))
                        Text("FurFrame")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                }
            }
            
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
            PolaroidOverlay(family: family)
        case .film:
            FilmOverlay(family: family)
        }
    }
}

// MARK: - Minimal Theme
struct MinimalOverlay: View {
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(8)
                }
            }
        }
    }
}

// MARK: - Polaroid Theme
struct PolaroidOverlay: View {
    let family: WidgetFamily
    
    var bottomHeight: CGFloat {
        family == .systemSmall ? 24 : 32
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Color.clear
                Color.white.frame(height: bottomHeight)
            }
            .padding(8)
            
            VStack {
                Spacer()
                Text("memories")
                    .font(.system(size: family == .systemSmall ? 8 : 10, design: .serif))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .padding(.bottom, family == .systemSmall ? 6 : 8)
            }
        }
    }
}

// MARK: - Film Theme
struct FilmOverlay: View {
    let family: WidgetFamily
    
    var body: some View {
        ZStack {
            Color.black
            
            // Photo area
            GeometryReader { geo in
                ZStack {
                    Color.clear
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                    
                    // Vignette
                    RadialGradient(
                        colors: [.clear, .black.opacity(0.4)],
                        center: .center,
                        startRadius: geo.size.width * 0.3,
                        endRadius: geo.size.width * 0.6
                    )
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                }
            }
            
            // Film holes
            HStack {
                VStack(spacing: family == .systemSmall ? 6 : 8) {
                    ForEach(0..<(family == .systemSmall ? 4 : 6)) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hex: "FFD60A").opacity(0.8))
                            .frame(width: 4, height: family == .systemSmall ? 6 : 8)
                    }
                }
                Spacer()
                VStack(spacing: family == .systemSmall ? 6 : 8) {
                    ForEach(0..<(family == .systemSmall ? 4 : 6)) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hex: "FFD60A").opacity(0.8))
                            .frame(width: 4, height: family == .systemSmall ? 6 : 8)
                    }
                }
            }
            .padding(.horizontal, 5)
        }
    }
}

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
