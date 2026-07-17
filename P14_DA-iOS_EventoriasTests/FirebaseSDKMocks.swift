//
//  FirebaseSDKMocks.swift
//  P14_DA-iOS_EventoriasTests
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
@testable import P14_DA_iOS_Eventorias

// MARK: - Mocks for Firestore Protocols

class MockFirestore: @unchecked Sendable, FirestoreProtocol {
    var collections: [String: MockCollectionReference] = [:]
    
    func collection(_ collectionPath: String) -> CollectionReferenceProtocol {
        if let collection = collections[collectionPath] {
            return collection
        }
        let newCollection = MockCollectionReference()
        collections[collectionPath] = newCollection
        return newCollection
    }
}

class MockCollectionReference: @unchecked Sendable, CollectionReferenceProtocol {
    var documents: [String: MockDocumentReference] = [:]
    var addedDocuments: [Any] = []
    
    var whereFieldCalledWith: (field: String, value: Any)?
    var orderCalledWith: (field: String, descending: Bool)?
    
    var snapshotToReturn: MockQuerySnapshot?
    var errorToReturn: Error?
    
    func document(_ documentPath: String) -> DocumentReferenceProtocol {
        if let doc = documents[documentPath] {
            return doc
        }
        let newDoc = MockDocumentReference()
        documents[documentPath] = newDoc
        return newDoc
    }
    
    func addDocument<T>(from value: T, completion: ((Error?) -> Void)?) throws -> DocumentReferenceProtocol where T : Encodable {
        addedDocuments.append(value)
        completion?(errorToReturn)
        return MockDocumentReference()
    }
    
    func whereField(_ field: String, arrayContains value: Any) -> QueryProtocol {
        whereFieldCalledWith = (field, value)
        return self
    }
    
    func order(by field: String, descending: Bool) -> QueryProtocol {
        orderCalledWith = (field, descending)
        return self
    }
    
    func addSnapshotListener(_ listener: @escaping (QuerySnapshotProtocol?, Error?) -> Void) -> ListenerRegistrationProtocol {
        listener(snapshotToReturn, errorToReturn)
        return MockListenerRegistration()
    }
}

class MockDocumentReference: @unchecked Sendable, DocumentReferenceProtocol {
    var snapshotToReturn: MockDocumentSnapshot?
    var errorToReturn: Error?
    var updatedData: [AnyHashable: Any] = [:]
    var setDataValue: Any?
    var didDelete = false
    
    func getDocument(completion: @escaping (DocumentSnapshotProtocol?, Error?) -> Void) {
        completion(snapshotToReturn, errorToReturn)
    }
    
    func updateData(_ fields: [AnyHashable : Any], completion: ((Error?) -> Void)?) {
        updatedData.merge(fields) { _, new in new }
        completion?(errorToReturn)
    }
    
    func setData<T>(from value: T) throws where T : Encodable {
        setDataValue = value
        if let error = errorToReturn {
            throw error
        }
    }
    
    func delete(completion: ((Error?) -> Void)?) {
        didDelete = true
        completion?(errorToReturn)
    }
}

class MockDocumentSnapshot: @unchecked Sendable, DocumentSnapshotProtocol {
    var exists: Bool = true
    var dataToReturn: Any?
    var errorToReturn: Error?
    
    func data<T>(as type: T.Type) throws -> T where T : Decodable {
        if let error = errorToReturn {
            throw error
        }
        if let data = dataToReturn as? T {
            return data
        }
        throw NSError(domain: "MockError", code: 0, userInfo: nil)
    }
}

class MockQuerySnapshot: @unchecked Sendable, QuerySnapshotProtocol {
    var mockDocuments: [MockDocumentSnapshot] = []
    
    var documents: [DocumentSnapshotProtocol] {
        return mockDocuments
    }
}

// MARK: - Mocks for Storage Protocols

class MockStorage: @unchecked Sendable, StorageProtocol {
    let mockReference = MockStorageReference()
    var referenceForURLCalledWith: String?
    
    func reference() -> StorageReferenceProtocol {
        return mockReference
    }
    
    func reference(forURL url: String) -> StorageReferenceProtocol {
        referenceForURLCalledWith = url
        return mockReference
    }
}

class MockStorageReference: @unchecked Sendable, StorageReferenceProtocol {
    var paths: [String: MockStorageReference] = [:]
    var uploadedData: Data?
    var uploadError: Error?
    var urlToReturn: URL?
    var downloadError: Error?
    
    func child(_ path: String) -> StorageReferenceProtocol {
        if let ref = paths[path] { return ref }
        let newRef = MockStorageReference()
        paths[path] = newRef
        return newRef
    }
    
    func putData(_ uploadData: Data, metadata: StorageMetadata?, completion: ((StorageMetadata?, Error?) -> Void)?) {
        self.uploadedData = uploadData
        completion?(metadata, uploadError)
    }
    
    func downloadURL(completion: @escaping (URL?, Error?) -> Void) {
        completion(urlToReturn, downloadError)
    }
    
    var didDelete = false
    var deleteError: Error?
    func delete(completion: ((Error?) -> Void)?) {
        didDelete = true
        completion?(deleteError)
    }
}
