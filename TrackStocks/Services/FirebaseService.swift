//
//  FirebaseService.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/5/24.
//

import Combine
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

let database = Firestore.firestore()

struct ItemData: Identifiable, Encodable, Decodable, Hashable {
    var id: String = UUID().uuidString
    var firestoreId: String
    var symbol: String
    var basis: Double
    var price: Double
    var gainLose: Double
    var percent: Double
    var quantity: Double
    var dividend: [String]?
    var isSold: Bool
    var changesPercentage: Float?
    var change: Double?
    var dayLow: Float?
    var dayHigh: Float?
    var yearLow: Float?
    var yearHigh: Float?
    var marketCap: Int?
    var priceAvg50: Float?
    var priceAvg200: Float?
    var exchange: String?
    var volume: Int?
    var avgVolume: Int?
    var open: Float?
    var previousClose: Float?
    var eps: Float?
    var pe: Float?
    var earningsAnnouncement: String?
    var sharesOutstanding: Float?
    var timestamp: Int?
    var purchasedDate: String
    var soldDate: String
    var stockTag: String?
    var dividendList: [DividendDisplayData] = []
    var originalBasis: Double = 0
    var originalQuantity: Double = 0
}

struct StockItem: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var symbol: String?
}

struct Portfolio: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var name: String
}

struct MasterSymbolList: Codable, Identifiable, Hashable {
    var id = UUID().uuidString
    var portfolioName: String
    var portfolioId: String
    var stockSymbols: [String]
    var stockItems: [StockItem]
    var portfolioItems: [PortfolioItem]
    var itemsData: [ItemData] = []
    var stocks: [ItemData] = []
}

struct PortfolioItem: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var name: String?
    var quantity: Double
    var basis: Double
    var symbol: String?
    var isSold: Bool?
    var price: Double?
    var purchasedDate: String
    var soldDate: String
    var stockTag: String?
    var dividends: [String]?
}

struct ModelStock: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var AcceleratedProfits: [String]?
    var BreakthroughStocks: [String]?
    var EliteDividendPayers: [String]?
    var GrowthInvestor: [String]?
    var Buy: [String]?
    var Sell: [String]?
}

struct DividendDisplayData: Codable, Identifiable, Hashable, Equatable {
    var id = ""
    var symbol = ""
    var date = ""
    var price = ""
    var quantity = ""
    
    init(id: String = "", symbol: String = "", date: String = "", price: String = "", quantity: String = "") {
        self.id = id
        self.symbol = symbol
        self.date = date
        self.price = price
        self.quantity = quantity
    }
}

struct FirebaseUserInformation: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var fcm: String?
    var email: String?
    var notifications: [String]?
}

struct StocksNotificationData: Codable, Identifiable, Hashable {
    var id = UUID().uuidString
    var notifications: [String] = []
}

enum NotificationType: String, Codable, CaseIterable, Identifiable, Hashable {
    case price = "Price"
    case volume = "Volume"
    
    var id: Self { self }
    
}

enum NotificationFrequency: String, Codable, CaseIterable, Identifiable, Hashable {
    case once = "Once"
    case repeated = "Repeated"
    
    var id: Self { self }
    
}

enum MarketStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case marketOpen = "Market Open"
    case prepostMarket = "PrePost Market"
    case marketClosed = "Market Closed"
    
    var id: Self { self }
    
}

struct NotificationData: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var symbol: String = ""
    var notificationType: NotificationType = .price
    var notificationFrequency: NotificationFrequency = .once
    var action: NotificationAction = .notSelected
    var amount: Double = 0
    var marketPrice: Double = 0
    var volume: String = ""
    var change: Double = 0
    var marketStatus: String = MarketStatus.marketClosed.rawValue
}

struct ActivityData: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var symbol: String = ""
    var marketPrice: Double = 0
    var change: Double = 0
    var marketStatus: String = MarketStatus.marketClosed.rawValue
}

enum NotificationAction: String, Codable, CaseIterable, Identifiable, Hashable {
    case equalTo = "="
    case lessThan = "<"
    case lessThanOrEqualTo = "<="
    case greaterThan = ">"
    case greaterThanOrEqualTo = ">="
    case notSelected = "Not Selected"
    
    var id: Self { self }
    
}

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    var stockDataService = StockDataService()
    var settingService = SettingsService.shared
    var debugService = DebugService.shared
    @AppStorage("profile-url") var profileURL: String = ""
    @Published var user: FirebaseUserInformation = FirebaseUserInformation()
    @Published var portfolioList: [Portfolio] = []
    @Published var masterSymbolList: [MasterSymbolList] = []
    var fmc: String = ""
    var activityToken: String = ""
    var userListener: ListenerRegistration?
    var portfolioListener: ListenerRegistration?
    let stockNotifications = PassthroughSubject<[String], Never>()
    
    func getUser() {
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        let listener = database.collection("users").document(uid).addSnapshotListener { documentSnapshot, error in

            guard let document = documentSnapshot, let _ = document.data() else {
                print("getUser: Error fetching document: \(uid)")
                return
            }
            do {
                let user = try document.data(as: FirebaseUserInformation.self)
                DispatchQueue.main.async {
                    self.user = user
                    if let notifications = user.notifications {
                        self.stockNotifications.send(notifications)
                    }
                }
            } catch {
                debugPrint("getUser reading data: \(error.localizedDescription)")
            }

        }
        self.userListener = listener
    }
    
    func createUser(token: String) async {
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        let data = ["email": user.email ?? "no email",
                    "id": user.displayName ?? uid,
                    "fcm": token,
                   ]
        do {
            try await database.collection("users").document(uid).updateData(data)
            debugPrint(String.bell, "users updated!")
        } catch {
            do {
                let array: [String] = []
                let data = ["email": user.email ?? "no email",
                            "id": user.displayName ?? uid,
                            "fcm": token,
                            "notifications": array
                           ] as [String : Any]
                try await database.collection("users").document(uid).setData(data)
                debugPrint(String.bell, "users successfully written!")
            } catch {
                debugPrint(String.fatal, "users: Error writing users: \(error)")
                return
            }
        }
    }

    func addPortfolio(portfolioName: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        do {
            try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).setData([
                "name": portfolioName,
            ])
        } catch {
            debugPrint("Error creating addPortfolioCollection name: \(portfolioName) error: \(error)")
        }
    }
    
    func renamePortfolio(portfolioId: String, portfolioName: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        do {
            try await database.collection("users").document(uid).collection("portfolios").document(portfolioId).updateData([
                "name": portfolioName,
            ])
        } catch {
            debugPrint("Error creating addPortfolioCollection name: \(portfolioName) error: \(error)")
        }
    }
    
    @MainActor
    func listenerForPortfolios() async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        let listener = database.collection("users").document(uid).collection("portfolios").whereField("name", isNotEqualTo: "").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                debugPrint("🧨", "Error getPortfolios: \(error!)")
                return
            }
            debugPrint("👩‍🏭", "listenerForPortfolios called")
            var results: [Portfolio] = []
            
            do {
                for document in documents {
                    let data = try document.data(as: Portfolio.self)
                    results.append(data)
                }
                
                DispatchQueue.main.async {
                    self.portfolioList = results
                }
            }
            catch {
                debugPrint("🧨", "Error reading getPortfolios: \(error.localizedDescription)")
            }
        }
        self.portfolioListener = listener

    }
    
    @MainActor
    func listenerForStockSymbols(portfolioId: String, portfolioName: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        database.collection("users").document(uid).collection("portfolios").document(portfolioId).collection("stocks").whereField("symbol", isNotEqualTo: "").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                debugPrint("🧨", "listenerForStockSymbols: \(error!)")
                return
            }
            
            debugPrint("👨‍🦯‍➡️", "listenerForStockSymbols called for \(portfolioName)")
            
            var stockSymbols: Set<String> = []
            var stockItems: [StockItem] = []
            var portfolioItems: [PortfolioItem] = []
            do {
                for document in documents {
                    let data = try document.data(as: PortfolioItem.self)
                    if let symbol = data.symbol {
                        stockSymbols.insert(symbol)
                        let stockItem = StockItem(id: data.id ?? "no id", symbol: data.symbol ?? "no symbol")
                        stockItems.append(stockItem)
                        portfolioItems.append(data)
                    }
                }
            }
            catch {
                debugPrint("🧨", "Error listenerForStockSymbols: portfolioName: \(portfolioName) \(error.localizedDescription)")
                return
            }
            var items: [ItemData] = []
//            var total: Float = 0
//            var totalBasis: Float = 0
//            var totalSold: Float = 0
//            var totalNotSold: Float = 0
            var dividendList: [DividendDisplayData] = []
            
            for item in portfolioItems {
                var value = ""
                if let symbol = item.symbol {
                    value = symbol
                }
                var soldPrice: Double = 0
                var isSold = false
                if let value = item.price {
                    soldPrice = value
                    isSold = true
                }
                let temp = ItemData(firestoreId: item.id ?? "n/a", symbol: value, basis: item.basis, price: soldPrice, gainLose: 0, percent: 0, quantity: item.quantity, dividend: item.dividends, isSold: isSold, purchasedDate: item.purchasedDate, soldDate: item.soldDate, stockTag: item.stockTag ?? "None", originalBasis: item.basis, originalQuantity: item.quantity)
                items.append(temp)
            }
            let array = Array(stockSymbols)
            let string: String = array.joined(separator: ",")
            Task {
                let stockData = await self.stockDataService.fetchFullQuoteStocks(tickers: string)

                for item in stockData {
                    items.indices.forEach { index in
                        if item.id == items[index].symbol {
                            var price = items[index].price
                            if items[index].isSold == false {
                                price = item.price
                                items[index].price = price
                            }
                            let value = price - items[index].basis
                            items[index].percent = value / items[index].basis
                            let gainLose = items[index].quantity * value
                            items[index].gainLose = gainLose
                            dividendList = []
                            if let dividends = items[index].dividend {
                                let _ = dividends.map {
                                    let result = self.buildDividendList(array: $0, symbol: item.id)
                                    dividendList.append(result)
                                }
                            }
                            items[index].dividendList = dividendList
                            items[index].changesPercentage = item.changesPercentage != nil ? item.changesPercentage! / 100 : 0
                            items[index].change = item.change
                            items[index].dayLow = item.dayLow
                            items[index].dayHigh = item.dayHigh
                            items[index].yearLow = item.yearLow
                            items[index].yearHigh = item.yearHigh
                            items[index].marketCap = item.marketCap
                            items[index].priceAvg50 = item.priceAvg50
                            items[index].priceAvg200 = item.priceAvg200
                            items[index].exchange = item.exchange
                            items[index].volume = item.volume
                            items[index].avgVolume = item.avgVolume
                            items[index].open = item.open
                            items[index].previousClose = item.previousClose
                            items[index].eps = item.eps
                            items[index].pe = item.pe
                            items[index].earningsAnnouncement = item.earningsAnnouncement
                            items[index].sharesOutstanding = item.sharesOutstanding
                            items[index].timestamp = item.timestamp
                        }
                    }
                }
                if let index = self.masterSymbolList.firstIndex(where: {$0.portfolioId == portfolioId}) {
                    DispatchQueue.main.async {
                        self.masterSymbolList[index].stockSymbols = array
                        self.masterSymbolList[index].stockItems = stockItems
                        self.masterSymbolList[index].portfolioItems = portfolioItems
                        self.masterSymbolList[index].itemsData = items
                    }
                } else {
                    let value = MasterSymbolList(portfolioName: portfolioName, portfolioId: portfolioId, stockSymbols: array, stockItems: stockItems, portfolioItems: portfolioItems, itemsData: items)
                    DispatchQueue.main.async {
                        self.masterSymbolList.append(value)
                        self.masterSymbolList.sort(by: { $0.portfolioName < $1.portfolioName })
                    }
                }
            }
        }

    }
    
    func refreshPortfolio(portfolioName: String) async -> ([ItemData], Double, Double, Double, Double) {
        if let masterSymbol = masterSymbolList.filter({ $0.portfolioName == portfolioName }).first {
            
            var items = masterSymbol.itemsData
            let list = masterSymbol.stockSymbols
//            Task {
                let string: String = list.joined(separator: ",")
                var stockData: [StockData] = []
                stockData = await stockDataService.fetchFullQuoteStocks(tickers: string)
                for item in stockData {
                    items.indices.forEach { index in
                        if item.id == items[index].symbol {
                            debugPrint("🏓", "symbol: \(item.id) price: \(item.price)")
                            var price = items[index].price
                            for dividend in items[index].dividendList {
                                let dec = (dividend.price as NSString).doubleValue
                                if dec > 0 {
                                    let dividendQuantity = (dividend.quantity as NSString).doubleValue
                                    if dividendQuantity > 0 {
                                        let a = items[index].quantity * items[index].basis
                                        let b = dividendQuantity * dec
                                        let d = dividendQuantity + items[index].quantity
                                        if d > 0 {
                                            let c = (a + b) / d
                                            items[index].quantity = d
                                            items[index].basis = c
                                        }
                                    }
                                }
                            }
                            if items[index].isSold == false {
                                price = item.price
                                items[index].price = price
                            }
                            let value = price - items[index].basis
                            items[index].percent = (value / items[index].basis) * 100
                            let gainLose = items[index].quantity * value
                            items[index].gainLose = gainLose
                            items[index].changesPercentage = item.changesPercentage != nil ? item.changesPercentage! / 100 : 0
                            items[index].change = item.change
                            items[index].dayLow = item.dayLow
                            items[index].dayHigh = item.dayHigh
                            items[index].yearLow = item.yearLow
                            items[index].yearHigh = item.yearHigh
                            items[index].marketCap = item.marketCap
                            items[index].priceAvg50 = item.priceAvg50
                            items[index].priceAvg200 = item.priceAvg200
                            items[index].exchange = item.exchange
                            items[index].volume = item.volume
                            items[index].avgVolume = item.avgVolume
                            items[index].open = item.open
                            items[index].previousClose = item.previousClose
                            items[index].eps = item.eps
                            items[index].pe = item.pe
                            items[index].earningsAnnouncement = item.earningsAnnouncement
                            items[index].sharesOutstanding = item.sharesOutstanding
                            items[index].timestamp = item.timestamp
                        }
                    }
                }
                let results = await computeTotals(itemsData: items)
                return (results.0, results.1, results.2, results.3, results.4)
//            }
        } else {
            return ([], 0, 0 ,0, 0)
        }
    }
    
    func computeTotals(itemsData: [ItemData]) async -> ([ItemData], Double, Double, Double, Double) {
        var result: [ItemData] = []
        let displayStockState = settingService.displayStocks
        var total: Double = 0
        var totalBasis: Double = 0
        var totalSold: Double = 0
        var totalNotSold: Double = 0

        for item in itemsData {
            if displayStockState == .showSoldStocks && item.isSold == false {
                continue
            }
            if item.isSold == true, displayStockState == .showActiveStocks {
                continue
            }

            let gainLose = item.gainLose
            total += gainLose
            if item.isSold == true {
                totalSold += gainLose
            } else {
                totalNotSold += gainLose
            }
            totalBasis += item.basis * item.quantity
            result.append(item)
        }
        
        return (result, total, totalBasis, totalSold, totalNotSold)
        
    }
    
    func getPortfolioList(stockList: [StockItem], portfolioName: String, displayStockState: DisplayStockState) async -> [PortfolioItem] {
        
        if let index = self.masterSymbolList.firstIndex(where: {$0.portfolioId == portfolioName}) {
            let portfolioItems = self.masterSymbolList[index].portfolioItems
            var results: [PortfolioItem] = []
            for item in portfolioItems {
                if displayStockState == .showSoldStocks && item.isSold == nil {
                    continue
                }
                if let _ = item.isSold, displayStockState == .showActiveStocks {
                    continue
                }
                debugPrint("🦜", "portfolioItem: \(item.symbol ?? "n/a")")
                results.append(item)
            }
            return results.sorted(by: { $0.symbol ?? "" < $1.symbol ?? "" })
        } else {
            debugPrint("🙅‍♂️", "Stocks for portfolio \(portfolioName) not found")
            return []
        }
        
    }
    
    func moveStockToPortfolio(oldPortfolio: Portfolio, newPortfolioName: String, stock: ItemData) async {

        guard let user = Auth.auth().currentUser else {
            return
        }
            
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
            
        var value = [
            "symbol": stock.symbol,
            "quantity": stock.originalQuantity,
            "basis": stock.originalBasis,
            "purchasedDate": stock.purchasedDate,
            "soldDate": stock.soldDate,
            "stockTag": stock.stockTag ?? "None",
            "dividends": stock.dividend ?? [],
        ] as [String : Any]
        
        if stock.isSold == true {
            value["isSold"] = true
            value["price"] = stock.price
        }

        do {
            try await database.collection("users").document(uid).collection("portfolios").document(newPortfolioName).collection("stocks").document(stock.firestoreId).setData(value)
        } catch {
            debugPrint(String.boom, "addItem: \(error)")
        }
            
    }
    
    func getStockList(portfolioName: String) async -> ([String], [StockItem]) {
        
        if let item = masterSymbolList.filter({ $0.portfolioId == portfolioName }).first {
            return (item.stockSymbols, item.stockItems)
        }
        
        return ([], [])

    }
    
    func buildDividendArrayElement(id: String = UUID().uuidString, dividendDate: String, dividendAmount: String, dividendQuantity: String) -> [String] {
        var str = id + "," + dividendDate + "," + dividendAmount
        if dividendQuantity.isNotEmpty {
            str += "," + dividendQuantity
        }
        var array: [String] = []
        array.append(str)
        return array
        
    }
    
    func buildDividendList(array: String, symbol: String) -> DividendDisplayData {
        var data = DividendDisplayData(id: "", date: "", price: "", quantity: "")
        let value = array.split(separator: ",")
        if value.count == 3 {
            data = DividendDisplayData(id: String(value[0]), symbol: symbol, date: String(value[1]), price: String(value[2]))
        }
        if value.count == 4 {
            data = DividendDisplayData(id: String(value[0]), symbol: symbol, date: String(value[1]), price: String(value[2]), quantity: String(value[3]))
        }

        return data
    }
    
    func addCashDividend(portfolioName: String, firestoreId: String, dividendDate: String, dividendAmount: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        let array = buildDividendArrayElement(dividendDate: dividendDate, dividendAmount: dividendAmount, dividendQuantity: "")
        do {
            try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(["dividends": FieldValue.arrayUnion(array)])
        } catch {
            do {
                try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).setData(["dividends": FieldValue.arrayUnion(array)])
            } catch {
                debugPrint(String.boom, "addDividend failed: \(error)")
            }
        }
        
    }
    
    func addSharesDividend(portfolioName: String, firestoreId: String, dividendDate: String, dividendAmount: String, numberOfShares: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        let array = buildDividendArrayElement(dividendDate: dividendDate, dividendAmount: dividendAmount, dividendQuantity: numberOfShares)
        do {
            try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(["dividends": FieldValue.arrayUnion(array)])
        } catch {
            do {
                try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).setData(["dividends": FieldValue.arrayUnion(array)])
            } catch {
                debugPrint(String.boom, "addDividend failed: \(error)")
            }
        }
        
    }
    
    func deleteDividend(portfolioName: String, firestoreId: String, dividendDisplayData: DividendDisplayData) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        var str = dividendDisplayData.id + "," + dividendDisplayData.date + ",\(dividendDisplayData.price)"
        if dividendDisplayData.quantity.isNotEmpty {
            str += ",\(dividendDisplayData.quantity)"
        }
        var array: [String] = []
        array.append(str)
        do {
            try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(["dividends": FieldValue.arrayRemove(array)])
        } catch {
            debugPrint(String.boom, "deleteDividend failed: \(error)")
        }
        
    }
    
    func updateDividend(portfolioName: String, firestoreId: String, dividendDisplayData: DividendDisplayData, dividendAmount: String, dividendDate: String, numberOfShares: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        var str = dividendDisplayData.id + "," + dividendDisplayData.date + ",\(dividendDisplayData.price)"
        if dividendDisplayData.quantity.isNotEmpty {
            str += ",\(dividendDisplayData.quantity)"
        }
        var array: [String] = []
        array.append(str)
        let array2 = buildDividendArrayElement(id: dividendDisplayData.id, dividendDate: dividendDate, dividendAmount: dividendAmount, dividendQuantity: numberOfShares)
        
        do {
            try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(["dividends": FieldValue.arrayRemove(array)])
            try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(["dividends": FieldValue.arrayUnion(array2)])
            
        } catch {
            debugPrint(String.boom, "updateDividend failed: \(error)")
        }
        
    }
    
    func addItem(portfolioName: String, symbol: String, quantity: Double, basis: Double, purchasedDate: String, soldDate: String, stockTag: String = "None") async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        let value = [
            "symbol": symbol,
            "quantity": quantity,
            "basis": basis,
            "purchasedDate": purchasedDate,
            "soldDate": soldDate,
            "stockTag": stockTag,
        ] as [String : Any]
        
        do {
            try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").addDocument(data: value)
        } catch {
            debugPrint(String.boom, "addItem: \(error)")
        }
        
    }
    
    func updateItem(firestoreId: String, portfolioName: String, quantity: Decimal, basis: Decimal, date: String, stockTag: String = "None") async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        let value = [
            "quantity": quantity,
            "basis": basis,
            "purchasedDate": date,
            "stockTag": stockTag,
        ] as [String : Any]
        do {
            try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(value)
        } catch {
                debugPrint(String.boom, "updateItem for portfolio \(portfolioName) document \(firestoreId) failed: \(error)")
        }
        
    }
    
    func updateSoldItem(firestoreId: String, portfolioName: String, quantity: Double, documentId: String) async {
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        let value = [
            "isSold": false,
            "quantity": quantity,
            "soldIds": FieldValue.arrayUnion([documentId])
        ] as [String : Any]
        do {
            try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(value)
        } catch {
                debugPrint(String.boom, "soldItem for portfolio \(portfolioName) document \(firestoreId) failed: \(error)")
        }

        
    }
    
    func addSoldItem(portfolioName: String, symbol: String, quantity: Double, basis: Double, purchasedDate: String, soldDate: String, stockTag: String = "None", price: Decimal) async -> String {
        guard let user = Auth.auth().currentUser else {
            return ""
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        let value = [
            "symbol": symbol,
            "quantity": quantity,
            "basis": basis,
            "purchasedDate": purchasedDate,
            "soldDate": soldDate,
            "stockTag": stockTag,
            "isSold": true,
            "price": price,
        ] as [String : Any]
        
        do {
            let ref = try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").addDocument(data: value)
            debugPrint("🐸", "Document added with ID: \(ref.documentID)")
            return ref.documentID
        } catch {
            debugPrint(String.boom, "addItem: \(error)")
        }
        return ""
    }
    
    
    func soldItem(firestoreId: String, portfolioName: String, date: String, price: Decimal) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        let value = [
            "soldDate": date,
            "price": price,
            "isSold": true
        ] as [String : Any]
        do {
            try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(value)
        } catch {
                debugPrint(String.boom, "soldItem for portfolio \(portfolioName) document \(firestoreId) failed: \(error)")
        }
    }
    
    func deletePortfolio(portfolioName: String) async  {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        do {
            let querySnapshot = try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").getDocuments()
            for document in querySnapshot.documents {
                let item = try document.data(as: StockItem.self)
                if let id = item.id {
                    try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").document(id).delete()
                }
            }
            try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).delete()
        } catch {
            debugPrint(String.boom, "deletePortfolio for portfolio: \(portfolioName) \(error)")
        }
        
    }
    
    func deletePortfolioStock(portfolioName: String, stockId: String) async  {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        do {
            try await database.collection("users").document(uid).collection("portfolios").document(portfolioName).collection("stocks").document(stockId).delete()
        } catch {
            debugPrint(String.boom, "deletePortfolioStock for portfolio: \(portfolioName) sockid: \(stockId) error: \(error)")
        }
        
    }
    
    func getStocksNotification() async -> [NotificationData] {
        guard let user = Auth.auth().currentUser else { return [] }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        do {
            let data = try await database.collection("users").document(uid).getDocument(as: StocksNotificationData.self)
            var notificationData: [NotificationData] = []
            for item in data.notifications {
                let value = item.split(separator: ",")
                if value.count == 9 {
                    let symbol = String(value[0])
                    let notificationType = getNotificationTypeFromString(action: String(value[1]))
                    let notificationFrequency = getNotificationFrequencyFromString(action: String(value[2]))
                    let action = getNotificationActionFromString(action: String(value[3]))
                    let amount = Double(value[4]) ?? 0
                    let marketPrice = Double(value[5]) ?? 0
                    let volume = String(value[6])
                    let change = Double(value[7]) ?? 0
                    let result = NotificationData(symbol: symbol, notificationType: notificationType, notificationFrequency: notificationFrequency, action: action, amount: amount, marketPrice: marketPrice, volume: volume, change: change)
                    notificationData.append(result)
                }
                
            }
            notificationData.sort( by: {$0.symbol < $1.symbol} )
            return notificationData
        } catch {
            debugPrint("Error getStocksNotification: \(error)")
        }
        
        return []
    }
    
    func addStocksNotification(symbol: String, notificationType: NotificationType, notificationFrequency: NotificationFrequency, action: NotificationAction, amount: Double) async {
        guard let user = Auth.auth().currentUser else { return }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        let string = symbol + "," + notificationType.rawValue + "," + notificationFrequency.rawValue + "," + action.rawValue + "," + String(amount) + "," + "0.0" + "," + "0" + "," + "0.0" + "," + "Market Closed"

        do {
            try await database.collection("users").document(uid).updateData(["notifications": FieldValue.arrayUnion([string])])
        } catch {
            debugPrint(String.bell, "Error addStocksNotification: \(error)")
            return
        }
    }
    
    func updateStocksNotification(oldNotificationData: NotificationData, newNotificationData: NotificationData) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        let string = oldNotificationData.symbol + "," + oldNotificationData.notificationType.rawValue + "," + oldNotificationData.notificationFrequency.rawValue + "," + oldNotificationData.action.rawValue + "," + String(oldNotificationData.amount) + "," + String(oldNotificationData.marketPrice) + "," + oldNotificationData.volume + "," + String(oldNotificationData.change)
        let string2 = newNotificationData.symbol + "," + oldNotificationData.notificationType.rawValue + "," + oldNotificationData.notificationFrequency.rawValue + ","  + newNotificationData.action.rawValue + "," + String(newNotificationData.amount) + "," + String(newNotificationData.marketPrice) + "," + newNotificationData.volume + "," + String(newNotificationData.change)
        
        do {
            try await database.collection("users").document(uid).updateData(["notifications": FieldValue.arrayRemove([string])])
            try await database.collection("users").document(uid).updateData(["notifications": FieldValue.arrayUnion([string2])])
            
        } catch {
            debugPrint(String.boom, "Error updateStocksNotification: \(error)")
        }
        
    }
    
    func deleteStockNotification(item: NotificationData) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var uid = user.uid
        if debugService.isDebugEnabled {
            uid = debugService.uid
        }
        
        let string = item.symbol + "," + item.notificationType.rawValue + "," + item.notificationFrequency.rawValue + ","  + item.action.rawValue + "," + String(item.amount) + "," + String(item.marketPrice) + "," + item.volume + "," + String(item.change) + "," + item.marketStatus
        var array: [String] = []
        array.append(string)
        do {
            try await database.collection("users").document(uid).updateData(["notifications": FieldValue.arrayRemove(array)])
        } catch {
            debugPrint(String.boom, "deleteStockNotification failed: \(error)")
        }
        
    }
    
    func convertToNotificationData(data: [String]?) -> [NotificationData] {
        var notificationData: [NotificationData] = []
        if let data = data {
            for item in data {
                let value = item.split(separator: ",")
                if value.count == 9 {
                    let symbol = String(value[0])
                    let notificationType = getNotificationTypeFromString(action: String(value[1]))
                    let notificationFrequency = getNotificationFrequencyFromString(action: String(value[2]))
                    let action = getNotificationActionFromString(action: String(value[3]))
                    let amount = Double(value[4]) ?? 0
                    let marketPrice = Double(value[5]) ?? 0
                    let volume = String(value[6])
                    let change = Double(value[7]) ?? 0
                    let marketStatus = String(value[8])
                    let result = NotificationData(symbol: symbol, notificationType: notificationType, notificationFrequency: notificationFrequency, action: action, amount: amount, marketPrice: marketPrice, volume: volume, change: change, marketStatus: marketStatus)
                    notificationData.append(result)
                }
            }
            notificationData.sort { $0.symbol < $1.symbol }
        }
        return notificationData
        
    }
    
    func convertToActivityData(data: [String]?) -> [ActivityData] {
        var activityData: [ActivityData] = []
        if let data = data {
            for item in data {
                let value = item.split(separator: ",")
                if value.count == 8 {
                    let symbol = String(value[0])
                    let marketPrice = Double(value[5]) ?? 0
                    let change = Double(value[7]) ?? 0
                    let result = ActivityData(symbol: symbol, marketPrice: marketPrice, change: change, marketStatus: MarketStatus.marketClosed.rawValue)
                    activityData.append(result)
                }
            }
            activityData.sort { $0.symbol < $1.symbol }
        }
        return activityData
        
    }
    
    func updateAddFCM(token: String) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        self.fmc = token
        
        let values = [
                        "fcm" : token,
                     ]
        do {
            try await database.collection("users").document(currentUid).updateData(values)
        } catch {
            debugPrint("🧨", "updateAddFCMToUser: \(error)")
        }
        
    }

    func updateAddActivity(token: String) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        self.activityToken = token
        let docRef = database.collection("users").document(currentUid)

        do {
            try await docRef.updateData(["activityToken" : token])
        } catch {
            debugPrint("🧨", "updateAddactivityTokenToUser: \(error)")
        }
        
    }
    
    
    func updateAddUserProfileImage(url: String) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let value = [
            "profileImage" : url
        ]
        do {
            try await database.collection("users").document(currentUid).updateData(value)
        } catch {
            debugPrint(String.boom, "updateAddUserProfileImage: \(error)")
        }
        
    }
    
    func callFirebaseCallableFunction(data: String) {
        lazy var functions = Functions.functions()
        
        functions.httpsCallable("test").call(["body": data]) { result, error in
            if let error = error {
                debugPrint("🧨", "error: \(error.localizedDescription)")
                return
            }
            if let data = result?.data {
                debugPrint("😀", "result: \(data)")
            }
            
        }
    }
        
}
