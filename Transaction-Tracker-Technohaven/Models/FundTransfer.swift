import Foundation

nonisolated struct FundTransfer: Sendable {
    let receiverId: String
    let amount: Double
}
