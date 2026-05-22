//
//  TrackStocksWatch_Complication.swift
//  TrackStocksWatch Complication
//
//  Created by Larry Shannon on 2/2/26.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), stock: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let stock = SharedStocks.getStock()
        let entry = SimpleEntry(date: Date(), stock: stock)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {

        let currentDate = Date()
        let stock = SharedStocks.getStock()
        let entry = SimpleEntry(date: currentDate, stock: stock)
        let timelineEntry = Timeline(entries: [entry], policy: .never)
        completion(timelineEntry)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let stock: WatchStock?
}

struct TrackStocksWatch_ComplicationEntryView : View {
    var entry: Provider.Entry

    var body: some View {

        if entry.stock == nil {
            Image(.smallComplication)
        } else {
//            VStack {
//                Text("\(entry.stock!.symbol)")
//                Text("\(entry.stock!.price, specifier: "%.2f")")
//            }

            VStack {
                Text(entry.stock!.symbol)
                Text("\(String(format: "%.2f", entry.stock!.price))")
                    .font(.caption)
                Text("\(String(format: "%.2f", entry.stock!.change))")
                    .font(.caption)
            }
        }
    }
}

struct TrackStocksWatch_Complication: Widget {
    let kind: String = "TrackStocksWatch_Complication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TrackStocksWatch_ComplicationEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Stocks")
        .description("Launch Stock Tracker from the watch")
        .supportedFamilies([.accessoryCircular,.accessoryCorner,.accessoryInline])
    }
}

#Preview(as: .accessoryRectangular) {
    TrackStocksWatch_Complication()
} timeline: {
    SimpleEntry(date: .now, stock: nil)
}
