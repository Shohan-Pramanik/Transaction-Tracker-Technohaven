import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var container: DIContainer
    @State private var authenticatedUser: User?
    @State private var isLoggedIn = false

    var body: some View {
        Group {
            if isLoggedIn, let user = authenticatedUser {
                HomeView(
                    viewModel: container.makeHomeViewModel(user: user),
                    onLogout: {
                        withAnimation {
                            isLoggedIn = false
                            authenticatedUser = nil
                        }
                    }
                )
            } else {
                LoginView(
                    viewModel: container.makeLoginViewModel(),
                    onLoginSuccess: { user in
                        withAnimation {
                            authenticatedUser = user
                            isLoggedIn = true
                        }
                    }
                )
            }
        }
    }
}
