//
//  SignInView.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @State private var showEmailSignIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    VStack(spacing: 20) {
                        // Custom logo composition using SF Symbols
                        ZStack {
                            Image(.eventoriasLogo)
                        }
                        .foregroundStyle(.white)
                    }

                    Spacer()

                    // Sign In Button
                    Button(action: { showEmailSignIn = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")

                            Text("Sign in with email")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent) // Firebase red
                        .clipShape(.rect(cornerRadius: 4))
                    }
                    .accessibilityIdentifier("sign_in_with_email_button")
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showEmailSignIn) {
                EmailSignInView()
            }
        }
    }
}

#Preview {
    SignInView()
}
