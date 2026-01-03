import SwiftUI
import CoreData

@main
struct TradeCalendarApp: App {

    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootTabView(
                context: persistenceController.container.viewContext
            )
            .environment(
                \.managedObjectContext,
                persistenceController.container.viewContext
            )
        }
    }
}

