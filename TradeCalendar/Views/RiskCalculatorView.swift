import SwiftUI

struct RiskCalculatorView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel = RiskCalculatorViewModel()

    private enum Field { case balance, risk }
    @FocusState private var focused: Field?

    var body: some View {
        Form {
            Section("入力") {
                TextField("資金（JPY）", text: $viewModel.balanceText)
                    .keyboardType(.decimalPad)
                    .focused($focused, equals: .balance)

                TextField("リスク（%）", text: $viewModel.riskPercentText)
                    .keyboardType(.decimalPad)
                    .focused($focused, equals: .risk)

                if let msg = viewModel.validationMessage {
                    Text(msg).foregroundStyle(.secondary)
                }
            }

            Section("結果") {
                HStack {
                    Text("許容損失額")
                    Spacer()
                    Text(viewModel.allowedLossText)
                        .monospacedDigit()
                }
            }
        }
        .navigationTitle("リスク計算")
        .task { viewModel.loadDefaults(context: context) }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") { focused = nil }
            }
        }
        .onTapGesture { focused = nil }
    }
}

