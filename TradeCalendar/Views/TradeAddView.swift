import SwiftUI

struct TradeAddView: View {

    @Environment(\.dismiss) private var dismiss

    let initialBalanceBefore: Double
    let riskPercent: Double
    let onSave: (String, Double, Double, Date, String?) -> Void

    @State private var pair: String = ""
    @State private var balanceBefore: String = ""
    @State private var balanceAfter: String = ""
    @State private var date: Date = Date()
    @State private var memo: String = ""

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case pair, balanceBefore, balanceAfter, memo
    }

    private var profit: Double {
        (Double(balanceAfter) ?? 0) - (Double(balanceBefore) ?? 0)
    }

    private var allowedLoss: Double {
        let balance = Double(balanceBefore) ?? 0
        return balance * (riskPercent / 100.0)
    }

    private var profit2R: Double { allowedLoss * 2 }
    private var profit3R: Double { allowedLoss * 3 }

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
                        Text(NumberFormatters.yen(profit))
                            .foregroundStyle(profit >= 0 ? Color("AppBlue") : .red)
                    }

                    HStack {
                        Text("許容損失額（1R）")
                        Spacer()
                        Text(NumberFormatters.yen(allowedLoss))
                            .monospacedDigit()
                            .foregroundStyle(.red)
                    }

                    HStack {
                        Text("2R（目標①）")
                        Spacer()
                        Text(NumberFormatters.yen(profit2R))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("3R（目標②）")
                        Spacer()
                        Text(NumberFormatters.yen(profit3R))
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
            }
            .navigationTitle("新規トレード")
            .onAppear {
                balanceBefore = initialBalanceBefore > 0 ? String(Int(initialBalanceBefore)) : ""
            }
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

                        onSave(pair, before, after, date, memo.isEmpty ? nil : memo)
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
            .onTapGesture { focusedField = nil }
        }
        .tint(Color("AppBlue"))
    }
}
