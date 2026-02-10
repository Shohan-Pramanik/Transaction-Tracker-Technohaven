import Foundation

protocol AuthenticationServiceProtocol: Sendable {
    func login(credentials: LoginCredentials) async throws -> User
    func logout() async
}

enum AuthenticationError: LocalizedError, Equatable {
    case invalidEmail
    case passwordTooShort
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .passwordTooShort:
            return "Password must be at least 6 characters."
        case .invalidCredentials:
            return "Invalid email or password."
        }
    }
}

nonisolated final class AuthenticationService: AuthenticationServiceProtocol {
    private let validEmail = "test@app.com"
    private let validPassword = "123456"

    func login(credentials: LoginCredentials) async throws -> User {
        try validateEmail(credentials.email)
        try validatePassword(credentials.password)

        try await Task.sleep(nanoseconds: 500_000_000)

        guard credentials.email == validEmail,
              credentials.password == validPassword else {
            throw AuthenticationError.invalidCredentials
        }

        return User.mock
    }

    func logout() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
    }

    private func validateEmail(_ email: String) throws {
        let pattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let pred = NSPredicate(format: "SELF MATCHES %@", pattern)
        guard pred.evaluate(with: email) else {
            throw AuthenticationError.invalidEmail
        }
    }

    private func validatePassword(_ password: String) throws {
        guard password.count >= 6 else {
            throw AuthenticationError.passwordTooShort
        }
    }
}
