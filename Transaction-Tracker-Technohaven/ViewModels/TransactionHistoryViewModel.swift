import Foundation
import Observation

@Observable
@MainActor
final class TransactionHistoryViewModel {
    var transactions: [Transaction] = []
    var isLoading = false
    var errorMessage: String?

    private let transactionService: TransactionServiceProtocol
    private let persistenceService: PersistenceServiceProtocol
    private let transactionsPersistenceKey = "savedTransactions"

    init(
        transactionService: TransactionServiceProtocol,
        persistenceService: PersistenceServiceProtocol
    ) {
        self.transactionService = transactionService
        self.persistenceService = persistenceService
    }

    func loadTransactions() async {
        isLoading = true
        errorMessage = nil

        // Try loading from persistence first
        if let saved: [Transaction] = try? persistenceService.load(
            forKey: transactionsPersistenceKey,
            as: [Transaction].self
        ), !saved.isEmpty {
            transactions = saved.sorted { $0.date > $1.date }
            isLoading = false
            return
        }

        do {
            let fetched = try await transactionService.fetchTransactions()
            transactions = fetched.sorted { $0.date > $1.date }
            try? persistenceService.save(transactions, forKey: transactionsPersistenceKey)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func appendTransaction(_ transaction: Transaction) {
        transactions.insert(transaction, at: 0)
        try? persistenceService.save(transactions, forKey: transactionsPersistenceKey)
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func formattedAmount(_ transaction: Transaction) -> String {
        let prefix = transaction.type == .credit ? "+" : "-"
        return "\(prefix)$\(String(format: "%.2f", transaction.amount))"
    }
}
