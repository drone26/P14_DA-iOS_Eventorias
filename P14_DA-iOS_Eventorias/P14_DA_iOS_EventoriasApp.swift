//
//  P14_DA_iOS_EventoriasApp.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 11/06/2026.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase
import FirebaseStorage

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
        
        if CommandLine.arguments.contains("-UseFirebaseEmulator") {
            Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
            
            let settings = Firestore.firestore().settings
            settings.host = "127.0.0.1:8080"
            settings.cacheSettings = MemoryCacheSettings()
            settings.isSSLEnabled = false
            Firestore.firestore().settings = settings
            
            Database.database().useEmulator(withHost: "127.0.0.1", port: 9000)
            
            Storage.storage().useEmulator(withHost: "127.0.0.1", port: 9199)
        }
        
        _authManager = State(wrappedValue: AuthManager())
    }

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environment(authManager)
            } else {
                SignInView()
            }
        }
    }
}
