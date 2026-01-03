import SwiftUI

struct LotCalculatorView: View {

    @ObservedObject var viewModel: LotCalculatorViewModel
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("入力")) {
                    TextField("資金", value: $viewModel.capital, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($focused)

                    TextField("損切り幅（pips）", value: $viewModel.stopLossPips, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($focused)
                }

                Section(header: Text("結果")) {
                    HStack {
                        Text("許容損失額")
                        Spacer()
                        Text("\(viewModel.allowableLoss, specifier: "%.2f")")
                    }

                    HStack {
                        Text("適正ロット")
                        Spacer()
                        Text("\(viewModel.lotSize, specifier: "%.2f")")
                    }
                }
            }
            .navigationTitle("適正ロット計算")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        focused = false
                    }
                }
            }
        }
    }
}

