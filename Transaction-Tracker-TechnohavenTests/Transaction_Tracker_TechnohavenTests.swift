import Testing
import Foundation
@testable import Transaction_Tracker_Technohaven

// MARK: - Mock Services

final class MockAuthService: AuthenticationServiceProtocol {
    var shouldSucceed = true
    var loginCallCount = 0
    var logoutCallCount = 0

    func login(credentials: LoginCredentials) async throws -> User {
        loginCallCount += 1
        if shouldSucceed {
            return User.mock
        }
        throw AuthenticationError.invalidCredentials
    }

    func logout() async {
        logoutCallCount += 1
    }
}

final class MockTransactionService: TransactionServiceProtocol {
    var shouldSucceed = true
    var mockTransactions: [Transaction] = []
    var fetchCallCount = 0
    var sendCallCount = 0

    func fetchTransactions() async throws -> [Transaction] {
        fetchCallCount += 1
        if shouldSucceed {
            return mockTransactions
        }
        throw TransactionError.dataLoadFailed
    }

    func sendFunds(transfer: FundTransfer, currentBalance: Double) async throws -> Transaction {
        sendCallCount += 1
        guard !transfer.receiverId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TransactionError.emptyReceiverId
        }
        guard transfer.amount > 0 else {
            throw TransactionError.invalidAmount
        }
        guard transfer.amount <= currentBalance else {
            throw TransactionError.insufficientBalance
        }
        return Transaction(
            id: "TXN_TEST",
            date: Date(),
            title: "Transfer to \(transfer.receiverId)",
            amount: transfer.amount,
            type: .debit
        )
    }
}

final class MockBiometricService: BiometricServiceProtocol {
    var isAvailable = true
    var shouldSucceed = true

    func canUseBiometrics() -> Bool {
        return isAvailable
    }

    func authenticate() async throws -> Bool {
        if shouldSucceed {
            return true
        }
        throw BiometricError.authenticationFailed
    }
}

final class MockPersistenceService: PersistenceServiceProtocol {
    var storage: [String: Data] = [:]

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        storage[key] = try encoder.encode(value)
    }

    func load<T: Codable>(forKey key: String, as type: T.Type) throws -> T? {
        guard let data = storage[key] else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    func remove(forKey key: String) {
        storage.removeValue(forKey: key)
    }
}

// MARK: - User Model Tests

struct UserModelTests {
    @Test func userCodable() throws {
        let user = User.mock
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(User.self, from: data)

        #expect(decoded.id == user.id)
        #expect(decoded.fullName == user.fullName)
        #expect(decoded.email == user.email)
        #expect(decoded.accountId == user.accountId)
        #expect(decoded.balance == user.balance)
    }

    @Test func userMockValues() {
        let user = User.mock
        #expect(user.email == "test@app.com")
        #expect(user.fullName == "John Doe")
        #expect(user.balance == 10000.00)
    }
}

// MARK: - Transaction Model Tests

struct TransactionModelTests {
    @Test func transactionCodable() throws {
        let json = """
        {
            "id": "TXN001",
            "date": "2025-01-15T10:30:00Z",
            "title": "Salary Deposit",
            "amount": 5000.00,
            "type": "credit"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let transaction = try decoder.decode(Transaction.self, from: Data(json.utf8))

        #expect(transaction.id == "TXN001")
        #expect(transaction.title == "Salary Deposit")
        #expect(transaction.amount == 5000.00)
        #expect(transaction.type == .credit)
    }

    @Test func transactionArrayCodable() throws {
        let json = """
        [
            {"id": "TXN001", "date": "2025-01-15T10:30:00Z", "title": "Deposit", "amount": 100.0, "type": "credit"},
            {"id": "TXN002", "date": "2025-01-16T10:30:00Z", "title": "Withdrawal", "amount": 50.0, "type": "debit"}
        ]
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let transactions = try decoder.decode([Transaction].self, from: Data(json.utf8))

        #expect(transactions.count == 2)
        #expect(transactions[0].type == .credit)
        #expect(transactions[1].type == .debit)
    }
}

// MARK: - Authentication Service Tests

struct AuthenticationServiceTests {
    @Test func loginWithValidCredentials() async throws {
        let service = AuthenticationService()
        let credentials = LoginCredentials(email: "test@app.com", password: "123456")
        let user = try await service.login(credentials: credentials)

        #expect(user.email == "test@app.com")
        #expect(user.fullName == "John Doe")
    }

    @Test func loginWithInvalidEmail() async {
        let service = AuthenticationService()
        let credentials = LoginCredentials(email: "invalid", password: "123456")

        do {
            _ = try await service.login(credentials: credentials)
            #expect(Bool(false), "Should have thrown")
        } catch let error as AuthenticationError {
            #expect(error == .invalidEmail)
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    @Test func loginWithShortPassword() async {
        let service = AuthenticationService()
        let credentials = LoginCredentials(email: "test@app.com", password: "123")

        do {
            _ = try await service.login(credentials: credentials)
            #expect(Bool(false), "Should have thrown")
        } catch let error as AuthenticationError {
            #expect(error == .passwordTooShort)
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    @Test func loginWithWrongCredentials() async {
        let service = AuthenticationService()
        let credentials = LoginCredentials(email: "wrong@app.com", password: "123456")

        do {
            _ = try await service.login(credentials: credentials)
            #expect(Bool(false), "Should have thrown")
        } catch let error as AuthenticationError {
            #expect(error == .invalidCredentials)
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }
}

// MARK: - Transaction Service Tests

struct TransactionServiceTests {
    @Test func sendFundsWithValidData() async throws {
        let service = MockTransactionService()
        service.shouldSucceed = true
        let transfer = FundTransfer(receiverId: "USER001", amount: 100.0)
        let transaction = try await service.sendFunds(transfer: transfer, currentBalance: 1000.0)

        #expect(transaction.amount == 100.0)
        #expect(transaction.type == .debit)
        #expect(service.sendCallCount == 1)
    }

    @Test func sendFundsWithZeroAmount() async {
        let service = MockTransactionService()
        let transfer = FundTransfer(receiverId: "USER001", amount: 0)

        do {
            _ = try await service.sendFunds(transfer: transfer, currentBalance: 1000.0)
            #expect(Bool(false), "Should have thrown")
        } catch let error as TransactionError {
            #expect(error == .invalidAmount)
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    @Test func sendFundsExceedingBalance() async {
        let service = MockTransactionService()
        let transfer = FundTransfer(receiverId: "USER001", amount: 2000.0)

        do {
            _ = try await service.sendFunds(transfer: transfer, currentBalance: 1000.0)
            #expect(Bool(false), "Should have thrown")
        } catch let error as TransactionError {
            #expect(error == .insufficientBalance)
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    @Test func sendFundsWithEmptyReceiver() async {
        let service = MockTransactionService()
        let transfer = FundTransfer(receiverId: "", amount: 100.0)

        do {
            _ = try await service.sendFunds(transfer: transfer, currentBalance: 1000.0)
            #expect(Bool(false), "Should have thrown")
        } catch let error as TransactionError {
            #expect(error == .emptyReceiverId)
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }
}

// MARK: - Persistence Service Tests

struct PersistenceServiceTests {
    @Test func saveAndLoadUser() throws {
        let service = MockPersistenceService()
        let user = User.mock

        try service.save(user, forKey: "testUser")
        let loaded: User? = try service.load(forKey: "testUser", as: User.self)

        #expect(loaded != nil)
        #expect(loaded?.email == user.email)
        #expect(loaded?.balance == user.balance)
    }

    @Test func saveAndLoadTransactions() throws {
        let service = MockPersistenceService()
        let transactions = [
            Transaction(id: "1", date: Date(), title: "Test", amount: 100, type: .credit),
            Transaction(id: "2", date: Date(), title: "Test 2", amount: 50, type: .debit)
        ]

        try service.save(transactions, forKey: "testTransactions")
        let loaded: [Transaction]? = try service.load(forKey: "testTransactions", as: [Transaction].self)

        #expect(loaded?.count == 2)
    }

    @Test func loadNonExistentKey() throws {
        let service = MockPersistenceService()
        let loaded: User? = try service.load(forKey: "nonExistent", as: User.self)
        #expect(loaded == nil)
    }

    @Test func removeKey() throws {
        let service = MockPersistenceService()
        try service.save(User.mock, forKey: "testUser")
        service.remove(forKey: "testUser")
        let loaded: User? = try service.load(forKey: "testUser", as: User.self)
        #expect(loaded == nil)
    }
}

// MARK: - LoginViewModel Tests

@MainActor
struct LoginViewModelTests {
    func makeViewModel(
        authService: MockAuthService = MockAuthService(),
        biometricService: MockBiometricService = MockBiometricService(),
        persistenceService: MockPersistenceService = MockPersistenceService()
    ) -> (LoginViewModel, MockAuthService, MockBiometricService, MockPersistenceService) {
        let vm = LoginViewModel(
            authService: authService,
            biometricService: biometricService,
            persistenceService: persistenceService
        )
        return (vm, authService, biometricService, persistenceService)
    }

    @Test func loginSuccess() async {
        let (vm, _, _, _) = makeViewModel()
        vm.email = "test@app.com"
        vm.password = "123456"

        await vm.login()

        #expect(vm.isAuthenticated == true)
        #expect(vm.authenticatedUser != nil)
        #expect(vm.errorMessage == nil)
    }

    @Test func loginFailure() async {
        let authService = MockAuthService()
        authService.shouldSucceed = false
        let (vm, _, _, _) = makeViewModel(authService: authService)
        vm.email = "test@app.com"
        vm.password = "123456"

        await vm.login()

        #expect(vm.isAuthenticated == false)
        #expect(vm.errorMessage != nil)
    }

    @Test func biometricAvailability() {
        let biometricService = MockBiometricService()
        biometricService.isAvailable = true
        let (vm, _, _, _) = makeViewModel(biometricService: biometricService)

        #expect(vm.isBiometricAvailable == true)
    }

    @Test func biometricLoginWithSavedSession() async throws {
        let persistenceService = MockPersistenceService()
        try persistenceService.save(User.mock, forKey: "loggedInUser")

        let (vm, _, _, _) = makeViewModel(persistenceService: persistenceService)

        await vm.loginWithBiometrics()

        #expect(vm.isAuthenticated == true)
        #expect(vm.authenticatedUser?.email == "test@app.com")
    }

    @Test func biometricLoginWithoutSavedSession() async {
        let (vm, _, _, _) = makeViewModel()

        await vm.loginWithBiometrics()

        #expect(vm.isAuthenticated == false)
        #expect(vm.errorMessage != nil)
    }
}

// MARK: - HomeViewModel Tests

@MainActor
struct HomeViewModelTests {
    @Test func formattedBalance() {
        let vm = HomeViewModel(
            user: User.mock,
            authService: MockAuthService(),
            persistenceService: MockPersistenceService()
        )

        #expect(vm.formattedBalance == "$10000.00")
    }

    @Test func updateBalance() {
        let vm = HomeViewModel(
            user: User.mock,
            authService: MockAuthService(),
            persistenceService: MockPersistenceService()
        )

        vm.updateBalance(by: 500.0)
        #expect(vm.user.balance == 9500.00)
    }

    @Test func logout() async {
        let authService = MockAuthService()
        let persistenceService = MockPersistenceService()
        let vm = HomeViewModel(
            user: User.mock,
            authService: authService,
            persistenceService: persistenceService
        )

        await vm.logout()
        #expect(authService.logoutCallCount == 1)
    }
}

// MARK: - TransactionHistoryViewModel Tests

@MainActor
struct TransactionHistoryViewModelTests {
    @Test func loadTransactionsFromService() async {
        let service = MockTransactionService()
        service.mockTransactions = [
            Transaction(id: "1", date: Date(), title: "Test", amount: 100, type: .credit)
        ]

        let vm = TransactionHistoryViewModel(
            transactionService: service,
            persistenceService: MockPersistenceService()
        )

        await vm.loadTransactions()

        #expect(vm.transactions.count == 1)
        #expect(vm.errorMessage == nil)
    }

    @Test func loadTransactionsFromPersistence() async throws {
        let persistence = MockPersistenceService()
        let savedTransactions = [
            Transaction(id: "1", date: Date(), title: "Saved", amount: 200, type: .debit)
        ]
        try persistence.save(savedTransactions, forKey: "savedTransactions")

        let vm = TransactionHistoryViewModel(
            transactionService: MockTransactionService(),
            persistenceService: persistence
        )

        await vm.loadTransactions()

        #expect(vm.transactions.count == 1)
        #expect(vm.transactions.first?.title == "Saved")
    }

    @Test func appendTransaction() {
        let vm = TransactionHistoryViewModel(
            transactionService: MockTransactionService(),
            persistenceService: MockPersistenceService()
        )

        let transaction = Transaction(id: "NEW", date: Date(), title: "New Transfer", amount: 50, type: .debit)
        vm.appendTransaction(transaction)

        #expect(vm.transactions.count == 1)
        #expect(vm.transactions.first?.id == "NEW")
    }

    @Test func formattedAmountCredit() {
        let vm = TransactionHistoryViewModel(
            transactionService: MockTransactionService(),
            persistenceService: MockPersistenceService()
        )

        let transaction = Transaction(id: "1", date: Date(), title: "Credit", amount: 100, type: .credit)
        #expect(vm.formattedAmount(transaction) == "+$100.00")
    }

    @Test func formattedAmountDebit() {
        let vm = TransactionHistoryViewModel(
            transactionService: MockTransactionService(),
            persistenceService: MockPersistenceService()
        )

        let transaction = Transaction(id: "1", date: Date(), title: "Debit", amount: 50, type: .debit)
        #expect(vm.formattedAmount(transaction) == "-$50.00")
    }

    @Test func loadTransactionsError() async {
        let service = MockTransactionService()
        service.shouldSucceed = false

        let vm = TransactionHistoryViewModel(
            transactionService: service,
            persistenceService: MockPersistenceService()
        )

        await vm.loadTransactions()

        #expect(vm.transactions.isEmpty)
        #expect(vm.errorMessage != nil)
    }
}

// MARK: - SendFundsViewModel Tests

@MainActor
struct SendFundsViewModelTests {
    @Test func sendFundsSuccess() async {
        var receivedTransaction: Transaction?
        var receivedAmount: Double?

        let vm = SendFundsViewModel(
            currentBalance: 1000.0,
            transactionService: MockTransactionService(),
            onTransferComplete: { transaction, amount in
                receivedTransaction = transaction
                receivedAmount = amount
            }
        )

        vm.receiverId = "USER001"
        vm.amountText = "100.0"

        await vm.sendFunds()

        #expect(vm.showConfirmation == true)
        #expect(vm.errorMessage == nil)
        #expect(receivedTransaction != nil)
        #expect(receivedAmount == 100.0)
    }

    @Test func sendFundsInsufficientBalance() async {
        let vm = SendFundsViewModel(
            currentBalance: 50.0,
            transactionService: MockTransactionService(),
            onTransferComplete: { _, _ in }
        )

        vm.receiverId = "USER001"
        vm.amountText = "100.0"

        await vm.sendFunds()

        #expect(vm.showConfirmation == false)
        #expect(vm.errorMessage != nil)
    }

    @Test func formattedBalance() {
        let vm = SendFundsViewModel(
            currentBalance: 1234.56,
            transactionService: MockTransactionService(),
            onTransferComplete: { _, _ in }
        )

        #expect(vm.formattedBalance == "$1234.56")
    }

    @Test func amountParsing() {
        let vm = SendFundsViewModel(
            currentBalance: 1000.0,
            transactionService: MockTransactionService(),
            onTransferComplete: { _, _ in }
        )

        vm.amountText = "250.50"
        #expect(vm.amount == 250.50)

        vm.amountText = "invalid"
        #expect(vm.amount == 0)
    }
}

// MARK: - Error Description Tests

struct ErrorDescriptionTests {
    @Test func authenticationErrorDescriptions() {
        #expect(AuthenticationError.invalidEmail.errorDescription != nil)
        #expect(AuthenticationError.passwordTooShort.errorDescription != nil)
        #expect(AuthenticationError.invalidCredentials.errorDescription != nil)
    }

    @Test func transactionErrorDescriptions() {
        #expect(TransactionError.invalidAmount.errorDescription != nil)
        #expect(TransactionError.insufficientBalance.errorDescription != nil)
        #expect(TransactionError.emptyReceiverId.errorDescription != nil)
        #expect(TransactionError.dataLoadFailed.errorDescription != nil)
    }
}
