import SwiftUI

struct HomeView: View {
    @State var viewModel: HomeViewModel
    @EnvironmentObject private var container: DIContainer
    var onLogout: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // User Info Card
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.user.fullName)
                                .font(.title2.bold())

                            Text("Account: \(viewModel.user.accountId)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    Divider()

                    VStack(spacing: 4) {
                        Text("Current Balance")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(viewModel.formattedBalance)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

                // Action Buttons
                VStack(spacing: 12) {
                    NavigationLink {
                        TransactionHistoryView(
                            viewModel: container.makeTransactionHistoryViewModel()
                        )
                    } label: {
                        ActionButton(
                            title: "Transaction History",
                            icon: "list.bullet.rectangle",
                            color: .blue
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        SendFundsView(
                            viewModel: container.makeSendFundsViewModel(
                                balance: viewModel.user.balance
                            ) { transaction, amount in
                                viewModel.updateBalance(by: amount)
                                // Persist the new transaction so it shows in history
                                let key = "savedTransactions"
                                var existing = (try? container.persistenceService.load(
                                    forKey: key, as: [Transaction].self
                                )) ?? []
                                existing.insert(transaction, at: 0)
                                try? container.persistenceService.save(existing, forKey: key)
                            }
                        )
                    } label: {
                        ActionButton(
                            title: "Send Funds",
                            icon: "paperplane.fill",
                            color: .orange
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task {
                            await viewModel.logout()
                            onLogout()
                        }
                    } label: {
                        ActionButton(
                            title: viewModel.isLoggingOut ? "Logging out..." : "Logout",
                            icon: "rectangle.portrait.and.arrow.right",
                            color: .red
                        )
                    }
                    .disabled(viewModel.isLoggingOut)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 40)

            Text(title)
                .fontWeight(.medium)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
