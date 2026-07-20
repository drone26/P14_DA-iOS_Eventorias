import XCTest

final class LoginUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-UseFirebaseEmulator")
        app.launch()
        
        let eventsTab = app.tabBars.buttons["Events"]
        if eventsTab.waitForExistence(timeout: 10) {
            sleep(2) // Wait for layout to settle
            let profileTab = app.tabBars.buttons["Profile"]
            if profileTab.exists {
                profileTab.tap()
                
                // Wait for profile to load
                sleep(2)
                
                let signOutButton = app.buttons["sign_out_button"]
                if signOutButton.waitForExistence(timeout: 15) {
                    sleep(1)
                    signOutButton.tap()
                    
                    // Wait for logout to complete
                    sleep(2)
                }
            }
        }
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testEmailLogin_Flow() throws {
        let signInButton = app.buttons["sign_in_with_email_button"]
        if !signInButton.waitForExistence(timeout: 10) {
            // Already logged in, logout first
            let profileTab = app.tabBars.buttons["Profile"]
            if profileTab.waitForExistence(timeout: 10) {
                sleep(2) // Wait for layout to settle
                profileTab.tap()
                
                // Wait for profile to load
                sleep(2)
                
                let signOutButton = app.buttons["sign_out_button"]
                if signOutButton.waitForExistence(timeout: 15) {
                    sleep(1)
                    signOutButton.tap()
                    
                    // Wait for logout to complete
                    sleep(2)
                }
            }
        }
        
        let randomEmail = "user\(UUID().uuidString.prefix(8))@example.com"
        let validPassword = "SuperSecretP@ssword1234567890!"
        
        // 1. Register first
        XCTAssertTrue(signInButton.waitForExistence(timeout: 10), "Sign in button should exist")
        signInButton.tap()
        
        // Wait for the push transition to finish
        sleep(1)
        
        let toggleRegister = app.buttons["toggle_register_button"]
        XCTAssertTrue(toggleRegister.waitForExistence(timeout: 10))
        toggleRegister.tap() // Switch to Register
        
        let emailField = app.textFields["email_field"]
        emailField.tap()
        emailField.typeText(randomEmail)
        
        let passwordField = app.secureTextFields["password_field"]
        passwordField.tap()
        passwordField.typeText(validPassword)
        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        } else if app.keyboards.buttons["return"].exists {
            app.keyboards.buttons["return"].tap()
        }
        
        let authButton = app.buttons["authenticate_button"]
        authButton.tap()
        
        // Wait for registration/login to complete (events tab should appear)
        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 10), "Login failed! Events tab did not appear.")
        
        // Wait for the navigation animation and view hierarchy to fully stabilize
        sleep(5)  // Increased from 3 to 5 seconds
        
        // Dismiss keyboard if still present
        if app.keyboards.count > 0 {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
            sleep(1)
        }
        
        // Verify the events tab is actually selected and the view is settled
        XCTAssertTrue(eventsTab.exists, "Events tab should exist")
        
        // Additional wait to ensure tab bar is fully interactive
        sleep(3)
        
        // 2. Log out
        // Try multiple strategies to access the profile tab
        var profileTabTapped = false
        let maxStrategies = 3
        
        for strategy in 1...maxStrategies {
            print("Attempting strategy \(strategy) to tap profile tab...")
            
            if strategy == 1 {
                // Strategy 1: Standard approach with polling
                let profileTab = app.tabBars.buttons["Profile"]
                
                if profileTab.waitForExistence(timeout: 5) {
                    // Wait for it to become hittable
                    for attempt in 1...10 {
                        if profileTab.isHittable {
                            print("Profile tab is hittable on attempt \(attempt)")
                            profileTab.tap()
                            profileTabTapped = true
                            break
                        }
                        print("Attempt \(attempt)/10: Profile tab not hittable, waiting...")
                        sleep(1)
                    }
                }
                
                if profileTabTapped {
                    break
                }
            } else if strategy == 2 {
                // Strategy 2: Try tapping by coordinate
                print("Strategy 2: Attempting coordinate tap...")
                let tabBar = app.tabBars.firstMatch
                if tabBar.exists {
                    // Profile tab is typically the rightmost tab
                    let coordinate = tabBar.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
                    coordinate.tap()
                    sleep(2)
                    
                    // Check if we're now on the profile view
                    if app.buttons["sign_out_button"].waitForExistence(timeout: 3) {
                        profileTabTapped = true
                        print("Successfully navigated to profile via coordinate tap")
                        break
                    }
                }
            } else if strategy == 3 {
                // Strategy 3: Try using the tab bar item directly
                print("Strategy 3: Trying alternative query...")
                let tabs = app.tabBars.buttons
                let profileCount = tabs.matching(identifier: "Profile").count
                
                if profileCount > 0 {
                    let profileTab = tabs["Profile"]
                    sleep(2)
                    profileTab.tap()
                    sleep(2)
                    
                    if app.buttons["sign_out_button"].waitForExistence(timeout: 3) {
                        profileTabTapped = true
                        print("Successfully navigated to profile via alternative query")
                        break
                    }
                }
            }
            
            print("Strategy \(strategy) failed, trying next approach...")
            sleep(1)
        }
        
        XCTAssertTrue(profileTabTapped, "Should be able to tap profile tab using one of the strategies")
        
        // Wait for profile view to fully appear and load
        sleep(3)
        
        // Try to find the sign out button with multiple attempts
        let signOutButton = app.buttons["sign_out_button"]
        var buttonFound = false
        let maxAttempts = 5
        
        for attempt in 1...maxAttempts {
            if signOutButton.exists && signOutButton.isHittable {
                buttonFound = true
                break
            }
            print("Attempt \(attempt)/\(maxAttempts): Sign out button not ready, waiting...")
            sleep(2)
        }
        
        XCTAssertTrue(buttonFound, "Sign out button should exist and be hittable after profile loads")
        XCTAssertTrue(signOutButton.exists, "Sign out button should exist")
        XCTAssertTrue(signOutButton.isHittable, "Sign out button should be hittable")
        
        signOutButton.tap()
        
        // Wait for logout animation to complete
        sleep(2)
        
        // 3. Test Login
        XCTAssertTrue(signInButton.waitForExistence(timeout: 10))
        signInButton.tap()
        
        // Wait for the push transition to finish
        sleep(1)
        
        XCTAssertTrue(emailField.waitForExistence(timeout: 10))
        emailField.tap()
        emailField.typeText(randomEmail)
        
        passwordField.tap()
        passwordField.typeText(validPassword)
        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        } else if app.keyboards.buttons["return"].exists {
            app.keyboards.buttons["return"].tap()
        }
        
        app.buttons["authenticate_button"].tap()
        
        // Verify we navigate to events list again
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 10))
    }

    func testEmailLogin_RegistrationFlow() throws {
        let signInButton = app.buttons["sign_in_with_email_button"]
        if !signInButton.waitForExistence(timeout: 10) {
            let profileTab = app.tabBars.buttons["Profile"]
            if profileTab.waitForExistence(timeout: 10) {
                sleep(1)
                profileTab.tap()
                sleep(3)
                
                let signOutButton = app.buttons["sign_out_button"]
                if signOutButton.waitForExistence(timeout: 15) {
                    sleep(1)
                    signOutButton.tap()
                    sleep(2)
                }
            }
        }
        
        XCTAssertTrue(signInButton.waitForExistence(timeout: 10))
        signInButton.tap()
        
        let toggleRegister = app.buttons["toggle_register_button"]
        XCTAssertTrue(toggleRegister.waitForExistence(timeout: 10))
        toggleRegister.tap()
        
        let emailField = app.textFields["email_field"]
        emailField.tap()
        emailField.typeText("newuser@example.com")
        
        let passwordField = app.secureTextFields["password_field"]
        passwordField.tap()
        passwordField.typeText("SuperSecretP@ssword1234567890!")
        
        
        
        let authButton = app.buttons["authenticate_button"]
        XCTAssertTrue(authButton.isEnabled)
    }

    func testEmailLogin_EmptyFieldsDisableButton() throws {
        let signInButton = app.buttons["sign_in_with_email_button"]
        if !signInButton.waitForExistence(timeout: 10) {
            let profileTab = app.tabBars.buttons["Profile"]
            if profileTab.waitForExistence(timeout: 10) {
                sleep(1)
                profileTab.tap()
                sleep(3)
                
                let signOutButton = app.buttons["sign_out_button"]
                if signOutButton.waitForExistence(timeout: 15) {
                    sleep(1)
                    signOutButton.tap()
                    sleep(2)
                }
            }
        }
        
        XCTAssertTrue(signInButton.waitForExistence(timeout: 10))
        signInButton.tap()
        
        let authButton = app.buttons["authenticate_button"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 10))
        
        // Both fields are initially empty, so the button should be disabled
        XCTAssertFalse(authButton.isEnabled)
    }

    func testEmailLogin_ErrorState_WeakPassword() throws {
        let signInButton = app.buttons["sign_in_with_email_button"]
        if !signInButton.waitForExistence(timeout: 5) {
            let profileTab = app.tabBars.buttons["Profile"]
            if profileTab.waitForExistence(timeout: 5) {
                sleep(1)
                profileTab.tap()
                sleep(2)
                
                let signOutButton = app.buttons["sign_out_button"]
                if signOutButton.waitForExistence(timeout: 10) {
                    sleep(1)
                    signOutButton.tap()
                    sleep(2)
                }
            }
        }
        
        XCTAssertTrue(signInButton.waitForExistence(timeout: 10))
        signInButton.tap()
        sleep(1)
        
        let toggleRegister = app.buttons["toggle_register_button"]
        XCTAssertTrue(toggleRegister.waitForExistence(timeout: 10))
        toggleRegister.tap() // Switch to Register
        
        let emailField = app.textFields["email_field"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let passwordField = app.secureTextFields["password_field"]
        passwordField.tap()
        passwordField.typeText("short")
        
        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        } else if app.keyboards.buttons["return"].exists {
            app.keyboards.buttons["return"].tap()
        }
        
        app.buttons["authenticate_button"].tap()
        
        let errorText = app.staticTexts["error_message_text"]
        XCTAssertTrue(errorText.waitForExistence(timeout: 5))
        XCTAssertTrue(errorText.label.contains("au moins 20 caractères") || errorText.label.contains("too weak"))
    }

    func testEmailLogin_ErrorState_InvalidCredentials() throws {
        let signInButton = app.buttons["sign_in_with_email_button"]
        if !signInButton.waitForExistence(timeout: 5) {
            let profileTab = app.tabBars.buttons["Profile"]
            if profileTab.waitForExistence(timeout: 5) {
                sleep(1)
                profileTab.tap()
                sleep(2)
                
                let signOutButton = app.buttons["sign_out_button"]
                if signOutButton.waitForExistence(timeout: 10) {
                    sleep(1)
                    signOutButton.tap()
                    sleep(2)
                }
            }
        }
        
        XCTAssertTrue(signInButton.waitForExistence(timeout: 10))
        signInButton.tap()
        sleep(1)
        
        let emailField = app.textFields["email_field"]
        emailField.tap()
        emailField.typeText("nonexistentuser12345@example.com")
        
        let passwordField = app.secureTextFields["password_field"]
        passwordField.tap()
        passwordField.typeText("WrongPassword123!")
        
        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        } else if app.keyboards.buttons["return"].exists {
            app.keyboards.buttons["return"].tap()
        }
        
        app.buttons["authenticate_button"].tap()
        
        let errorText = app.staticTexts["error_message_text"]
        XCTAssertTrue(errorText.waitForExistence(timeout: 10))
    }
}
