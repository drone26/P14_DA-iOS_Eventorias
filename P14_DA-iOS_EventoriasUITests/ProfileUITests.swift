import XCTest

final class ProfileUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testProfile_StaticElements() throws {
        loginIfNeeded(app: app)
        
        // Wait for login to fully complete and UI to stabilize
        sleep(3)
        
        openProfileTab(app: app)
        
        // Verify static texts
        let nameText = app.staticTexts["Name"]
        XCTAssertTrue(nameText.waitForExistence(timeout: 15), "Name label should exist in profile view")
        XCTAssertTrue(nameText.exists, "Name text should exist after waiting")
        
        let emailText = app.staticTexts["E-mail"]
        XCTAssertTrue(emailText.waitForExistence(timeout: 5), "E-mail label should exist")
        XCTAssertTrue(emailText.exists, "E-mail text should exist after waiting")
        
        let notificationsText = app.staticTexts["Notifications"]
        XCTAssertTrue(notificationsText.waitForExistence(timeout: 5), "Notifications label should exist")
        XCTAssertTrue(notificationsText.exists, "Notifications text should exist after waiting")
        
        let emailLabel = app.staticTexts["profile_email_text"]
        XCTAssertTrue(emailLabel.waitForExistence(timeout: 5), "Email text value should exist")
        XCTAssertTrue(emailLabel.exists, "Email label should exist after waiting")
    }
    
    func testProfile_EditNameDismissKeyboardByTap() throws {
        loginIfNeeded(app: app)
        
        // Wait for login to fully complete and UI to stabilize
        sleep(3)
        
        openProfileTab(app: app)
        
        let nameField = app.textFields["profile_name_field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10), "Name field should exist")
        XCTAssertTrue(nameField.exists, "Name field should exist after waiting")
        nameField.tap()
        nameField.typeText(" Tapped")
        
        // Tap background to dismiss keyboard
        let background = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        background.tap()
        
        // Wait a moment for keyboard to dismiss
        sleep(1)
        
        // Keyboard should be gone (or at least focus lost)
        let signOutButton = app.buttons["sign_out_button"]
        XCTAssertTrue(signOutButton.exists, "Sign out button should be visible")
    }

    func testProfile_Flow() throws {
        loginIfNeeded(app: app)
        
        // Wait for login to fully complete and UI to stabilize
        sleep(3)
        
        openProfileTab(app: app)
        
        let nameField = app.textFields["profile_name_field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10), "Name field should exist")
        XCTAssertTrue(nameField.exists, "Name field should exist after waiting")
        nameField.tap()
        nameField.typeText(" Updated")
        
        let doneButton = app.keyboards.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        }
        
        let toggle = app.switches["profile_notifications_toggle"]
        if toggle.exists {
            toggle.tap()
            // Tap again to revert
            toggle.tap()
        }
        
        let signOutButton = app.buttons["sign_out_button"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 10), "Sign out button should exist")
        XCTAssertTrue(signOutButton.exists, "Sign out button should exist after waiting")
        sleep(1)
        signOutButton.tap()
        
        // Verify login screen shown
        let signInButton = app.buttons["sign_in_with_email_button"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Sign in button should appear after logout")
    }

    func testProfile_AvatarSelectionDialogAndPicker() throws {
        loginIfNeeded(app: app)
        
        // Wait for login to fully complete and UI to stabilize
        sleep(3)
        
        openProfileTab(app: app)
        
        // Open the avatar source dialog. isHittable is unreliable for elements while the app
        // isn't reporting "idle" (the events feed's animating spinner), so coordinate-tap the
        // avatar button and retry until the confirmation dialog appears.
        let avatarBtn = app.buttons["profile_avatar_button"]
        XCTAssertTrue(avatarBtn.waitForExistence(timeout: 15), "Avatar button should exist")
        
        let cameraOpt = app.buttons["Camera"]
        for _ in 1...6 {
            avatarBtn.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            if cameraOpt.waitForExistence(timeout: 3) { break }
        }
        
        // Verify confirmation dialog shows
        XCTAssertTrue(cameraOpt.exists, "Camera option should appear in dialog")
        
        let photoOpt = app.buttons["Photo Library"]
        XCTAssertTrue(photoOpt.exists, "Photo Library option should exist")
        
        // Tap Photo Library to open ImagePicker
        photoOpt.tap()
        
        // Image picker should appear (often has a Cancel button)
        let cancelBtn = app.buttons["Cancel"]
        if cancelBtn.waitForExistence(timeout: 10) {
            cancelBtn.tap()
        } else {
            // Swipe down to dismiss fullScreenCover if Cancel isn't found
            app.swipeDown()
            sleep(1)
        }
        
        // Verify we're back on profile view
        XCTAssertTrue(avatarBtn.waitForExistence(timeout: 10), "Avatar button should exist after dismissing picker")
        XCTAssertTrue(avatarBtn.exists, "Avatar button should exist after returning to profile")
    }
}

extension XCTestCase {
    /// Polls until the element becomes hittable or the timeout elapses.
    /// Returns the final hittable state, so it can be used directly in an assertion.
    @discardableResult
    func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 20) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.isHittable { return true }
            usleep(300_000) // 0.3s
        }
        return element.isHittable
    }

    /// Navigates to the Profile tab and waits until the profile view is actually shown.
    ///
    /// isHittable is unreliable for the tab bar because the events feed's animating spinner keeps
    /// the app from reporting "idle", so we coordinate-tap (which targets the button's screen point
    /// directly). Right after a fresh registration the tab bar is still animating in, so the tap can
    /// miss its transient frame — we retry until the always-present avatar button confirms the
    /// profile view appeared.
    func openProfileTab(app: XCUIApplication) {
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 15), "Profile tab should exist")

        let profileMarker = app.buttons["profile_avatar_button"]
        for _ in 1...6 {
            profileTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            if profileMarker.waitForExistence(timeout: 5) { return }
        }
        XCTFail("Profile view did not appear after tapping the Profile tab")
    }

    func loginIfNeeded(app: XCUIApplication) {
        let eventsTab = app.tabBars.buttons["Events"]
        if eventsTab.waitForExistence(timeout: 10) {
            return // Already logged in
        }
        
        let signInButton = app.buttons["sign_in_with_email_button"]
        if signInButton.waitForExistence(timeout: 10) {
            signInButton.tap()
            
            // Switch to Registration mode to ensure we get a fresh account
            // Wait for transition
            sleep(1)
            
            let toggleRegister = app.buttons["toggle_register_button"]
            if toggleRegister.waitForExistence(timeout: 10) {
                toggleRegister.tap()
            }
            
            let emailField = app.textFields["email_field"]
            XCTAssertTrue(emailField.waitForExistence(timeout: 10), "Email field should exist")
            XCTAssertTrue(emailField.exists, "Email field should exist after waiting")
            emailField.tap()
            
            // Use a random email to avoid collision
            let randomId = UUID().uuidString.prefix(8)
            emailField.typeText("test_\(randomId)@example.com")
            
            let passwordField = app.secureTextFields["password_field"]
            XCTAssertTrue(passwordField.exists, "Password field should exist")
            passwordField.tap()
            
            // Must be at least 20 chars, with upper, lower, number, and special char
            passwordField.typeText("SuperSecretP@ssword1234567890!")
            
            let doneButton = app.keyboards.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            } else {
                let returnButton = app.keyboards.buttons["return"]
                if returnButton.exists {
                    returnButton.tap()
                }
            }
            
            let authButton = app.buttons["authenticate_button"]
            XCTAssertTrue(authButton.exists, "Auth button should exist")
            authButton.tap()
            
            // Wait for login/registration to complete and tab bar to appear
            XCTAssertTrue(eventsTab.waitForExistence(timeout: 10), "Login failed! Events tab did not appear.")
        } else {
            XCTFail("Could not find either events_tab or sign_in_with_email_button")
        }
    }
}
