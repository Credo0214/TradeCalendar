import SwiftUI

struct TradeEditView: View {

    @Environment(\.dismiss) private var dismiss

    let trade: TradeEntity
    let riskPercent: Double
    let onSave: (TradeEntity, String, Double, Double, Date, String?) -> Void
    let onDelete: (TradeEntity) -> Void

    @State private var pair: String = ""
    @State private var balanceBefore: String = ""
    @State private var balanceAfter: String = ""
    @State private var date: Date = Date()
    @State private var memo: String = ""

    @State private var showDeleteConfirm = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case pair, balanceBefore, balanceAfter, memo
    }

    private var beforeValue: Double { Double(balanceBefore) ?? 0 }
    private var afterValue: Double { Double(balanceAfter) ?? 0 }

    private var profitValue: Double {
        RiskCalculator.profit(balanceBefore: beforeValue, balanceAfter: afterValue)
    }

    private var oneR: RiskAmount {
        RiskCalculator.oneR(balance: beforeValue, rate: RiskRate(percent: riskPercent))
    }

    private var twoR: TargetAmount {
        RiskCalculator.nR(balance: beforeValue, rate: RiskRate(percent: riskPercent), multiple: 2)
    }

    private var threeR: TargetAmount {
        RiskCalculator.nR(balance: beforeValue, rate: RiskRate(percent: riskPercent), multiple: 3)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("通貨ペア") {
                    TextField("例：USDJPY", text: $pair)
                        .textInputAutocapitalization(.characters)
                        .focused($focusedField, equals: .pair)
                }

                Section("資金") {
                    TextField("取引開始資金", text: $balanceBefore)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .balanceBefore)

                    TextField("取引終了資金", text: $balanceAfter)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .balanceAfter)

                    HStack {
                        Text("損益（自動）")
                        Spacer()
                        Text(NumberFormatters.yen(profitValue))
                            .foregroundStyle(profitValue >= 0 ? Color("AppBlue") : .red)
                    }

                    HStack {
                        Text("許容損失額（1R）")
                        Spacer()
                        Text(NumberFormatters.yen(oneR.value))
                            .monospacedDigit()
                            .foregroundStyle(.red)
                    }

                    HStack {
                        Text("2R（目標①）")
                        Spacer()
                        Text(NumberFormatters.yen(twoR.value))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("3R（目標②）")
                        Spacer()
                        Text(NumberFormatters.yen(threeR.value))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Section("時間") {
                    DatePicker("取引日", selection: $date, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                }

                Section("メモ") {
                    TextField("任意", text: $memo)
                        .focused($focusedField, equals: .memo)
                }

                Section {
                    Button(role: .destructive) {
                        focusedField = nil
                        showDeleteConfirm = true
                    } label: {
                        Label("このトレードを削除", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("編集")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        focusedField = nil
                        guard !pair.isEmpty,
                              let before = Double(balanceBefore),
                              let after = Double(balanceAfter) else { return }

                        onSave(trade, pair, before, after, date, memo.isEmpty ? nil : memo)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        focusedField = nil
                        dismiss()
                    }
                }
            }
            .onAppear {
                pair = trade.pair ?? ""
                balanceBefore = String(trade.balanceBefore)
                balanceAfter = String(trade.balanceAfter)
                date = trade.date ?? Date()
                memo = trade.memo ?? ""
            }
            .confirmationDialog("本当に削除しますか？", isPresented: $showDeleteConfirm) {
                Button("削除", role: .destructive) {
                    onDelete(trade)
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            }
            .onTapGesture { focusedField = nil }
        }
        .tint(Color("AppBlue"))
    }
}
