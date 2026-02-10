import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var user: User
    var isLoggingOut = false

    private let authService: AuthenticationServiceProtocol
    private let persistenceService: PersistenceServiceProtocol
    private let userPersistenceKey = "loggedInUser"

    init(
        user: User,
        authService: AuthenticationServiceProtocol,
        persistenceService: PersistenceServiceProtocol
    ) {
        self.user = user
        self.authService = authService
        self.persistenceService = persistenceService
    }

    var formattedBalance: String {
        String(format: "$%.2f", user.balance)
    }

    func logout() async {
        isLoggingOut = true
        await authService.logout()
        isLoggingOut = false
    }

    func updateBalance(by amount: Double) {
        user.balance -= amount
        try? persistenceService.save(user, forKey: userPersistenceKey)
    }
}
