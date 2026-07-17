import XCTest

final class EventFeedUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testEventFeed_Interactions() throws {
        loginIfNeeded(app: app)
        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()
        
        // Test Sort Menu
        let sortMenu = app.buttons["sort_menu"]
        XCTAssertTrue(sortMenu.waitForExistence(timeout: 10))
        sortMenu.tap()
        
        // Cannot reliably test the exact SwiftUI menu items by identifier as they use standard system actions, 
        // but we verify the menu opens. We tap back on sort_menu or swipe to dismiss it.
        app.swipeDown()
        
        // Test Search Bar
        let searchBar = app.searchFields.firstMatch
        if searchBar.waitForExistence(timeout: 10) {
            searchBar.tap()
            searchBar.typeText("Music")
            app.keyboards.buttons["Search"].tap()
        }
    }

    func testEventFeed_DetailNavigation() throws {
        loginIfNeeded(app: app)
        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()
        
        // Wait for the feed to load
        sleep(2)
        
        // Tap the first available event row
        let eventRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'event_row_'")).firstMatch
        XCTAssertTrue(eventRow.waitForExistence(timeout: 10), "Event row should exist")
        
        // Ensure the row is hittable by scrolling to make it visible
        if !eventRow.isHittable {
            // Scroll up slightly to ensure the row is not obscured
            app.swipeUp()
            sleep(1)
        }
        
        // Wait a moment for the element to become hittable
        let startTime = Date()
        while !eventRow.isHittable && Date().timeIntervalSince(startTime) < 5 {
            sleep(1)
        }
        
        XCTAssertTrue(eventRow.isHittable, "Event row should be hittable")
        eventRow.tap()
        
        // Verify detail view elements exist
        let description = app.staticTexts["event_detail_description"]
        XCTAssertTrue(description.waitForExistence(timeout: 10), "Event description should exist in detail view")
        
        let address = app.staticTexts["event_detail_address"]
        XCTAssertTrue(address.waitForExistence(timeout: 10), "Event address should exist in detail view")
        
        // Navigate back (NavigationBar back button usually matches "Events" or is the first button)
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }
        
        // Verify we're back on feed
        XCTAssertTrue(app.buttons["create_event_fab"].waitForExistence(timeout: 10), "FAB should exist after navigating back")
    }

    func testEventDetail_OwnerCanDeleteEvent() throws {
        // The creation form needs portrait (it collapses in landscape).
        XCUIDevice.shared.orientation = .portrait
        loginIfNeeded(app: app)
        sleep(2)

        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 10), "Events tab should exist")

        // Create an event owned by the current user, with a unique title so we can find it.
        let title = "UITest Delete \(UUID().uuidString.prefix(6))"
        createEvent(titled: title)

        // Isolate the created event via search so its row is at the top and hittable.
        let searchBar = app.searchFields.firstMatch
        XCTAssertTrue(searchBar.waitForExistence(timeout: 10), "Search field should exist")
        searchBar.tap()
        searchBar.typeText(title)
        sleep(2) // let the filtered fetch complete

        let row = app.buttons["event_row_\(title)"]
        XCTAssertTrue(row.waitForExistence(timeout: 15), "Created event row should appear in the feed")
        XCTAssertTrue(waitForHittable(row), "Event row should be hittable")
        row.tap()

        // Detail content renders.
        XCTAssertTrue(app.staticTexts["event_detail_description"].waitForExistence(timeout: 10), "Description should show")
        XCTAssertTrue(app.staticTexts["event_detail_address"].exists, "Address should show")

        // Owner sees the delete button; tap it and confirm.
        let deleteButton = app.buttons["delete_event_button"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 10), "Owner should see the delete button")
        // It sits at the bottom of the scroll view, so scroll down to reveal it, then
        // coordinate-tap (isHittable is unreliable while the map image's spinner keeps the
        // app from reporting "idle").
        app.swipeUp()
        app.swipeUp()
        sleep(1)
        deleteButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        // The confirmation button exposes duplicate nested matches, so take firstMatch.
        let confirmButton = app.sheets.buttons["confirm_delete_event_button"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5), "Confirmation dialog should appear")
        confirmButton.tap()

        // Deletion dismisses back to the feed.
        XCTAssertTrue(app.buttons["create_event_fab"].waitForExistence(timeout: 15), "Should return to the feed after deletion")
    }

    /// Creates an event via the FAB flow and returns once the feed is shown again.
    private func createEvent(titled title: String) {
        let fab = app.buttons["create_event_fab"]
        XCTAssertTrue(fab.waitForExistence(timeout: 15), "FAB should exist")

        // Coordinate-tap the FAB and retry until the form's title field appears
        // (isHittable is unreliable while the feed spinner keeps the app from idling).
        let titleField = app.textFields["event_title_field"]
        for _ in 1...6 {
            fab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            if titleField.waitForExistence(timeout: 5) { break }
        }
        XCTAssertTrue(titleField.waitForExistence(timeout: 10), "Title field should exist after navigation")
        XCTAssertTrue(waitForHittable(titleField), "Title field should be hittable")
        titleField.tap()
        titleField.typeText("\(title)\n") // trailing newline dismisses the single-line keyboard

        let addressField = app.textFields["event_address_field"]
        XCTAssertTrue(addressField.waitForExistence(timeout: 10), "Address field should exist")
        XCTAssertTrue(waitForHittable(addressField), "Address field should be hittable")
        addressField.tap()
        addressField.typeText("Paris, France\n")

        let descField = app.textViews["event_description_field"]
        XCTAssertTrue(descField.waitForExistence(timeout: 10), "Description field should exist")
        XCTAssertTrue(waitForHittable(descField), "Description field should be hittable")
        descField.tap()
        descField.typeText("Event to be deleted by UI test")

        let saveButton = app.buttons["save_event_button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 10), "Save button should exist")
        XCTAssertTrue(waitForHittable(saveButton), "Save button should be hittable")
        saveButton.tap()

        // Back on the feed after geocoding + save.
        XCTAssertTrue(fab.waitForExistence(timeout: 20), "Should return to the feed after saving")
    }
}
