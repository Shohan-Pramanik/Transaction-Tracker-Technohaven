import Foundation
import Observation

@Observable
@MainActor
final class LoginViewModel {
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?
    var isAuthenticated = false
    var authenticatedUser: User?
    var isBiometricAvailable = false

    private let authService: AuthenticationServiceProtocol
    private let biometricService: BiometricServiceProtocol
    private let persistenceService: PersistenceServiceProtocol

    private let userPersistenceKey = "loggedInUser"

    init(
        authService: AuthenticationServiceProtocol,
        biometricService: BiometricServiceProtocol,
        persistenceService: PersistenceServiceProtocol
    ) {
        self.authService = authService
        self.biometricService = biometricService
        self.persistenceService = persistenceService
        self.isBiometricAvailable = biometricService.canUseBiometrics()
    }

    func login() async {
        errorMessage = nil
        isLoading = true

        do {
            let freshUser = try await authService.login(
                credentials: LoginCredentials(email: email, password: password)
            )
            // Use persisted user (with real balance) if available; only save fresh mock on first login
            if let savedUser: User = try? persistenceService.load(forKey: userPersistenceKey, as: User.self) {
                authenticatedUser = savedUser
            } else {
                try? persistenceService.save(freshUser, forKey: userPersistenceKey)
                authenticatedUser = freshUser
            }
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loginWithBiometrics() async {
        errorMessage = nil
        isLoading = true

        do {
            let success = try await biometricService.authenticate()
            if success {
                if let savedUser: User = try? persistenceService.load(forKey: userPersistenceKey, as: User.self) {
                    authenticatedUser = savedUser
                    isAuthenticated = true
                } else {
                    errorMessage = "No saved session. Please login with credentials first."
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func checkExistingSession() {
        if let savedUser: User = try? persistenceService.load(forKey: userPersistenceKey, as: User.self) {
            authenticatedUser = savedUser
            isBiometricAvailable = biometricService.canUseBiometrics()
        }
    }
}
