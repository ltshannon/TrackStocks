//
//  StockDateSelectorView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/8/24.
//

import SwiftUI

struct StockDateSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: String
    @State var date: Date = Date()
    @State var showingNotSelectedAlert = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section {
                        Section {
                            DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .frame(maxHeight: 200)
                        } header: {
                            Text("Date")
                        }
                        .onChange(of: date) {
                            setDate(date: date)
                            dismiss()
                        }
                    }
                    Section {
                        TextField("Date", text: $selectedDate)
                            .keyboardType(.default)
                    } header: {
                        Text("Date")
                    }
                }
                .navigationTitle("Select Date")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                        }
                    }
                }
            }
        }
        .onAppear {
            setDate(date: Date())
        }
    }

    func setDate(date: Date) {
        let formatter1 = DateFormatter()
        formatter1.dateStyle = .short
        selectedDate = formatter1.string(from: date)
    }
}
