import Foundation

nonisolated struct User: Codable, Equatable, Sendable {
    let id: String
    let fullName: String
    let email: String
    let accountId: String
    var balance: Double

    static let mock = User(
        id: "1",
        fullName: "John Doe",
        email: "test@app.com",
        accountId: "ACC-2024-001",
        balance: 10000.00
    )
}
