import Foundation
import Combine
import CoreData

@MainActor
final class RiskCalculatorViewModel: ObservableObject {

    // Inputs（文字列で受ける）
    @Published var balanceText: String = ""
    @Published var riskPercentText: String = ""

    // Output
    @Published private(set) var allowedLossText: String = "—"
    @Published private(set) var validationMessage: String? = nil

    private var cancellables: Set<AnyCancellable> = []

    init() {
        Publishers.CombineLatest($balanceText, $riskPercentText)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.recalculate()
            }
            .store(in: &cancellables)
    }

    func loadDefaults(context: NSManagedObjectContext) {
        if let risk = fetchRiskRatePercent(context: context) {
            riskPercentText = formatDecimal(risk, maxFractionDigits: 2)
        }
        if let balance = fetchLatestBalanceAfter(context: context) {
            balanceText = formatDecimal(balance, maxFractionDigits: 0)
        }
    }

    private func recalculate() {
        let b = balanceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let r = riskPercentText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !b.isEmpty, !r.isEmpty else {
            allowedLossText = "—"
            validationMessage = nil
            return
        }

        guard let balance = parseDouble(b),
              let riskPercent = parseDouble(r)
        else {
            allowedLossText = "—"
            validationMessage = "数値として解釈できない入力があります"
            return
        }

        guard let loss = RiskCalculator.allowedLoss(
            balance: balance,
            riskPercent: riskPercent
        ) else {
            allowedLossText = "—"
            validationMessage = "入力値は 0 より大きい必要があります"
            return
        }

        allowedLossText = formatJPY(loss)
        validationMessage = nil
    }

    // MARK: - Core Data

    private func fetchRiskRatePercent(context: NSManagedObjectContext) -> Double? {
        let req = NSFetchRequest<AppSettingsEntity>(entityName: "AppSettingsEntity")
        req.fetchLimit = 1
        return try? context.fetch(req).first?.riskRate
    }

    private func fetchLatestBalanceAfter(context: NSManagedObjectContext) -> Double? {
        let req = NSFetchRequest<TradeEntity>(entityName: "TradeEntity")
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "date != nil")
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return try? context.fetch(req).first?.balanceAfter
    }

    // MARK: - Utils

    private func parseDouble(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: ""))
    }

    private func formatJPY(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = "JPY"
        nf.maximumFractionDigits = 0
        return nf.string(from: NSNumber(value: value)) ?? "—"
    }

    private func formatDecimal(_ value: Double, maxFractionDigits: Int) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = maxFractionDigits
        return nf.string(from: NSNumber(value: value)) ?? ""
    }
}

