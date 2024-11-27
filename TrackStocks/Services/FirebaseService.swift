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
}

struct PortfolioItem: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var name: String?
    var quantity: Double
    var basis: Float
//    var dividend: [String]?
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
    var id = UUID().uuidString
    var symbol = ""
    var date = ""
    var price = ""
}

struct DividendPlaceholder: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var dividend: DividendData
}

struct DividendData: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var values: [String]
}

extension DividendData {
    init(snapshot: Dictionary<String, Any>) {
        let item = snapshot["values"] as? [String] ?? []
        values = item
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
        database.collection("users").document(user.uid).collection("portfolios").document(portfolioId).collection("stocks").whereField("symbol", isNotEqualTo: "").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                debugPrint("🧨", "listenerForStockSymbols: \(error!)")
                return
            }
            
            debugPrint("👨‍🦯‍➡️", "listenerForStockSymbols called")
            
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
                let array = Array(stockSymbols)
                if let index = self.masterSymbolList.firstIndex(where: {$0.portfolioId == portfolioId}) {
                    DispatchQueue.main.async {
                        self.masterSymbolList[index].stockSymbols = array
                        self.masterSymbolList[index].stockItems = stockItems
                        self.masterSymbolList[index].portfolioItems = portfolioItems
                    }
                } else {
                    let value = MasterSymbolList(portfolioName: portfolioName, portfolioId: portfolioId, stockSymbols: array, stockItems: stockItems, portfolioItems: portfolioItems)
                    DispatchQueue.main.async {
                        self.masterSymbolList.append(value)
                        self.masterSymbolList.sort(by: { $0.portfolioName < $1.portfolioName })
                    }
                }
            }
            catch {
                debugPrint("🧨", "Error listenerForStockSymbols: portfolioName: \(portfolioName) \(error.localizedDescription)")
            }
        }

    }
    
    func getPortfolioList(stockList: [StockItem], portfolioName: String, displayStockState: DisplayStockState) async -> [PortfolioItem] {
        
        if let index = self.masterSymbolList.firstIndex(where: {$0.portfolioId == portfolioName}) {
            let portfolioItems = self.masterSymbolList[index].portfolioItems
            for item in portfolioItems {
                debugPrint("🦜", "portfolioItem: \(item.symbol ?? "n/a")")
            }
            return portfolioItems.sorted(by: { $0.symbol ?? "" < $1.symbol ?? "" })
        } else {
            debugPrint("🙅‍♂️", "Stocks for portfolio \(portfolioName) not found")
            return []
        }
/*
        var portfolioItems: [PortfolioItem] = []
        for item in stockList {
            do {
                id = item.id ?? "n/a"
                let querySnapshot = try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").document(id).getDocument()
                
                if querySnapshot.exists {
                    var data = try querySnapshot.data(as: PortfolioItem.self)
                    if displayStockState == .showSoldStocks && data.isSold == nil {
                        continue
                    }
                    if let _ = data.isSold, displayStockState == .showActiveStocks {
                        continue
                    }
                    if let stock = data.symbol {
                        data.symbol = stock
                    } else {
                        data.symbol = data.id ?? "n/a"
                    }
                    let querySnapshot2 = try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").document(id).collection("dividend").document("dividend").getDocument()
                    if querySnapshot2.exists {
                        let data2 = try querySnapshot2.data(as: DividendData.self)
                        data.dividends = data2.values
                    }
                    portfolioItems.append(data)
                }
            }
            catch {
                debugPrint("🧨", "id: \(id) portfolioName: \(portfolioName) Error reading stock items: \(error.localizedDescription)")
            }
        }
        
        return portfolioItems.sorted(by: { $0.symbol ?? "" < $1.symbol ?? "" })
*/
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
    
    func buildDividendArrayElement(dividendDate: String, dividendAmount: String) -> [String] {
        let str = dividendDate + "," + "\(dividendAmount)"
        var array: [String] = []
        array.append(str)
        return array
        
    }
    
    func addDividend(portfolioName: String, firestoreId: String, dividendDate: String, dividendAmount: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let array = buildDividendArrayElement(dividendDate: dividendDate, dividendAmount: dividendAmount)
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
        
        let str = dividendDisplayData.date + ",\(dividendDisplayData.price)"
        var array: [String] = []
        array.append(str)
        do {
            try await database.collection("users").document(user.uid).collection("portfolios").document(portfolioName).collection("stocks").document(firestoreId).updateData(["dividends": FieldValue.arrayRemove(array)])
        } catch {
            debugPrint(String.boom, "deleteDividend failed: \(error)")
        }
        
    }
    
    func updateDividend(portfolioName: String, firestoreId: String, dividendDisplayData: DividendDisplayData, dividendAmount: String, dividendDate: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let str = dividendDisplayData.date + ",\(dividendDisplayData.price)"
        var array: [String] = []
        array.append(str)
        let array2 = buildDividendArrayElement(dividendDate: dividendDate, dividendAmount: dividendAmount)
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
