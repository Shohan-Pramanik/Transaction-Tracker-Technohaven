import SwiftUI

struct TransactionHistoryView: View {
    @State var viewModel: TransactionHistoryViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading transactions...")
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.loadTransactions() }
                    }
                }
            } else if viewModel.transactions.isEmpty {
                ContentUnavailableView(
                    "No Transactions",
                    systemImage: "tray",
                    description: Text("Your transaction history will appear here.")
                )
            } else {
                List(viewModel.transactions) { transaction in
                    TransactionRow(
                        transaction: transaction,
                        formattedDate: viewModel.formattedDate(transaction.date),
                        formattedAmount: viewModel.formattedAmount(transaction)
                    )
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadTransactions()
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let formattedDate: String
    let formattedAmount: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.body.weight(.medium))

                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formattedAmount)
                .font(.body.weight(.semibold))
                .foregroundStyle(transaction.type == .credit ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}
