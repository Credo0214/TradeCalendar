import Foundation
import CoreData
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Input / Output (for View)
    @Published var riskRateText: String = ""
    @Published private(set) var validationMessage: String? = nil

    // MARK: - Internal
    private var settings: AppSettingsEntity?
    private var context: NSManagedObjectContext?
    private var cancellables = Set<AnyCancellable>()

    // 許容範囲（最小実装）
    private let minRiskRate: Double = 0
    private let maxRiskRate: Double = 100

    init() {
        // 入力が変わるたびに軽く検証（保存は明示的に）
        $riskRateText
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.validateOnly()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    func load(context: NSManagedObjectContext) {
        self.context = context

        let request = AppSettingsEntity.fetchRequest()
        request.fetchLimit = 1

        do {
            let results = try context.fetch(request)
            if let existing = results.first {
                self.settings = existing
            } else {
                let created = AppSettingsEntity(context: context)
                created.riskRate = 5 // デフォルト（必要なら0でも可）
                self.settings = created
                try context.save()
            }
            syncFromEntityToView()
        } catch {
            // ここは事故防止のため「落とさない」。画面上で最低限通知。
            validationMessage = "設定の読み込みに失敗しました。"
        }
    }

    func saveIfValid() {
        guard let context else { return }
        guard let settings else { return }

        guard let value = Double(riskRateText) else {
            validationMessage = "リスク率は数値で入力してください。"
            return
        }
        guard value >= minRiskRate && value <= maxRiskRate else {
            validationMessage = "リスク率は \(Int(minRiskRate))〜\(Int(maxRiskRate)) の範囲で入力してください。"
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

    // View用：Stepperなどから安全に増減させたい場合
    func setRiskRate(_ newValue: Double) {
        riskRateText = formatNumber(newValue)
        saveIfValid()
    }

    // 補助表示用（表示のみ）
    var riskFractionPreviewText: String {
        guard let value = Double(riskRateText) else { return "—" }
        let fraction = value / 100.0
        return String(format: "%.4f", fraction)
    }

    // MARK: - Private

    private func syncFromEntityToView() {
        let current = settings?.riskRate ?? 0
        riskRateText = formatNumber(current)
        validationMessage = nil
    }

    private func validateOnly() {
        guard !riskRateText.isEmpty else {
            validationMessage = "リスク率を入力してください。"
            return
        }
        guard let value = Double(riskRateText) else {
            validationMessage = "リスク率は数値で入力してください。"
            return
        }
        guard value >= minRiskRate && value <= maxRiskRate else {
            validationMessage = "リスク率は \(Int(minRiskRate))〜\(Int(maxRiskRate)) の範囲で入力してください。"
            return
        }
        validationMessage = nil
    }

    private func formatNumber(_ value: Double) -> String {
        // 余計な0を出しにくい簡易フォーマット（最小実装）
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(value)
    }
}
