import Foundation

nonisolated struct Transaction: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let date: Date
    let title: String
    let amount: Double
    let type: TransactionType

    nonisolated enum TransactionType: String, Codable, Sendable {
        case credit
        case debit
    }
}
