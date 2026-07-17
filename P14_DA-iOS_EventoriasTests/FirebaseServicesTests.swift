//
//  FirebaseServicesTests.swift
//  P14_DA-iOS_EventoriasTests
//

import XCTest
@testable import P14_DA_iOS_Eventorias

@MainActor
class FirebaseEventRepositoryTests: XCTestCase {
    var repository: FirebaseEventRepository!
    var mockFirestore: MockFirestore!
    
    override func setUp() {
        super.setUp()
        mockFirestore = MockFirestore()
        repository = FirebaseEventRepository(db: mockFirestore)
    }
    
    func testFetchEvents_WithoutSearch() async {
        let collection = mockFirestore.collection("events") as! MockCollectionReference
        
        // Setup mock data
        let snapshot = MockQuerySnapshot()
        let doc1 = MockDocumentSnapshot()
        doc1.dataToReturn = Event(title: "Event 1", description: "Desc 1", date: Date(), address: "Add 1", creatorId: "user1")
        let doc2 = MockDocumentSnapshot()
        doc2.dataToReturn = Event(title: "Event 2", description: "Desc 2", date: Date().addingTimeInterval(100), address: "Add 2", creatorId: "user1")
        snapshot.mockDocuments = [doc1, doc2]
        
        collection.snapshotToReturn = snapshot
        
        let expectation = XCTestExpectation(description: "Fetch complete")
        
        _ = repository.fetchEvents(searchQuery: "", sortOption: .dateAsc) { events, error in
            XCTAssertNil(error)
            XCTAssertEqual(events?.count, 2)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertNil(collection.whereFieldCalledWith)
        XCTAssertEqual(collection.orderCalledWith?.field, "date")
        XCTAssertEqual(collection.orderCalledWith?.descending, false)
    }
    
    func testFetchEvents_WithSearch_DateDesc() async {
        let collection = mockFirestore.collection("events") as! MockCollectionReference
        
        // Setup mock data
        let snapshot = MockQuerySnapshot()
        let doc1 = MockDocumentSnapshot()
        doc1.dataToReturn = Event(title: "Event 1", description: "Desc 1", date: Date(), address: "Add 1", creatorId: "user1")
        let doc2 = MockDocumentSnapshot()
        doc2.dataToReturn = Event(title: "Event 2", description: "Desc 2", date: Date().addingTimeInterval(100), address: "Add 2", creatorId: "user1")
        snapshot.mockDocuments = [doc1, doc2]
        
        collection.snapshotToReturn = snapshot
        
        let expectation = XCTestExpectation(description: "Fetch complete")
        
        _ = repository.fetchEvents(searchQuery: "Event", sortOption: .dateDesc) { events, error in
            XCTAssertNil(error)
            XCTAssertEqual(events?.count, 2)
            // Expect Date Descending sorting to apply locally
            XCTAssertEqual(events?.first?.title, "Event 2")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(collection.whereFieldCalledWith?.field, "searchTokens")
        XCTAssertEqual(collection.whereFieldCalledWith?.value as? String, "event")
        XCTAssertNil(collection.orderCalledWith) // Ordering is done locally when searching
    }
    
    func testFetchEvents_Error() async {
        let collection = mockFirestore.collection("events") as! MockCollectionReference
        collection.errorToReturn = NSError(domain: "NetworkError", code: -1, userInfo: nil)
        
        let expectation = XCTestExpectation(description: "Fetch error")
        
        _ = repository.fetchEvents(searchQuery: "", sortOption: .titleAsc) { events, error in
            XCTAssertNotNil(error)
            XCTAssertNil(events)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(collection.orderCalledWith?.field, "titleLower")
        XCTAssertEqual(collection.orderCalledWith?.descending, false)
    }
    
    func testAddEvent_Success() {
        let collection = mockFirestore.collection("events") as! MockCollectionReference
        let event = Event(title: "New Event", description: "Desc", date: Date(), address: "Add", creatorId: "user1")
        
        let expectation = XCTestExpectation(description: "Add success")
        repository.addEvent(event) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(collection.addedDocuments.count, 1)
    }
    
    func testAddEvent_Error() {
        let collection = mockFirestore.collection("events") as! MockCollectionReference
        collection.errorToReturn = NSError(domain: "WriteError", code: -1, userInfo: nil)
        
        let event = Event(title: "New Event", description: "Desc", date: Date(), address: "Add", creatorId: "user1")
        
        let expectation = XCTestExpectation(description: "Add error")
        repository.addEvent(event) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchEvents_NoSnapshotReturnsEmpty() async {
        // No snapshot and no error configured: the guard falls through to an empty result.
        let expectation = XCTestExpectation(description: "Fetch empty")
        
        _ = repository.fetchEvents(searchQuery: "", sortOption: .dateAsc) { events, error in
            XCTAssertNil(error)
            XCTAssertEqual(events?.count, 0)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testFetchEvents_WithSearch_DateAsc_SortsLocally() async {
        let collection = mockFirestore.collection("events") as! MockCollectionReference
        
        let snapshot = MockQuerySnapshot()
        let later = MockDocumentSnapshot()
        later.dataToReturn = Event(title: "B Event", description: "D", date: Date().addingTimeInterval(100), address: "A", creatorId: "u")
        let earlier = MockDocumentSnapshot()
        earlier.dataToReturn = Event(title: "A Event", description: "D", date: Date(), address: "A", creatorId: "u")
        snapshot.mockDocuments = [later, earlier]
        collection.snapshotToReturn = snapshot
        
        let expectation = XCTestExpectation(description: "Fetch dateAsc")
        _ = repository.fetchEvents(searchQuery: "Event", sortOption: .dateAsc) { events, error in
            XCTAssertNil(error)
            XCTAssertEqual(events?.first?.title, "A Event") // earlier date sorts first
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testFetchEvents_WithSearch_TitleAsc_SortsLocally() async {
        let collection = mockFirestore.collection("events") as! MockCollectionReference
        
        let snapshot = MockQuerySnapshot()
        let docB = MockDocumentSnapshot()
        docB.dataToReturn = Event(title: "B Event", description: "D", date: Date(), address: "A", creatorId: "u")
        let docA = MockDocumentSnapshot()
        docA.dataToReturn = Event(title: "A Event", description: "D", date: Date().addingTimeInterval(100), address: "A", creatorId: "u")
        snapshot.mockDocuments = [docB, docA]
        collection.snapshotToReturn = snapshot
        
        let expectation = XCTestExpectation(description: "Fetch titleAsc")
        _ = repository.fetchEvents(searchQuery: "Event", sortOption: .titleAsc) { events, error in
            XCTAssertNil(error)
            XCTAssertEqual(events?.first?.title, "A Event") // titleLower sorts first
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testDeleteEvent_Success() {
        let collection = mockFirestore.collection("events") as! MockCollectionReference
        let document = collection.document("event123") as! MockDocumentReference
        let event = Event(id: "event123", title: "T", description: "D", date: Date(), address: "A", creatorId: "u")
        
        let expectation = XCTestExpectation(description: "Delete success")
        repository.deleteEvent(event) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(document.didDelete)
    }
    
    func testDeleteEvent_NoIdentifier() {
        let event = Event(title: "T", description: "D", date: Date(), address: "A", creatorId: "u") // id is nil
        
        let expectation = XCTestExpectation(description: "Delete missing id")
        repository.deleteEvent(event) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}

@MainActor
class FirebaseUserRepositoryTests: XCTestCase {
    var repository: FirebaseUserRepository!
    var mockFirestore: MockFirestore!
    
    override func setUp() {
        super.setUp()
        mockFirestore = MockFirestore()
        repository = FirebaseUserRepository(db: mockFirestore)
    }
    
    func testGetProfile_Success() async {
        let collection = mockFirestore.collection("users") as! MockCollectionReference
        let document = collection.document("user123") as! MockDocumentReference
        
        let snapshot = MockDocumentSnapshot()
        snapshot.dataToReturn = UserProfile(id: "user123", name: "Test User", email: "test@example.com", avatarUrl: nil, notificationsEnabled: false)
        document.snapshotToReturn = snapshot
        
        let expectation = XCTestExpectation(description: "Get profile")
        
        repository.getProfile(uid: "user123") { profile, error in
            XCTAssertNil(error)
            XCTAssertNotNil(profile)
            XCTAssertEqual(profile?.name, "Test User")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testGetProfile_NotFound() async {
        let collection = mockFirestore.collection("users") as! MockCollectionReference
        let document = collection.document("user123") as! MockDocumentReference
        
        let snapshot = MockDocumentSnapshot()
        snapshot.exists = false
        document.snapshotToReturn = snapshot
        
        let expectation = XCTestExpectation(description: "Profile not found")
        
        repository.getProfile(uid: "user123") { profile, error in
            XCTAssertNil(error)
            XCTAssertNil(profile)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testUpdateProfile() {
        let collection = mockFirestore.collection("users") as! MockCollectionReference
        let document = collection.document("user123") as! MockDocumentReference
        
        let expectation = XCTestExpectation(description: "Update profile")
        repository.updateProfile(uid: "user123", data: ["name": "New Name"]) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(document.updatedData["name"] as? String, "New Name")
    }
    
    func testSaveProfile() {
        let collection = mockFirestore.collection("users") as! MockCollectionReference
        
        let profile = UserProfile(id: "user123", name: "Save User", email: "save@test.com", avatarUrl: nil, notificationsEnabled: true)
        let document = collection.document("user123") as! MockDocumentReference
        
        let expectation = XCTestExpectation(description: "Save profile")
        repository.saveProfile(profile) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(document.setDataValue)
    }
}

class FirebaseImageStorageServiceTests: XCTestCase {
    var service: FirebaseImageStorageService!
    var mockStorage: MockStorage!
    
    override func setUp() {
        super.setUp()
        mockStorage = MockStorage()
        service = FirebaseImageStorageService(storage: mockStorage)
    }
    
    func testUploadImage_Success() {
        let rootRef = mockStorage.mockReference
        let childRef = rootRef.child("images/test.jpg") as! MockStorageReference
        
        childRef.urlToReturn = URL(string: "https://example.com/images/test.jpg")!
        
        let expectation = XCTestExpectation(description: "Upload success")
        service.uploadImage(Data(), path: "images/test.jpg") { url, error in
            XCTAssertNil(error)
            XCTAssertEqual(url?.absoluteString, "https://example.com/images/test.jpg")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(childRef.uploadedData)
    }
    
    func testUploadImage_PutDataError() {
        let rootRef = mockStorage.mockReference
        let childRef = rootRef.child("images/test.jpg") as! MockStorageReference
        
        childRef.uploadError = NSError(domain: "UploadError", code: -1, userInfo: nil)
        
        let expectation = XCTestExpectation(description: "Upload error")
        service.uploadImage(Data(), path: "images/test.jpg") { url, error in
            XCTAssertNotNil(error)
            XCTAssertNil(url)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteImage_Success() {
        let expectation = XCTestExpectation(description: "Delete image")
        service.deleteImage(url: "https://example.com/images/test.jpg") { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockStorage.referenceForURLCalledWith, "https://example.com/images/test.jpg")
        XCTAssertTrue(mockStorage.mockReference.didDelete)
    }
}
