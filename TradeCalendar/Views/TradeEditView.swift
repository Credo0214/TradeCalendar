import SwiftUI

struct TradeEditView: View {

    @Environment(\.dismiss) private var dismiss

    let trade: TradeEntity
    let onSave: (TradeEntity, String, Double, Double, Date, String?) -> Void
    let onDelete: (TradeEntity) -> Void

    @State private var pair: String = ""
    @State private var balanceBefore: String = ""
    @State private var balanceAfter: String = ""
    @State private var date: Date = Date()
    @State private var memo: String = ""

    @State private var showDeleteConfirm = false

    private var profit: Double {
        (Double(balanceAfter) ?? 0) - (Double(balanceBefore) ?? 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("通貨ペア") {
                    TextField("例：USDJPY", text: $pair)
                        .textInputAutocapitalization(.characters)
                }

                Section("資金") {
                    TextField("取引開始資金", text: $balanceBefore)
                        .keyboardType(.decimalPad)

                    TextField("取引終了資金", text: $balanceAfter)
                        .keyboardType(.decimalPad)

                    HStack {
                        Text("損益（自動）")
                        Spacer()
                        Text(NumberFormatters.yen(profit))
                            .foregroundStyle(profit >= 0 ? .green : .red)
                    }
                }

                Section("時間") {
                    DatePicker("取引日時", selection: $date)
                }

                Section("メモ") {
                    TextField("任意", text: $memo)
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("このトレードを削除", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("編集")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard
                            !pair.isEmpty,
                            let before = Double(balanceBefore),
                            let after = Double(balanceAfter)
                        else { return }

                        onSave(trade, pair, before, after, date, memo.isEmpty ? nil : memo)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .onAppear {
                pair = trade.pair ?? ""
                balanceBefore = String(trade.balanceBefore)
                balanceAfter = String(trade.balanceAfter)
                date = trade.date ?? Date()
                memo = trade.memo ?? ""
            }
            .confirmationDialog(
                "本当に削除しますか？",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    onDelete(trade)
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }
}

