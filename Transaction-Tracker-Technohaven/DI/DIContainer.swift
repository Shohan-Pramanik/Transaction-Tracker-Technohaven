import Foundation
import Combine

final class DIContainer: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()

    let authService: AuthenticationServiceProtocol
    let transactionService: TransactionServiceProtocol
    let biometricService: BiometricServiceProtocol
    let persistenceService: PersistenceServiceProtocol

    init(
        authService: AuthenticationServiceProtocol = AuthenticationService(),
        transactionService: TransactionServiceProtocol = TransactionService(),
        biometricService: BiometricServiceProtocol = BiometricService(),
        persistenceService: PersistenceServiceProtocol = PersistenceService()
    ) {
        self.authService = authService
        self.transactionService = transactionService
        self.biometricService = biometricService
        self.persistenceService = persistenceService
    }

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(
            authService: authService,
            biometricService: biometricService,
            persistenceService: persistenceService
        )
    }

    func makeHomeViewModel(user: User) -> HomeViewModel {
        HomeViewModel(
            user: user,
            authService: authService,
            persistenceService: persistenceService
        )
    }

    func makeTransactionHistoryViewModel() -> TransactionHistoryViewModel {
        TransactionHistoryViewModel(
            transactionService: transactionService,
            persistenceService: persistenceService
        )
    }

    func makeSendFundsViewModel(balance: Double, onTransferComplete: @escaping @MainActor (Transaction, Double) -> Void) -> SendFundsViewModel {
        SendFundsViewModel(
            currentBalance: balance,
            transactionService: transactionService,
            onTransferComplete: onTransferComplete
        )
    }
}
