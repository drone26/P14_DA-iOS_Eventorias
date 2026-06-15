//
//  ContentView.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 11/06/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) var authManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            Button("Sign Out") {
                authManager.signOut()
            }
            .foregroundColor(.red)
            .padding(.top, 40)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
