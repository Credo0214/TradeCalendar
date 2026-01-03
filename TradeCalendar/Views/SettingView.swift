import SwiftUI

struct SettingView: View {

    @EnvironmentObject private var settingsStore: AppSettingsStore
    @FocusState private var isRiskFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("リスク設定") {
                    HStack {
                        Text("リスク率（%）")
                        Spacer()
                        TextField("例: 5", text: $settingsStore.riskRateText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(minWidth: 80)
                            .focused($isRiskFocused)
                            .onChange(of: isRiskFocused) { focused in
                                if !focused {
                                    settingsStore.saveRiskRateIfValid()
                                }
                            }
                    }

                    if let message = settingsStore.validationMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section("表示") {
                    Picker(
                        "テーマ",
                        selection: Binding(
                            get: { settingsStore.appearanceMode },
                            set: { settingsStore.setAppearanceMode($0) }
                        )
                    ) {
                        ForEach(AppSettingsStore.AppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Color("AppBlue"))
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        settingsStore.saveRiskRateIfValid()
                        isRiskFocused = false
                    }
                }
            }
        }
        .tint(Color("AppBlue"))
    }
}
