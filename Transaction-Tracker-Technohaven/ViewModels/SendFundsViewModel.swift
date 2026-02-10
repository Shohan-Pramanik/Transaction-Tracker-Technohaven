import Foundation
import Observation

@Observable
@MainActor
final class SendFundsViewModel {
    var receiverId = ""
    var amountText = ""
    var isLoading = false
    var errorMessage: String?
    var showConfirmation = false
    var successMessage: String?
    let currentBalance: Double

    private let transactionService: TransactionServiceProtocol
    private let onTransferComplete: @MainActor (Transaction, Double) -> Void

    init(
        currentBalance: Double,
        transactionService: TransactionServiceProtocol,
        onTransferComplete: @escaping @MainActor (Transaction, Double) -> Void
    ) {
        self.currentBalance = currentBalance
        self.transactionService = transactionService
        self.onTransferComplete = onTransferComplete
    }

    var formattedBalance: String {
        String(format: "$%.2f", currentBalance)
    }

    var amount: Double {
        Double(amountText) ?? 0
    }

    func sendFunds() async {
        errorMessage = nil
        isLoading = true

        let transfer = FundTransfer(receiverId: receiverId, amount: amount)

        do {
            let transaction = try await transactionService.sendFunds(
                transfer: transfer,
                currentBalance: currentBalance
            )
            successMessage = "Successfully sent $\(String(format: "%.2f", amount)) to \(receiverId)"
            showConfirmation = true
            onTransferComplete(transaction, amount)
            receiverId = ""
            amountText = ""
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
