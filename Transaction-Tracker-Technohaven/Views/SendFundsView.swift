import SwiftUI

struct SendFundsView: View {
    @State var viewModel: SendFundsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Balance Display
            VStack(spacing: 4) {
                Text("Available Balance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(viewModel.formattedBalance)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Form Fields
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Receiver ID")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("Enter receiver ID", text: $viewModel.receiverId)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Amount")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("Enter amount", text: $viewModel.amountText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }
            }

            // Error Message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // Send Button
            Button {
                Task { await viewModel.sendFunds() }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    Text("Send Funds")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(viewModel.isLoading || viewModel.receiverId.isEmpty || viewModel.amountText.isEmpty)

            Spacer()
        }
        .padding()
        .navigationTitle("Send Funds")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Transfer Successful", isPresented: $viewModel.showConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(viewModel.successMessage ?? "Funds transferred successfully.")
        }
    }
}
