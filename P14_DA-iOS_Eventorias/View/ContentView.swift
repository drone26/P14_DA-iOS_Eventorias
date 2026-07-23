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
            Tab("Events", systemImage: "calendar") {
                NavigationStack {
                    EventListView()
                }
                .accessibilityIdentifier("events_tab")
            }

            Tab("Profile", systemImage: "person") {
                NavigationStack {
                    ProfileView()
                }
                .accessibilityIdentifier("profile_tab")
            }
        }
        .accentColor(AppTheme.accent)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
