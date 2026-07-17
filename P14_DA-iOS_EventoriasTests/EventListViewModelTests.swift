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
        let expectedEvents = [
            Event(title: "Event 1", description: "Desc", date: Date(), address: "Address", creatorId: "user1"),
            Event(title: "Event 2", description: "Desc", date: Date(), address: "Address", creatorId: "user2")
        ]
        
        mockEventRepository.fetchResult = .success(expectedEvents)
        
        viewModel.fetchEvents()
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(viewModel.events.count, 2)
        XCTAssertEqual(viewModel.events.first?.title, "Event 1")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testFetchEvents_Failure() async {
        mockEventRepository.fetchResult = .failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
        
        viewModel.fetchEvents()
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertTrue(viewModel.events.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testAddMockData() {
        XCTAssertTrue(mockEventRepository.addedEvents.isEmpty)
        
        viewModel.addMockData()
        
        XCTAssertEqual(mockEventRepository.addedEvents.count, 4)
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.events.count, 0)
        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertEqual(viewModel.sortOption, .dateAsc)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
}
