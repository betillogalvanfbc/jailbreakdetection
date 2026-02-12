//
//  JailbreakWidget.swift
//  JailbreakWidget
//
//  iOS Widget showing jailbreak detection status
//  Updates every 15 minutes
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            isJailbroken: false,
            threatsDetected: 0,
            totalChecks: 8
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(
            date: Date(),
            isJailbroken: SharedData.isJailbroken(),
            threatsDetected: SharedData.getThreatCount(),
            totalChecks: 8
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = SimpleEntry(
            date: currentDate,
            isJailbroken: SharedData.isJailbroken(),
            threatsDetected: SharedData.getThreatCount(),
            totalChecks: 8
        )
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let isJailbroken: Bool
    let threatsDetected: Int
    let totalChecks: Int
}

// MARK: - Widget Views
struct JailbreakWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (Compact Status)
struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        if #available(iOS 17.0, *) {
            // iOS 17+ - Usar containerBackground
            content
                .containerBackground(for: .widget) {
                    backgroundGradient
                }
        } else {
            // iOS 16 - Usar ZStack tradicional
            ZStack {
                backgroundGradient
                content
            }
        }
    }
    
    private var content: some View {
        VStack(spacing: 8) {
            Image(systemName: entry.isJailbroken ? "exclamationmark.shield.fill" : "checkmark.shield.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
            
            Text(entry.isJailbroken ? "JAILBROKEN" : "SECURE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if entry.isJailbroken {
                Text("\(entry.threatsDetected) threats")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: entry.isJailbroken
                ? [Color.red.opacity(0.8), Color.orange.opacity(0.6)]
                : [Color.green.opacity(0.8), Color.blue.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Medium Widget (Status + Stats)
struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        if #available(iOS 17.0, *) {
            // iOS 17+ - Usar containerBackground
            content
                .containerBackground(for: .widget) {
                    backgroundGradient
                }
        } else {
            // iOS 16 - Usar ZStack tradicional
            ZStack {
                backgroundGradient
                content
            }
        }
    }
    
    private var content: some View {
        HStack(spacing: 16) {
            Image(systemName: entry.isJailbroken ? "exclamationmark.shield.fill" : "checkmark.shield.fill")
                .font(.system(size: 50))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.isJailbroken ? "JAILBREAK DETECTED" : "DEVICE SECURE")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if entry.isJailbroken {
                    Text("\(entry.threatsDetected) of \(entry.totalChecks) checks failed")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                } else {
                    Text("All \(entry.totalChecks) checks passed")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Text("Updated \(entry.date, style: .relative) ago")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: entry.isJailbroken
                ? [Color.red.opacity(0.8), Color.orange.opacity(0.6)]
                : [Color.green.opacity(0.8), Color.blue.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Large Widget (Detailed View)
struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        if #available(iOS 17.0, *) {
            // iOS 17+ - Usar containerBackground
            content
                .containerBackground(for: .widget) {
                    backgroundGradient
                }
        } else {
            // iOS 16 - Usar ZStack tradicional
            ZStack {
                backgroundGradient
                content
            }
        }
    }
    
    private var content: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: entry.isJailbroken ? "exclamationmark.shield.fill" : "checkmark.shield.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading) {
                    Text(entry.isJailbroken ? "JAILBREAK DETECTED" : "DEVICE SECURE")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Security Status")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Stats
            HStack(spacing: 20) {
                StatBox(title: "Total Checks", value: "\(entry.totalChecks)", icon: "checkmark.circle")
                StatBox(title: "Threats", value: "\(entry.threatsDetected)", icon: "exclamationmark.triangle")
            }
            
            Spacer()
            
            // Footer
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("Updated \(entry.date, style: .relative) ago")
                    .font(.caption2)
            }
            .foregroundColor(.white.opacity(0.7))
        }
        .padding()
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: entry.isJailbroken
                ? [Color.red.opacity(0.8), Color.orange.opacity(0.6)]
                : [Color.green.opacity(0.8), Color.blue.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Widget Definition
struct JailbreakWidget: Widget {
    let kind: String = "JailbreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            JailbreakWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Jailbreak Detector")
        .description("Shows the current jailbreak detection status of your device.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
#if DEBUG
@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    JailbreakWidget()
} timeline: {
    SimpleEntry(date: .now, isJailbroken: false, threatsDetected: 0, totalChecks: 8)
    SimpleEntry(date: .now, isJailbroken: true, threatsDetected: 5, totalChecks: 8)
}

@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    JailbreakWidget()
} timeline: {
    SimpleEntry(date: .now, isJailbroken: false, threatsDetected: 0, totalChecks: 8)
    SimpleEntry(date: .now, isJailbroken: true, threatsDetected: 5, totalChecks: 8)
}

@available(iOS 17.0, *)
#Preview(as: .systemLarge) {
    JailbreakWidget()
} timeline: {
    SimpleEntry(date: .now, isJailbroken: false, threatsDetected: 0, totalChecks: 8)
    SimpleEntry(date: .now, isJailbroken: true, threatsDetected: 5, totalChecks: 8)
}
#endif
