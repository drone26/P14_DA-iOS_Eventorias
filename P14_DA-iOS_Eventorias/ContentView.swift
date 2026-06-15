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
            NavigationView {
                EventListView()
            }
            .tabItem {
                Label("Events", systemImage: "calendar")
            }
            
            NavigationView {
                // Espace réservé pour la vue Profil (ne pas créer de fichier comme demandé)
                ZStack {
                    Color(red: 0.12, green: 0.12, blue: 0.14).ignoresSafeArea()
                    Text("Vue Profil (À venir)")
                        .foregroundColor(.white)
                }
                .navigationTitle("Profile")
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
