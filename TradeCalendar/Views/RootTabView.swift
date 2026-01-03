import SwiftUI
import CoreData

struct RootTabView: View {

    let context: NSManagedObjectContext
    @EnvironmentObject private var settingsStore: AppSettingsStore

    var body: some View {
        TabView {
            CalendarHomeView(viewModel: CalendarViewModel(context: context))
                .tabItem { Label("カレンダー", systemImage: "calendar") }

            ProfitGraphView(context: context)
                .tabItem { Label("グラフ", systemImage: "chart.line.uptrend.xyaxis") }

            RiskCalculatorView()
                .tabItem { Label("リスク", systemImage: "exclamationmark.triangle") }

            SettingView()
                .tabItem { Label("設定", systemImage: "gearshape") }
        }
        .preferredColorScheme(settingsStore.preferredColorScheme)
    }
}
