//
//  widget.swift
//  widget
//
//  Created by Nadia Garcia on 01/07/21.
//  Code for a simple widget that will display bitcoin prices throughout the day. Available on small, medium and large sizes.
//

import WidgetKit
import SwiftUI

// Manages all server requests for Blockchain API
class NetworkManager {
    func getWeatherData(completion: @escaping (SimpleEntry.BTCData?) -> Void) {
        guard let url = URL(string: "https://api.blockchain.com/v3/exchange/tickers/BTC-USD") else {
            return completion(nil)
        }
        URLSession.shared.dataTask(with: url) { d, res, err
            in
            var result: SimpleEntry.BTCData?
            
            if let data = d,
               let response = res as? HTTPURLResponse, response.statusCode == 200 {
                do {
                    result = try JSONDecoder().decode(SimpleEntry.BTCData.self, from: data)
                } catch {
                    print(error)
                }
            }
            
            return completion(result)
        }.resume()
    }
}

// Establishes Timeline Snapshots (What the widget should look like throughout the day)
struct Provider: TimelineProvider {
    let networkManager = NetworkManager()
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: .previewData, error: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        networkManager.getWeatherData {
            data in
            let entry = SimpleEntry(date: Date(), data: data ?? .error, error: data == nil)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        networkManager.getWeatherData {
            data in
            let timeline = Timeline(
                entries: [SimpleEntry(date: Date(), data: data ?? .error, error: data == nil)],
                policy: .after(Calendar.current.date(byAdding: .minute, value: 15,to: Date())!)
            )
            completion(timeline)
        }
        
    }
}

// Since the widget stays the same and just refreshes its info, it is a Simple Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    var data: BTCData
    var error: Bool
    
    enum DIfferenceMode: String {
        case up = "up",
             down = "down",
             error = "error"
    }
    
    var diffMode: DIfferenceMode {
        if error || data.difference == 0.0 {
            return .error
        } else if data.difference > 0.0 {
            return .up
        } else  {
            return .down
        }
    }
    
    struct BTCData: Decodable { // Map JSON to struct
        let price_24h: Double
        let volume_24h: Double
        let last_trade_price: Double
        
        var difference: Double { price_24h - last_trade_price }
        static let previewData = BTCData(price_24h: 11370.2, volume_24h: 61.5274347, last_trade_price: 11381.5)
        
        static let error = BTCData(
            price_24h: 0,
            volume_24h: 0,
            last_trade_price: 0
        )
    }
}

// We define our UI views in here
struct widgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme
    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .unredacted()
            
            HStack {
                VStack (alignment: .leading){
                    header
                    Spacer()
                    pricing
                    if family == .systemLarge {
                        Spacer()
                        volume }
                }.padding()
                Spacer()
            }
        }
    }
    
    var header: some View {
        Group {
            Text("BTC App").bold()
                .font(family == .systemLarge ? .system(size: 40) : .title)
            Text("Bitcoin").font(family == .systemLarge ? .title : .headline)
                .padding(.top, family == .systemLarge ? -15 : 0)
        }.foregroundColor(Color("headingColor"))
    }
    
    var pricing: some View {
        Group {
            if family == .systemMedium {
                HStack(alignment: .firstTextBaseline) {
                    price
                    difference
                }
            } else {
                    price
                    difference
            }
        }
    }
    var price : some View {
    Text(entry.error ? "± ––––" : "\(entry.diffMode == .up ? "+" : "") \(String(format: "%.1f", entry.data.price_24h))")
        .bold()
        .font(family == .systemSmall ? .body : .system(size: CGFloat(family.rawValue * 25 + 5)))
        .foregroundColor(scheme == .dark ? .white : .black)
    }
    var difference: some View {
        Text(entry.error ? "± ––––" : "\(entry.diffMode == .up ? "+" : "") \(String(format: "%.2f", entry.data.difference))")
            .bold()
            .foregroundColor(Color("\(entry.diffMode)Color"))
            .font(family == .systemSmall ? .footnote : .title2)
    }
    
    var volume: some View{
        Text("VOLUME: \(entry.error ? "––––" : "\(String(format: "%.2f", entry.data.volume_24h))")")
            .bold()
            .font(.title2).foregroundColor(scheme == .dark ? .pink : .pink)
    }
}

@main
// We define configuration data in here.
// You can provide available sizes as an array
struct widget: Widget {
    let kind: String = "widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            widgetEntryView(entry: entry)
        }
        .configurationDisplayName("Bitcoin Tracker")
        .description("Track Bitcoin prices")
        
    }
}

// Xcode previews
struct widget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            widgetEntryView(entry: SimpleEntry(date: Date(), data: .previewData, error: false))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            widgetEntryView(entry: SimpleEntry(date: Date(), data: .previewData, error: false))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            widgetEntryView(entry: SimpleEntry(date: Date(), data: .previewData, error: false))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }.environment(\.colorScheme, .light)
        //.redacted(reason: .placeholder)
        
    }
}
