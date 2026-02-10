import Foundation
import LocalAuthentication

protocol BiometricServiceProtocol: Sendable {
    func canUseBiometrics() -> Bool
    func authenticate() async throws -> Bool
}

enum BiometricError: LocalizedError {
    case notAvailable
    case authenticationFailed
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device."
        case .authenticationFailed:
            return "Biometric authentication failed."
        case .userCancelled:
            return "Authentication was cancelled."
        }
    }
}

nonisolated final class BiometricService: BiometricServiceProtocol {
    func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate() async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricError.notAvailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access your account"
            )
            return success
        } catch let authError as LAError {
            switch authError.code {
            case .userCancel, .appCancel, .systemCancel:
                throw BiometricError.userCancelled
            default:
                throw BiometricError.authenticationFailed
            }
        }
    }
}
