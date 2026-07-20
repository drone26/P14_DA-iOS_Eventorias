import XCTest

final class EventCreationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-UseFirebaseEmulator")
        app.launch()
        // The event creation form lives in a ScrollView that collapses to a ~90px viewport in
        // landscape, pushing fields and the Save button off-screen. Force portrait so the form
        // is usable regardless of the simulator's saved orientation.
        XCUIDevice.shared.orientation = .portrait
    }

    func testCreateEvent_FormFilling() throws {
        loginIfNeeded(app: app)
        
        // Wait for UI to stabilize after login
        sleep(2)
        
        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5), "Events tab should exist")
        
        // The events feed's animating spinner can keep the app from reporting "idle", which makes
        // isHittable a false negative for the FAB. Coordinate-tap it (targets the button's screen
        // point directly) and retry until the creation form's title field appears.
        let fab = app.buttons["create_event_fab"]
        XCTAssertTrue(fab.waitForExistence(timeout: 15), "FAB should exist")
        
        let titleField = app.textFields["event_title_field"]
        for _ in 1...6 {
            fab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            if titleField.waitForExistence(timeout: 5) { break }
        }
        XCTAssertTrue(titleField.waitForExistence(timeout: 10), "Title field should exist after navigation")
        XCTAssertTrue(waitForHittable(titleField), "Title field should be hittable")
        titleField.tap()
        // A trailing newline submits this single-line field and dismisses its keyboard.
        titleField.typeText("New Test Event\n")
        
        // Fill the address before the description. The address is a single-line field whose
        // keyboard can be dismissed with a newline; the description is a multi-line TextEditor
        // whose keyboard has no dismiss key and would otherwise cover the fields below it.
        // The address must also be geocodable, or createEvent() fails and never dismisses.
        let addressField = app.textFields["event_address_field"]
        XCTAssertTrue(addressField.waitForExistence(timeout: 10), "Address field should exist")
        XCTAssertTrue(waitForHittable(addressField), "Address field should be hittable")
        addressField.tap()
        addressField.typeText("Paris, France\n")
        
        // Fill the description last. Its keyboard stays up, but SwiftUI's keyboard avoidance
        // keeps the Save button (below the ScrollView) reachable above the keyboard.
        let descField = app.textViews["event_description_field"]
        XCTAssertTrue(descField.waitForExistence(timeout: 10), "Description field should exist")
        XCTAssertTrue(waitForHittable(descField), "Description field should be hittable")
        descField.tap()
        descField.typeText("This is a test event description")
        
        let saveButton = app.buttons["save_event_button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 10), "Save button should exist")
        XCTAssertTrue(waitForHittable(saveButton), "Save button should be hittable")
        
        saveButton.tap()
        
        // Wait for geocoding + save to complete and verify we're back on events list
        XCTAssertTrue(fab.waitForExistence(timeout: 20), "Should return to events list after save")
    }

    func testCreateEvent_MediaPickersAndEmptyValidation() throws {
        loginIfNeeded(app: app)
        
        // Wait for UI to stabilize after login
        sleep(2)
        
        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5), "Events tab should exist")
        
        let fab = app.buttons["create_event_fab"]
        XCTAssertTrue(fab.waitForExistence(timeout: 10), "FAB should exist")
        XCTAssertTrue(waitForHittable(fab), "FAB should be hittable")
        fab.tap()
        
        // Wait for the push transition to finish
        sleep(2)
        
        // Verify both media picker buttons are present and interactive. We do NOT open the
        // camera: the simulator has no camera device, so its picker gets stuck with no dismiss
        // control, which would leave an invisible cover over the form and hang the test.
        let cameraBtn = app.buttons["camera_button"]
        XCTAssertTrue(cameraBtn.waitForExistence(timeout: 10), "Camera button should exist")
        XCTAssertTrue(waitForHittable(cameraBtn), "Camera button should be hittable")
        
        let photoBtn = app.buttons["photo_library_button"]
        XCTAssertTrue(photoBtn.waitForExistence(timeout: 10), "Photo library button should exist")
        XCTAssertTrue(waitForHittable(photoBtn), "Photo library button should be hittable")
        
        // Empty-form validation: saving with no fields filled must keep us on the creation view.
        let saveButton = app.buttons["save_event_button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 10), "Save button should exist")
        XCTAssertTrue(waitForHittable(saveButton), "Save button should be hittable")
        saveButton.tap()
        
        // Wait a moment for validation
        sleep(1)
        
        // Should not dismiss because fields are empty, view should remain
        XCTAssertTrue(cameraBtn.exists, "Should still be on creation view after validation fails")
    }
}
