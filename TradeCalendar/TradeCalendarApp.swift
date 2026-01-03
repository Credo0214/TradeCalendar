import SwiftUI
import CoreData
import UIKit

@main
struct TradeCalendarApp: App {

    let persistenceController = PersistenceController.shared
    @StateObject private var settingsStore: AppSettingsStore

    init() {
        let ctx = PersistenceController.shared.container.viewContext
        _settingsStore = StateObject(wrappedValue: AppSettingsStore(context: ctx))

        // TabBar: 選択=AppBlue, 未選択=グレー
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        let selected = UIColor(named: "AppBlue") ?? UIColor.systemBlue
        let normal = UIColor.systemGray2

        appearance.stackedLayoutAppearance.selected.iconColor = selected
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selected]
        appearance.stackedLayoutAppearance.normal.iconColor = normal
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normal]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(context: persistenceController.container.viewContext)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(settingsStore)
                .tint(Color("AppBlue"))
        }
    }
}
