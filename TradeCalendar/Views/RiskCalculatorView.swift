import SwiftUI

struct RiskCalculatorView: View {

    @StateObject private var vm = RiskCalculatorViewModel()
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case balance
        case risk
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("入力") {
                    TextField("資金", text: $vm.balanceText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .balance)

                    TextField("リスク率（%）", text: $vm.riskPercentText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .risk)
                }

                Section("出力") {
                    row(title: "許容損失額（1R）", value: vm.oneRText, isRisk: true)
                    row(title: "2R（目標①）", value: vm.twoRText, isRisk: false)
                    row(title: "3R（目標②）", value: vm.threeRText, isRisk: false)
                }
            }
            .navigationTitle("リスク計算")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .onAppear {
                // 設定のリスク率を初期値として反映（表示だけ）
                // ※ ユーザーが入力していたら上書きしない
                if vm.riskPercentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    vm.riskPercentText = formatRiskRate(settingsStore.riskRate)
                }
            }
        }
        .tint(Color("AppBlue"))
    }

    private func row(title: String, value: String, isRisk: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            if value.isEmpty {
                Text("—").foregroundStyle(.secondary)
            } else {
                Text(value)
                    .monospacedDigit()
                    .foregroundStyle(isRisk ? .red : .secondary)
            }
        }
    }

    private func formatRiskRate(_ value: Double) -> String {
        if value.rounded() == value { return String(Int(value)) }
        return String(value)
    }
}
