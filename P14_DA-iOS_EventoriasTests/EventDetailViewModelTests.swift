//
//  EventDetailViewModelTests.swift
//  P14_DA-iOS_EventoriasTests
//

import XCTest
@testable import P14_DA_iOS_Eventorias

@MainActor
final class EventDetailViewModelTests: XCTestCase {
    var viewModel: EventDetailViewModel!
    var mockEventRepository: MockEventRepository!
    var mockStorageService: MockImageStorageService!
    
    override func setUp() {
        super.setUp()
        mockEventRepository = MockEventRepository()
        mockStorageService = MockImageStorageService()
        viewModel = EventDetailViewModel(eventRepository: mockEventRepository,
                                         storageService: mockStorageService)
    }
    
    private func makeEvent(id: String? = "event123", imageUrl: String? = nil) -> Event {
        Event(id: id, title: "T", description: "D", date: Date(),
              address: "A", creatorId: "u", coverImageUrl: imageUrl)
    }
    
    func testDeleteEvent_NoIdentifier() {
        let expectation = XCTestExpectation(description: "completion")
        viewModel.deleteEvent(makeEvent(id: nil)) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.errorMessage, "Cannot delete an event without an identifier.")
        XCTAssertFalse(viewModel.isDeleting)
        XCTAssertTrue(mockEventRepository.deletedEvents.isEmpty)
    }
    
    func testDeleteEvent_Success_WithoutImage() async {
        mockEventRepository.deleteResult = nil
        
        let expectation = XCTestExpectation(description: "completion")
        viewModel.deleteEvent(makeEvent(imageUrl: nil)) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(mockEventRepository.deletedEvents.count, 1)
        XCTAssertNil(mockStorageService.deletedImageUrl) // nothing to clean up
        XCTAssertFalse(viewModel.isDeleting)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testDeleteEvent_Success_WithImage_CleansUpImage() async {
        mockEventRepository.deleteResult = nil
        mockStorageService.deleteResult = nil
        
        let expectation = XCTestExpectation(description: "completion")
        viewModel.deleteEvent(makeEvent(imageUrl: "https://example.com/cover.jpg")) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(mockStorageService.deletedImageUrl, "https://example.com/cover.jpg")
    }
    
    func testDeleteEvent_Failure() async {
        mockEventRepository.deleteResult = NSError(domain: "", code: -1,
                                                   userInfo: [NSLocalizedDescriptionKey: "DB error"])
        
        let expectation = XCTestExpectation(description: "completion")
        viewModel.deleteEvent(makeEvent()) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.errorMessage, "Failed to delete event: DB error")
        XCTAssertFalse(viewModel.isDeleting)
        XCTAssertNil(mockStorageService.deletedImageUrl) // cleanup not reached on failure
    }
}
