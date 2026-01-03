import Foundation
import CoreData
import Combine
import SwiftUI

@MainActor
final class AppSettingsStore: ObservableObject {

    enum AppearanceMode: Int16, CaseIterable, Identifiable {
        case system = 0
        case light  = 1
        case dark   = 2

        var id: Int16 { rawValue }

        var title: String {
            switch self {
            case .system: return "System"
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

    private enum ThemeStorageKind {
        case int16
        case string
        case unknown
    }

    @Published var riskRateText: String = ""
    @Published var appearanceMode: AppearanceMode = .system
    @Published private(set) var validationMessage: String? = nil

    private let context: NSManagedObjectContext
    private var settings: AppSettingsEntity?
    private var themeStorageKind: ThemeStorageKind = .unknown

    init(context: NSManagedObjectContext) {
        self.context = context
        loadOrCreate()
    }

    var preferredColorScheme: ColorScheme? {
        appearanceMode.colorScheme
    }

    func loadOrCreate() {
        let request = AppSettingsEntity.fetchRequest()
        request.fetchLimit = 1

        do {
            let results = try context.fetch(request)
            if let existing = results.first {
                settings = existing
            } else {
                let created = AppSettingsEntity(context: context)
                created.riskRate = 5
                // theme は型が不明でもOK。後で kind 判定して適切に保存する
                settings = created
                try context.save()
            }

            detectThemeStorageKind()
            syncFromEntity()

            // theme が未設定ならデフォルトを保存
            if getThemeValueRaw() == nil {
                setTheme(mode: .system)
            }

        } catch {
            validationMessage = "設定の読み込みに失敗しました。"
        }
    }

    func saveRiskRateIfValid() {
        guard let settings else { return }

        guard !riskRateText.isEmpty else {
            validationMessage = "リスク率を入力してください。"
            return
        }
        guard let value = Double(riskRateText) else {
            validationMessage = "リスク率は数値で入力してください。"
            return
        }
        guard value >= 0 && value <= 100 else {
            validationMessage = "リスク率は 0〜100 の範囲で入力してください。"
            return
        }

        settings.riskRate = value

        do {
            try context.save()
            validationMessage = nil
        } catch {
            validationMessage = "設定の保存に失敗しました。"
        }
    }

    func setAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
        setTheme(mode: mode)
    }

    // MARK: - Private

    private func syncFromEntity() {
        let rate = settings?.riskRate ?? 0
        riskRateText = formatNumber(rate)

        // theme → appearanceMode
        if let mode = readThemeAsMode() {
            appearanceMode = mode
        } else {
            appearanceMode = .system
        }

        validationMessage = nil
    }

    private func detectThemeStorageKind() {
        guard let settings else { return }

        if let attr = settings.entity.attributesByName["theme"] {
            switch attr.attributeType {
            case .integer16AttributeType:
                themeStorageKind = .int16
            case .stringAttributeType:
                themeStorageKind = .string
            default:
                themeStorageKind = .unknown
            }
        } else {
            themeStorageKind = .unknown
        }
    }

    private func getThemeValueRaw() -> Any? {
        settings?.value(forKey: "theme")
    }

    private func readThemeAsMode() -> AppearanceMode? {
        guard let raw = getThemeValueRaw() else { return nil }

        // Int16 / Int / NSNumber 系
        if let n = raw as? NSNumber {
            return AppearanceMode(rawValue: n.int16Value)
        }
        if let i16 = raw as? Int16 {
            return AppearanceMode(rawValue: i16)
        }
        if let i = raw as? Int {
            return AppearanceMode(rawValue: Int16(i))
        }

        // String 系
        if let s = raw as? String {
            switch s.lowercased() {
            case "system": return .system
            case "light":  return .light
            case "dark":   return .dark
            default:       return nil
            }
        }

        return nil
    }

    private func setTheme(mode: AppearanceMode) {
        guard let settings else { return }

        // 可能なら attributeType に合わせて保存
        switch themeStorageKind {
        case .int16:
            settings.setValue(mode.rawValue, forKey: "theme")
        case .string:
            let str: String
            switch mode {
            case .system: str = "system"
            case .light:  str = "light"
            case .dark:   str = "dark"
            }
            settings.setValue(str, forKey: "theme")
        case .unknown:
            // unknown の場合は既存の値型に合わせる（なければ String で）
            if let raw = getThemeValueRaw(), !(raw is NSNull) {
                if raw is NSNumber || raw is Int16 || raw is Int {
                    settings.setValue(mode.rawValue, forKey: "theme")
                } else {
                    let str: String
                    switch mode {
                    case .system: str = "system"
                    case .light:  str = "light"
                    case .dark:   str = "dark"
                    }
                    settings.setValue(str, forKey: "theme")
                }
            } else {
                settings.setValue("system", forKey: "theme")
            }
        }

        do {
            try context.save()
        } catch {
            validationMessage = "表示設定の保存に失敗しました。"
        }
    }

    private func formatNumber(_ value: Double) -> String {
        if value.rounded() == value { return String(Int(value)) }
        return String(value)
    }
}
