import SwiftUI

struct EmailSignInView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var viewModel = EmailSignInViewModel()
    
    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.12, blue: 0.14)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text(viewModel.isRegistering ? "Create Account" : "Sign In")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                VStack(spacing: 16) {
                    TextField("", text: $viewModel.email, prompt: Text("Email").foregroundColor(.white.opacity(0.6)))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(white: 0.2))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .accentColor(.red)
                    
                    SecureField("", text: $viewModel.password, prompt: Text("Password").foregroundColor(.white.opacity(0.6)))
                        .padding()
                        .background(Color(white: 0.2))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .accentColor(.red)
                }
                .padding(.horizontal, 24)
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Button(action: {
                    viewModel.authenticate()
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(viewModel.isRegistering ? "Sign Up" : "Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(red: 0.85, green: 0.1, blue: 0.15))
                .cornerRadius(4)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
                
                Button(action: {
                    viewModel.toggleRegistering()
                }) {
                    Text(viewModel.isRegistering ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .padding(.top, 16)
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    EmailSignInView()
}
