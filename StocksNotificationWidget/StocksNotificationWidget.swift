//
//  StocksNotificationWidget.swift
//  StocksNotificationWidget
//
//  Created by Larry Shannon on 1/5/25.
//

import WidgetKit
import SwiftUI
import Firebase
import FirebaseAuth

class Provider: TimelineProvider {
    var firebaseService = FirebaseService.shared

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), items: [NotificationData(symbol: "IBM")])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), items: [])
        completion(entry)
        Task {
            let arrayItems = Array(await getData().prefix(2))
            let entry = SimpleEntry(date: .now, items: arrayItems)
            completion(entry)
        }
    }
    
    func getData() async -> [NotificationData] {
        let data = await firebaseService.getStocksNotification()

        return data
        
    }
    
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<SimpleEntry>) -> ()) {
        
        Task {
            let arrayItems = Array(await getData().prefix(7))
            let entry = SimpleEntry(date: .now, items: arrayItems)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        }
        
    }
    
}

struct SimpleEntry: TimelineEntry {
    let id = UUID().uuidString
    let date: Date
    var items: [NotificationData]
}

struct WidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            ForEach(entry.items, id: \.id) { item in
                HStack {
                    Text(item.symbol)
                    Text(item.marketPrice, format: .currency(code: "USD"))
                    Text("\(String(format: "%.2f", item.change))")
                        .padding([.leading, .trailing], 5)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(item.change < 0 ?.red : .green)
                        )
                    Text("\(item.volume)")
                    Spacer()
                }
                .padding(.horizontal)
                Divider()
            }
            Spacer()
        }
    }
}


struct StocksNotificationWidget: Widget {
    init() {
        FirebaseApp.configure()
        do {
            try Auth.auth().useUserAccessGroup("DDDAQ32TPA.com.breakawaydesign.TrackStocks")
        } catch {
            debugPrint(String.boom, "Auth.auth().useUserAccessGroup failed: \(error.localizedDescription)")
        }
    }
    let kind: String = "StocksNotificationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemLarge, .accessoryRectangular])
        .configurationDisplayName("My Lists")
        .description("View your current list")
    }
    
}

