//
//  SignInView.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import SwiftUI
import FirebaseAuth

struct SignInView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color(red: 0.12, green: 0.12, blue: 0.14)
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // Custom logo composition using SF Symbols
                        ZStack {
                            Image("EventoriasLogo")
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Sign In Button
                    NavigationLink(destination: EmailSignInView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18))
                            
                            Text("Sign in with email")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.85, green: 0.1, blue: 0.15)) // Firebase red
                        .cornerRadius(4)
                    }
                    .accessibilityIdentifier("sign_in_with_email_button")
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    SignInView()
}
