import Foundation

protocol TransactionServiceProtocol: Sendable {
    func fetchTransactions() async throws -> [Transaction]
    func sendFunds(transfer: FundTransfer, currentBalance: Double) async throws -> Transaction
}

enum TransactionError: LocalizedError, Equatable {
    case invalidAmount
    case insufficientBalance
    case emptyReceiverId
    case dataLoadFailed

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Amount must be greater than zero."
        case .insufficientBalance:
            return "Insufficient balance for this transfer."
        case .emptyReceiverId:
            return "Please enter a receiver ID."
        case .dataLoadFailed:
            return "Failed to load transaction data."
        }
    }
}

nonisolated final class TransactionService: TransactionServiceProtocol {
    func fetchTransactions() async throws -> [Transaction] {
        try await Task.sleep(nanoseconds: 300_000_000)

        guard let url = Bundle.main.url(forResource: "MockTransactions", withExtension: "json") else {
            throw TransactionError.dataLoadFailed
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Transaction].self, from: data)
    }

    func sendFunds(transfer: FundTransfer, currentBalance: Double) async throws -> Transaction {
        guard !transfer.receiverId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TransactionError.emptyReceiverId
        }

        guard transfer.amount > 0 else {
            throw TransactionError.invalidAmount
        }

        guard transfer.amount <= currentBalance else {
            throw TransactionError.insufficientBalance
        }

        try await Task.sleep(nanoseconds: 500_000_000)

        return Transaction(
            id: "TXN\(UUID().uuidString.prefix(6))",
            date: Date(),
            title: "Transfer to \(transfer.receiverId)",
            amount: transfer.amount,
            type: .debit
        )
    }
}
