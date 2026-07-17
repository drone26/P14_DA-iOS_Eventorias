import XCTest

final class EventListUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Launched per-test so we can pass launch arguments.
    }

    private func goToEventsTab() {
        loginIfNeeded(app: app)
        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 15), "Events tab should exist")
        eventsTab.tap()
        sleep(1)
    }

    func testEventList_ErrorStateAndRetry() throws {
        // Force the feed fetch to fail so the ErrorStateView renders.
        app.launchArguments = ["-UITestForceEventLoadError"]
        app.launch()
        goToEventsTab()

        XCTAssertTrue(app.staticTexts["Error"].waitForExistence(timeout: 15), "Error title should appear")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'error has occured'")).firstMatch.exists,
                      "Error message should appear")

        var retry = app.buttons["error_retry_button"]
        if !retry.waitForExistence(timeout: 10) {
            retry = app.buttons["Try again"] // XCUITest may surface it by label
        }
        XCTAssertTrue(retry.waitForExistence(timeout: 10), "Retry button should exist")
        XCTAssertTrue(waitForHittable(retry), "Retry button should be hittable")
        retry.tap()

        // Retry re-runs the (still failing) fetch, so we remain in the error state.
        XCTAssertTrue(app.staticTexts["Error"].waitForExistence(timeout: 10), "Error state should remain after retry")
    }

    func testEventList_EmptyState() throws {
        app.launch()
        goToEventsTab()

        let searchBar = app.searchFields.firstMatch
        XCTAssertTrue(searchBar.waitForExistence(timeout: 15), "Search field should exist")
        searchBar.tap()
        searchBar.typeText("zzq-no-such-event-xyz-98765")
        sleep(3) // let the filtered fetch complete

        XCTAssertTrue(app.staticTexts["Aucun événement trouvé."].waitForExistence(timeout: 15),
                      "Empty state should appear when no events match")
    }

    func testEventList_SortOptions() throws {
        app.launch()
        goToEventsTab()

        // Selecting each sort option exercises the menu item actions (and the checkmark).
        for option in ["Date (Éloigné)", "Titre (A-Z)", "Date (Proche)"] {
            let sortMenu = app.buttons["sort_menu"]
            XCTAssertTrue(sortMenu.waitForExistence(timeout: 10), "Sort menu should exist")
            XCTAssertTrue(waitForHittable(sortMenu), "Sort menu should be hittable")
            sortMenu.tap()

            let item = app.buttons[option]
            XCTAssertTrue(item.waitForExistence(timeout: 5), "\(option) menu item should appear")
            item.tap()
            sleep(1)
        }
    }
}
