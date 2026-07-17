//
//  P14_DA_iOS_EventoriasApp.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 11/06/2026.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase is now configured in the App init to ensure it happens before AuthManager initialization.
        return true
    }
}

@main
struct YourApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var authManager: AuthManager

    init() {
        FirebaseApp.configure()
        _authManager = State(wrappedValue: AuthManager())
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                if authManager.isAuthenticated {
                    ContentView()
                        .environment(authManager)
                } else {
                    SignInView()
                }
            }
        }
    }
}
