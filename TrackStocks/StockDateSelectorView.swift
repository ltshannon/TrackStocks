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
        VStack {
            Form {
                Section {
                    Section {
                        DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .frame(maxHeight: 200)
                    } header: {
                        Text("Select a date")
                    }
                    .onChange(of: date) {
                        setDate(date: date)
                    }
                }
                Section {
                    TextField("Date", text: $selectedDate)
                        .keyboardType(.default)
                } header: {
                    Text("Date")
                }
            }
        }
        Button {
            if selectedDate.isEmpty {
                showingNotSelectedAlert = true
                return
            }
            dismiss()
        } label: {
            Text("Done")
        }
        .buttonStyle(.borderedProminent)
        Button {
            dismiss()
        } label: {
            Text("Cancel")
        }
        .buttonStyle(.borderedProminent)
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
