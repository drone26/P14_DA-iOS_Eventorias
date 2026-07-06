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
        TabView {
            NavigationStack {
                EventListView()
            }
            .tabItem {
                Label("Events", systemImage: "calendar")
            }
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
        .accentColor(Color(red: 0.85, green: 0.1, blue: 0.15))
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
