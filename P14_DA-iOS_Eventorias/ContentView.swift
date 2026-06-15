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
        EventListView()
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
