import SwiftUI
import CoreData

struct RootTabView: View {

    let context: NSManagedObjectContext

    var body: some View {
        TabView {

            CalendarHomeView(
                viewModel: CalendarViewModel(context: context)
            )
            .tabItem {
                Label("カレンダー", systemImage: "calendar")
            }

            ProfitGraphView(
                viewModel: ProfitGraphViewModel(context: context)
            )
            .tabItem {
                Label("グラフ", systemImage: "chart.line.uptrend.xyaxis")
            }

            LotCalculatorView(
                viewModel: LotCalculatorViewModel()
            )
                .tabItem {
                    Label("ロット", systemImage: "calculator")
                }

            SettingsView(
                viewModel: SettingsViewModel(context: context)
            )
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
    }
}

