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
        
//        let currentDate = Date()
//        let formatter3 = DateFormatter()
//        formatter3.dateFormat = "HH:mm E, d MMM y"
//        let string = formatter3.string(from: Date.now)
//        let notificationData = NotificationData(symbol: string)
//        let entryDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
//        let entry = SimpleEntry(date: entryDate, items: [notificationData])
//        let timeline = Timeline(entries: [entry], policy: .atEnd)
//
//        completion(timeline)
        
    }
    
}

struct SimpleEntry: TimelineEntry {
    let id = UUID().uuidString
    let date: Date
    var items: [NotificationData]
}

struct WidgetView: View {
    var entry: Provider.Entry
    @State var date = ""
    
    var body: some View {
        VStack {
            Text(date)
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
        .onAppear {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            dateFormatter.locale = Locale.current
            date = dateFormatter.string(from: Date.now)
        }
    }
}

struct StocksNotificationWidget: Widget {
//    init() {
//        FirebaseApp.configure()
//        do {
//            try Auth.auth().useUserAccessGroup("DDDAQ32TPA.com.breakawaydesign.TrackStocks")
//        } catch {
//            debugPrint(String.boom, "Auth.auth().useUserAccessGroup failed: \(error.localizedDescription)")
//        }
//    }
//    let kind: String = "StocksNotificationWidget"
//
//    var body: some WidgetConfiguration {
//        StaticConfiguration(kind: kind, provider: Provider()) { entry in
//            WidgetView(entry: entry)
//                .containerBackground(.fill.tertiary, for: .widget)
//        }
//        .supportedFamilies([.systemLarge, .accessoryRectangular])
//        .configurationDisplayName("My Lists")
//        .description("View your current list")
//    }
    
    var body: some WidgetConfiguration {
//        ActivityConfiguration(for: StockTrackingAttributes.self) { context in
//            StockTrackingWidgetView(context: context)
        ActivityConfiguration(for: StockActivityAttributes.self) { context in
            StockActivityWidgetView(activityData: context.state.items)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    StockActivityWidgetView(activityData: context.state.items)
                }
            } compactLeading: {
//                Text("CL")
            } compactTrailing: {
//                Text("CT")
            } minimal: {
//                Text("M")
            }
        }
    }
    
}

struct StockActivityWidgetView: View {
    @Environment(\.colorScheme) var colorScheme
    var activityData: [ActivityData]
    @State var data: [ActivityData] = []
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Date.now, style: .date)
                Text(Date.now, style: .time)
            }
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            ForEach(data, id: \.id) { item in
                HStack {
                    Text(item.symbol)
                    Text(item.marketPrice, format: .currency(code: "USD"))
                    Text("\(String(format: "%.2f", item.change))")
                        .padding([.leading, .trailing], 5)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(item.change < 0 ?.red : .green)
                        )
                }
            }
        }
        .padding(20)
        .onAppear {
            data = activityData.sorted { $0.symbol < $1.symbol }
        }
    }
}


struct StockTrackingWidgetView: View {
    let context: ActivityViewContext<StockTrackingAttributes>
    @State var notificationData: [NotificationData] = []
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Date.now, style: .date)
                Text(Date.now, style: .time)
            }
            ForEach(notificationData, id: \.id) { item in
                HStack {
                    Text(item.symbol)
                    Text(item.marketPrice, format: .currency(code: "USD"))
                    Text("\(String(format: "%.2f", item.change))")
                        .padding([.leading, .trailing], 5)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(item.change < 0 ?.red : .green)
                        )
                }
            }
        }
        .padding(20)
        .onAppear {
            notificationData = context.state.items
        }
    }
}
