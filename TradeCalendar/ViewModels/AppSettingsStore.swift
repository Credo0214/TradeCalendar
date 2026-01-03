import Foundation
import CoreData
import Combine
import SwiftUI

@MainActor
final class AppSettingsStore: ObservableObject {

    enum AppearanceMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system: return "自動"
            case .light:  return "Light"
            case .dark:   return "Dark"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light:  return .light
            case .dark:   return .dark
            }
        }
    }

    // MARK: - Published state (SSOT)

    @Published private(set) var riskRate: Double = 1.0          // 例: 5 = 5%
    @Published var riskRateText: String = "1"
    @Published private(set) var appearanceMode: AppearanceMode = .system
    @Published private(set) var validationMessage: String? = nil

    // MARK: - Private

    private let context: NSManagedObjectContext
    private var settingsEntity: AppSettingsEntity?

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.context = context
        loadOrCreate()
    }

    // MARK: - Public helpers

    var preferredColorScheme: ColorScheme? {
        appearanceMode.colorScheme
    }

    func setAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
        persist()
    }

    func saveRiskRateIfValid() {
        let trimmed = riskRateText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed) else {
            validationMessage = "数値を入力してください"
            // 表示は元に戻す
            riskRateText = formatRiskRate(riskRate)
            return
        }

        // 製品として安全側: 0 < risk <= 100
        guard value > 0, value <= 100 else {
            validationMessage = "0より大きく、100以下で入力してください"
            riskRateText = formatRiskRate(riskRate)
            return
        }

        validationMessage = nil
        riskRate = value
        riskRateText = formatRiskRate(value)
        persist()
    }

    // MARK: - Core

    private func loadOrCreate() {
        let req = NSFetchRequest<AppSettingsEntity>(entityName: "AppSettingsEntity")
        req.fetchLimit = 1

        do {
            let found = try context.fetch(req).first
            if let found {
                settingsEntity = found
            } else {
                let created = AppSettingsEntity(context: context)
                created.id = UUID()
                created.createdAt = Date()
                created.riskRate = 1.0
                created.theme = AppearanceMode.system.rawValue
                settingsEntity = created
                try context.save()
            }

            applyFromEntity()

        } catch {
            // 失敗してもアプリが落ちない最小安全動作
            settingsEntity = nil
            riskRate = 1.0
            riskRateText = "1"
            appearanceMode = .system
            validationMessage = "設定の読み込みに失敗しました（\(error.localizedDescription)）"
        }
    }

    private func applyFromEntity() {
        guard let e = settingsEntity else { return }

        let rate = e.riskRate
        riskRate = (rate > 0 ? rate : 1.0)
        riskRateText = formatRiskRate(riskRate)

        let rawTheme = (e.theme ?? AppearanceMode.system.rawValue)
        appearanceMode = AppearanceMode(rawValue: rawTheme) ?? .system
    }

    private func persist() {
        guard let e = settingsEntity else { return }

        e.riskRate = riskRate
        e.theme = appearanceMode.rawValue

        do {
            try context.save()
        } catch {
            validationMessage = "保存に失敗しました（\(error.localizedDescription)）"
        }
    }

    private func formatRiskRate(_ value: Double) -> String {
        // 5.0 → "5" / 5.5 → "5.5"
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(value)
    }
}

