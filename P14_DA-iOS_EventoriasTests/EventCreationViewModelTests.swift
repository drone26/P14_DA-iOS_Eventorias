//
//  EventCreationViewModelTests.swift
//  EventCreationViewModelTests
//
//  Created by Mathieu ARRIO on 09/07/2026.
//

import XCTest
import UIKit
@testable import P14_DA_iOS_Eventorias

@MainActor
class EventCreationViewModelTests: XCTestCase {
    var viewModel: EventCreationViewModel!
    var mockEventRepository: MockEventRepository!
    var mockStorageService: MockImageStorageService!
    var mockGeocodingService: MockGeocodingService!
    
    override func setUp() {
        super.setUp()
        mockEventRepository = MockEventRepository()
        mockStorageService = MockImageStorageService()
        mockGeocodingService = MockGeocodingService()
        viewModel = EventCreationViewModel(eventRepository: mockEventRepository, storageService: mockStorageService, geocodingService: mockGeocodingService)
    }
    
    func testCreateEvent_EmptyFields() {
        let authManager = AuthManager(authService: MockAuthService())
        
        viewModel.title = ""
        viewModel.description = ""
        viewModel.address = ""
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        viewModel.createEvent(authManager: authManager) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.errorMessage, "Please fill in all fields.")
    }
    
    func testCreateEvent_UserNotLoggedIn() {
        let authManager = AuthManager(authService: MockAuthService(currentAppUser: nil))
        
        viewModel.title = "Test Title"
        viewModel.description = "Test Description"
        viewModel.address = "123 Test Ave"
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        viewModel.createEvent(authManager: authManager) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.errorMessage, "User not logged in.")
    }
    
    func testCreateEvent_GeocodingFailure() async {
        let authManager = AuthManager(authService: MockAuthService(currentAppUser: MockAppUser(uid: "user123")))
        
        viewModel.title = "Test Title"
        viewModel.description = "Test Description"
        viewModel.address = "Invalid"
        
        mockGeocodingService.validateAddressResult = .failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        viewModel.createEvent(authManager: authManager) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.errorMessage, "Address not found: Network error")
    }
    
    func testCreateEvent_GeocodingNotFound() async {
        let authManager = AuthManager(authService: MockAuthService(currentAppUser: MockAppUser(uid: "user123")))
        
        viewModel.title = "Test Title"
        viewModel.description = "Test Description"
        viewModel.address = "Invalid"
        
        mockGeocodingService.validateAddressResult = .success(nil)
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        viewModel.createEvent(authManager: authManager) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.errorMessage, "Could not validate address.")
    }
    
    func testCreateEvent_Success_WithoutImage() async {
        let authManager = AuthManager(authService: MockAuthService(currentAppUser: MockAppUser(uid: "user123")))
        
        viewModel.title = "Test Title"
        viewModel.description = "Test Description"
        viewModel.address = "Valid Address"
        
        mockGeocodingService.validateAddressResult = .success("Validated Address")
        mockEventRepository.addResult = nil
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        viewModel.createEvent(authManager: authManager) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(mockEventRepository.addedEvents.count, 1)
        XCTAssertEqual(mockEventRepository.addedEvents.first?.address, "Validated Address")
    }
    
    func testCreateEvent_SaveEventFailure() async {
        let authManager = AuthManager(authService: MockAuthService(currentAppUser: MockAppUser(uid: "user123")))
        
        viewModel.title = "Test Title"
        viewModel.description = "Test Description"
        viewModel.address = "Valid Address"
        
        mockGeocodingService.validateAddressResult = .success("Validated Address")
        mockEventRepository.addResult = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "DB error"])
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        viewModel.createEvent(authManager: authManager) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.errorMessage, "Failed to save event: DB error")
    }
    
    // MARK: - Image branch (uploadImageAndSaveEvent)
    
    func testCreateEvent_Success_WithImage() async {
        let authManager = AuthManager(authService: MockAuthService(currentAppUser: MockAppUser(uid: "user123")))
        
        viewModel.title = "Test Title"
        viewModel.description = "Test Description"
        viewModel.address = "Valid Address"
        viewModel.selectedImage = makeSolidImage()
        
        mockGeocodingService.validateAddressResult = .success("Validated Address")
        let uploadedURL = URL(string: "https://example.com/cover.jpg")!
        mockStorageService.uploadResult = .success(uploadedURL)
        mockEventRepository.addResult = nil
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        viewModel.createEvent(authManager: authManager) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(mockStorageService.uploadedData)
        XCTAssertEqual(mockEventRepository.addedEvents.count, 1)
        XCTAssertEqual(mockEventRepository.addedEvents.first?.coverImageUrl, uploadedURL.absoluteString)
        XCTAssertEqual(mockEventRepository.addedEvents.first?.address, "Validated Address")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testCreateEvent_ImageProcessingFailure() async {
        let authManager = AuthManager(authService: MockAuthService(currentAppUser: MockAppUser(uid: "user123")))
        
        viewModel.title = "Test Title"
        viewModel.description = "Test Description"
        viewModel.address = "Valid Address"
        viewModel.selectedImage = UIImage() // Empty image fails jpegData extraction
        
        mockGeocodingService.validateAddressResult = .success("Validated Address")
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        viewModel.createEvent(authManager: authManager) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.errorMessage, "Could not process image.")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(mockEventRepository.addedEvents.isEmpty)
    }
    
    func testCreateEvent_ImageUploadFailure() async {
        let authManager = AuthManager(authService: MockAuthService(currentAppUser: MockAppUser(uid: "user123")))
        
        viewModel.title = "Test Title"
        viewModel.description = "Test Description"
        viewModel.address = "Valid Address"
        viewModel.selectedImage = makeSolidImage()
        
        mockGeocodingService.validateAddressResult = .success("Validated Address")
        mockStorageService.uploadResult = .failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Upload fail"]))
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        viewModel.createEvent(authManager: authManager) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.errorMessage, "Failed to upload image: Upload fail")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(mockEventRepository.addedEvents.isEmpty)
    }
    
    // MARK: - DefaultGeocodingService (real MapKit; requires network)
    
    /// Resolvable address: exercises the request setup and the completion closure.
    /// Online this hits the success branch; offline it hits the error branch — either
    /// way the callback fires, so the test only requires that it completes.
    func testDefaultGeocodingService_validAddressCompletes() {
        let service = DefaultGeocodingService()
        let expectation = XCTestExpectation(description: "geocoding completes")
        
        service.validateAddress("Tour Eiffel, Paris, France") { _, _ in
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20)
    }
    
    /// A query unlikely to match anything: exercises the "no results" completion branch.
    func testDefaultGeocodingService_nonsenseAddressCompletes() {
        let service = DefaultGeocodingService()
        let expectation = XCTestExpectation(description: "geocoding completes")
        
        service.validateAddress("zzqxwv nonexistent place 918273645") { _, _ in
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20)
    }
    
    // MARK: - Helpers
    
    /// A small non-empty image that produces valid JPEG data (unlike `UIImage()`).
    private func makeSolidImage() -> UIImage {
        let size = CGSize(width: 10, height: 10)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
