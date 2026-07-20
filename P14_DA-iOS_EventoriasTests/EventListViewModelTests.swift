//
//  EventListViewModelTests.swift
//  EventListViewModelTests
//
//  Created by Mathieu ARRIO on 09/07/2026.
//

import XCTest
@testable import P14_DA_iOS_Eventorias

@MainActor
class EventListViewModelTests: XCTestCase {
    var viewModel: EventListViewModel!
    var mockEventRepository: MockEventRepository!

    override func setUp() {
        super.setUp()
        mockEventRepository = MockEventRepository()
        viewModel = EventListViewModel(eventRepository: mockEventRepository)
    }

    func testFetchEvents_Success() async {
        // Given
        let expectedEvents = [
            Event(title: "Event 1", description: "Desc", date: Date(), address: "Address", creatorId: "user1"),
            Event(title: "Event 2", description: "Desc", date: Date(), address: "Address", creatorId: "user2")
        ]

        mockEventRepository.fetchResult = .success(expectedEvents)

        // When
        viewModel.fetchEvents()

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(viewModel.events.count, 2)
        XCTAssertEqual(viewModel.events.first?.title, "Event 1")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFetchEvents_Failure() async {
        // Given
        mockEventRepository.fetchResult = .failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))

        // When
        viewModel.fetchEvents()

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(viewModel.events.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testAddMockData() {
        // Given
        XCTAssertTrue(mockEventRepository.addedEvents.isEmpty)

        // When
        viewModel.addMockData()

        // Then
        XCTAssertEqual(mockEventRepository.addedEvents.count, 4)
    }

    func testInitialState() {
        // Given
        // A freshly initialized view model (see setUp).

        // When
        // No action is performed; the initial state is inspected directly.

        // Then
        XCTAssertEqual(viewModel.events.count, 0)
        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertEqual(viewModel.sortOption, .dateAsc)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
}
