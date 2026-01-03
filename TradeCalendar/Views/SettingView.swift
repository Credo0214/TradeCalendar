import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("表示") {
                Picker("テーマ", selection: $viewModel.theme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
            }

            Section("リスク") {
                TextField("許容損失率", value: $viewModel.riskRate, format: .number)
                    .keyboardType(.decimalPad)
            }
        }
        .navigationTitle("設定")
        .onChange(of: viewModel.theme) { _, _ in viewModel.save() }
        .onChange(of: viewModel.riskRate) { _, _ in viewModel.save() }
    }
}

