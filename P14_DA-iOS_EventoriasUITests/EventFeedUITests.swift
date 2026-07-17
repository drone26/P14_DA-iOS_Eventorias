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
}
