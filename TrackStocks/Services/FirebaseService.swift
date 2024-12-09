//
//  FirebaseService.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/5/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

let database = Firestore.firestore()

struct ItemData: Identifiable, Encodable, Decodable, Hashable {
    var id: String = UUID().uuidString
    var firestoreId: String
    var symbol: String
    var basis: Float
    var price: Float
    var gainLose: Float
    var percent: Float
    var quantity: Double
    var dividend: [String]?
    var isSold: Bool
    var changesPercentage: Float?
    var change: Float?
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
    var basis: Float
    var symbol: String?
    var isSold: Bool?
    var price: Float?
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
    var displayName: String?
    var email: String?
    var subscription: Bool?
}

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    var stockDataService = StockDataService()
    var settingService = SettingsService.shared
    @AppStorage("profile-url") var profileURL: String = ""
    @Published var user: FirebaseUserInformation = FirebaseUserInformation(id: "", displayName: "", email: "", subscription: false)
    @Published var portfolioList: [Portfolio] = []
    @Published var masterSymbolList: [MasterSymbolList] = []
    var fmc: String = ""
    var userListener: ListenerRegistration?
    var portfolioListener: ListenerRegistration?
    
    func getUser() {
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let listener = database.collection("users").document(user.uid).addSnapshotListener { documentSnapshot, error in

            guard let document = documentSnapshot, let _ = document.data() else {
                print("getUser: Error fetching document: \(user.uid)")
                return
            }
            do {
                let user = try document.data(as: FirebaseUserInformation.self)
                DispatchQueue.main.async {
                    self.user = user
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
        
        let data = ["email": user.email ?? "no email",
                "id": user.displayName ?? user.uid,
                "fcm": token
               ]
        do {
            try await database.collection("users").document(user.uid).setData(data)
            debugPrint(String.bell, "users successfully written!")
        } catch {
            debugPrint(String.fatal, "users: Error writing users: \(error)")
            return
        }
    }
    
    func addPortfolio(portfolioName: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        do {
            try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).setData([
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
        
        do {
            try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioId).updateData([
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
        
        let listener = database.collection("users").document(user.uid).collection("portfolios").whereField("name", isNotEqualTo: "").addSnapshotListener { querySnapshot, error in
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
        
//        var displayStockState = settingService.displayStocks
        database.collection("users").document(user.uid).collection("portfolios").document(portfolioId).collection("stocks").whereField("symbol", isNotEqualTo: "").addSnapshotListener { querySnapshot, error in
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
                var soldPrice:Float = 0.0
                var isSold = false
                if let value = item.price {
                    soldPrice = value
                    isSold = true
                }
                let temp = ItemData(firestoreId: item.id ?? "n/a", symbol: value, basis: item.basis, price: soldPrice, gainLose: 0, percent: 0, quantity: item.quantity, dividend: item.dividends, isSold: isSold, purchasedDate: item.purchasedDate, soldDate: item.soldDate, stockTag: item.stockTag ?? "None")
                items.append(temp)
            }
            let array = Array(stockSymbols)
            let string: String = array.joined(separator: ",")
            Task {
                let stockData = await self.stockDataService.fetchFullQuoteStocks(tickers: string)

                for item in stockData {
                    items.indices.forEach { index in
                        if item.id == items[index].symbol {
                            var price: Float = items[index].price
                            if items[index].isSold == false {
                                price = Float(Double(item.price))
                                items[index].price = price
                            }
                            let value = price - items[index].basis
                            items[index].percent = value / items[index].basis
                            let gainLose = Float(items[index].quantity) * value
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
    
    func getStockList(portfolioName: String) async -> ([String], [StockItem]) {
        
        if let item = masterSymbolList.filter({ $0.portfolioId == portfolioName }).first {
            return (item.stockSymbols, item.stockItems)
        }
        
        return ([], [])

    }

    func addItem(portfolioName: String, symbol: String, quantity: Double, basis: Double, purchasedDate: String, soldDate: String, stockTag: String = "None") async {
        guard let user = Auth.auth().currentUser else {
            return
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
            try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").addDocument(data: value)
        } catch {
            debugPrint(String.boom, "addItem: \(error)")
        }
        
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
        
        let array = buildDividendArrayElement(dividendDate: dividendDate, dividendAmount: dividendAmount, dividendQuantity: "")
        do {
            try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(["dividends": FieldValue.arrayUnion(array)])
        } catch {
            do {
                try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).setData(["dividends": FieldValue.arrayUnion(array)])
            } catch {
                debugPrint(String.boom, "addDividend failed: \(error)")
            }
        }
        
    }
    
    func addSharesDividend(portfolioName: String, firestoreId: String, dividendDate: String, dividendAmount: String, numberOfShares: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let array = buildDividendArrayElement(dividendDate: dividendDate, dividendAmount: dividendAmount, dividendQuantity: numberOfShares)
        do {
            try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(["dividends": FieldValue.arrayUnion(array)])
        } catch {
            do {
                try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).setData(["dividends": FieldValue.arrayUnion(array)])
            } catch {
                debugPrint(String.boom, "addDividend failed: \(error)")
            }
        }
        
    }
    
    func deleteDividend(portfolioName: String, firestoreId: String, dividendDisplayData: DividendDisplayData) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var str = dividendDisplayData.id + "," + dividendDisplayData.date + ",\(dividendDisplayData.price)"
        if dividendDisplayData.quantity.isNotEmpty {
            str += ",\(dividendDisplayData.quantity)"
        }
        var array: [String] = []
        array.append(str)
        do {
            try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(["dividends": FieldValue.arrayRemove(array)])
        } catch {
            debugPrint(String.boom, "deleteDividend failed: \(error)")
        }
        
    }
    
    func updateDividend(portfolioName: String, firestoreId: String, dividendDisplayData: DividendDisplayData, dividendAmount: String, dividendDate: String, numberOfShares: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var str = dividendDisplayData.id + "," + dividendDisplayData.date + ",\(dividendDisplayData.price)"
        if numberOfShares.isNotEmpty {
            str += ",\(numberOfShares)"
        }
        var array: [String] = []
        array.append(str)
        let array2 = buildDividendArrayElement(id: dividendDisplayData.id, dividendDate: dividendDate, dividendAmount: dividendAmount, dividendQuantity: numberOfShares)
        
        do {
            try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(["dividends": FieldValue.arrayRemove(array)])
            try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(["dividends": FieldValue.arrayUnion(array2)])
            
        } catch {
            debugPrint(String.boom, "updateDividend failed: \(error)")
        }
        
    }
    
    func updateItem(firestoreId: String, portfolioName: String, quantity: Decimal, basis: Decimal, date: String, stockTag: String = "None") async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let value = [
            "quantity": quantity,
            "basis": basis,
            "purchasedDate": date,
            "stockTag": stockTag,
        ] as [String : Any]
        do {
            try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(value)
        } catch {
                debugPrint(String.boom, "updateItem for portfolio \(portfolioName) document \(firestoreId) failed: \(error)")
        }
        
    }
    
    func soldItem(firestoreId: String, portfolioName: String, date: String, price: Decimal) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let value = [
            "soldDate": date,
            "price": price,
            "isSold": true
        ] as [String : Any]
        do {
            try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(value)
        } catch {
                debugPrint(String.boom, "soldItem for portfolio \(portfolioName) document \(firestoreId) failed: \(error)")
        }
    }
    
    func deletePortfolio(portfolioName: String) async  {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        do {
            let querySnapshot = try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").getDocuments()
            for document in querySnapshot.documents {
                let item = try document.data(as: StockItem.self)
                if let id = item.id {
                    try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").document(id).delete()
                }
            }
            try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).delete()
        } catch {
            debugPrint(String.boom, "deletePortfolio for portfolio: \(portfolioName) \(error)")
        }
        
    }
    
    func deletePortfolioStock(portfolioName: String, stockId: String) async  {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        do {
            try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").document(stockId).delete()
        } catch {
            debugPrint(String.boom, "deletePortfolioStock for portfolio: \(portfolioName) sockid: \(stockId) error: \(error)")
        }
        
    }

    func updateAddFCMToUser(token: String) async {
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
        
}
