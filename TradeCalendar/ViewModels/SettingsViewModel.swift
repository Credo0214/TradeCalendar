import Foundation
import CoreData
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var theme: String = "system"
    @Published var riskRate: Double = 0.05

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        loadOrCreate()
    }

    func loadOrCreate() {
        let request: NSFetchRequest<AppSettingsEntity> = AppSettingsEntity.fetchRequest()
        request.fetchLimit = 1

        do {
            if let s = try context.fetch(request).first {
                theme = s.theme ?? "system"      // ★修正
                riskRate = s.riskRate
            } else {
                let s = AppSettingsEntity(context: context)
                s.id = UUID()
                s.theme = "system"
                s.riskRate = 0.05
                try context.save()

                theme = s.theme ?? "system"      // ★修正
                riskRate = s.riskRate
            }
        } catch {
            theme = "system"
            riskRate = 0.05
        }
    }

    func save() {
        let request: NSFetchRequest<AppSettingsEntity> = AppSettingsEntity.fetchRequest()
        request.fetchLimit = 1

        do {
            let s = try context.fetch(request).first ?? AppSettingsEntity(context: context)
            if s.id == nil { s.id = UUID() }

            s.theme = theme.isEmpty ? "system" : theme
            s.riskRate = riskRate

            try context.save()
        } catch {
            context.rollback()
        }
    }
}

