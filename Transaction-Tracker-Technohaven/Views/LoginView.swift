import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel
    var onLoginSuccess: (User) -> Void

    init(viewModel: LoginViewModel, onLoginSuccess: @escaping (User) -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.onLoginSuccess = onLoginSuccess
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // App Logo
                VStack(spacing: 8) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Transaction Tracker")
                        .font(.title.bold())

                    Text("Technohaven")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Form Fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email / User ID")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("Enter your email", text: $viewModel.email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password / PIN")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        SecureField("Enter your password", text: $viewModel.password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)
                    }
                }

                // Error Message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Login Button
                Button {
                    Task {
                        await viewModel.login()
                        if viewModel.isAuthenticated, let user = viewModel.authenticatedUser {
                            onLoginSuccess(user)
                        }
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else {
                        Text("Login")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)

                // Biometric Login
                if viewModel.isBiometricAvailable {
                    Button {
                        Task {
                            await viewModel.loginWithBiometrics()
                            if viewModel.isAuthenticated, let user = viewModel.authenticatedUser {
                                onLoginSuccess(user)
                            }
                        }
                    } label: {
                        Label("Login with Face ID", systemImage: "faceid")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.checkExistingSession()
            }
        }
    }
}
