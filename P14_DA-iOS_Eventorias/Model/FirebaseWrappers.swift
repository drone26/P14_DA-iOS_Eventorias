//
//  FirebaseWrappers.swift
//  P14_DA-iOS_Eventorias
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

// MARK: - Protocol Definitions

protocol ListenerRegistrationProtocol: Sendable {
    func remove()
}

protocol DocumentSnapshotProtocol: Sendable {
    var exists: Bool { get }
    func data<T: Decodable>(as type: T.Type) throws -> T
}

protocol QuerySnapshotProtocol: Sendable {
    var documents: [DocumentSnapshotProtocol] { get }
}

protocol DocumentReferenceProtocol: Sendable {
    func getDocument(completion: @escaping (DocumentSnapshotProtocol?, Error?) -> Void)
    func updateData(_ fields: [AnyHashable: Any], completion: ((Error?) -> Void)?)
    func setData<T: Encodable>(from value: T) throws
    func delete(completion: ((Error?) -> Void)?)
}

protocol QueryProtocol: Sendable {
    func whereField(_ field: String, arrayContains value: Any) -> QueryProtocol
    func order(by field: String, descending: Bool) -> QueryProtocol
    func addSnapshotListener(_ listener: @escaping (QuerySnapshotProtocol?, Error?) -> Void) -> ListenerRegistrationProtocol
}

protocol CollectionReferenceProtocol: QueryProtocol {
    func document(_ documentPath: String) -> DocumentReferenceProtocol
    func addDocument<T: Encodable>(from value: T, completion: ((Error?) -> Void)?) throws -> DocumentReferenceProtocol
}

protocol FirestoreProtocol: Sendable {
    func collection(_ collectionPath: String) -> CollectionReferenceProtocol
}

protocol StorageReferenceProtocol: Sendable {
    func child(_ path: String) -> StorageReferenceProtocol
    func putData(_ uploadData: Data, metadata: StorageMetadata?, completion: ((StorageMetadata?, Error?) -> Void)?)
    func downloadURL(completion: @escaping (URL?, Error?) -> Void)
    func delete(completion: ((Error?) -> Void)?)
}

protocol StorageProtocol: Sendable {
    func reference() -> StorageReferenceProtocol
    func reference(forURL url: String) -> StorageReferenceProtocol
}

// MARK: - Default Implementations

final class DefaultListenerRegistration: @unchecked Sendable, ListenerRegistrationProtocol {
    private let reg: ListenerRegistration
    init(_ reg: ListenerRegistration) { self.reg = reg }
    func remove() { reg.remove() }
}

final class DefaultDocumentSnapshot: @unchecked Sendable, DocumentSnapshotProtocol {
    private let snap: DocumentSnapshot
    init(_ snap: DocumentSnapshot) { self.snap = snap }
    var exists: Bool { snap.exists }
    func data<T: Decodable>(as type: T.Type) throws -> T {
        return try snap.data(as: type)
    }
}

final class DefaultQuerySnapshot: @unchecked Sendable, QuerySnapshotProtocol {
    private let snap: QuerySnapshot
    init(_ snap: QuerySnapshot) { self.snap = snap }
    var documents: [DocumentSnapshotProtocol] {
        return snap.documents.map { DefaultDocumentSnapshot($0) }
    }
}

final class DefaultDocumentReference: @unchecked Sendable, DocumentReferenceProtocol {
    private let ref: DocumentReference
    init(_ ref: DocumentReference) { self.ref = ref }
    func getDocument(completion: @escaping (DocumentSnapshotProtocol?, Error?) -> Void) {
        ref.getDocument { snap, err in
            if let snap = snap { completion(DefaultDocumentSnapshot(snap), err) }
            else { completion(nil, err) }
        }
    }
    func updateData(_ fields: [AnyHashable: Any], completion: ((Error?) -> Void)?) {
        ref.updateData(fields, completion: completion)
    }
    func setData<T: Encodable>(from value: T) throws {
        try ref.setData(from: value)
    }
    func delete(completion: ((Error?) -> Void)?) {
        ref.delete(completion: completion)
    }
}

final class DefaultQuery: @unchecked Sendable, QueryProtocol {
    private let query: Query
    init(_ query: Query) { self.query = query }
    func whereField(_ field: String, arrayContains value: Any) -> QueryProtocol {
        return DefaultQuery(query.whereField(field, arrayContains: value))
    }
    func order(by field: String, descending: Bool) -> QueryProtocol {
        return DefaultQuery(query.order(by: field, descending: descending))
    }
    func addSnapshotListener(_ listener: @escaping (QuerySnapshotProtocol?, Error?) -> Void) -> ListenerRegistrationProtocol {
        let reg = query.addSnapshotListener { snap, err in
            if let snap = snap { listener(DefaultQuerySnapshot(snap), err) }
            else { listener(nil, err) }
        }
        return DefaultListenerRegistration(reg)
    }
}

final class DefaultCollectionReference: @unchecked Sendable, CollectionReferenceProtocol {
    private let ref: CollectionReference
    init(_ ref: CollectionReference) { self.ref = ref }
    
    func document(_ documentPath: String) -> DocumentReferenceProtocol {
        return DefaultDocumentReference(ref.document(documentPath))
    }
    func addDocument<T: Encodable>(from value: T, completion: ((Error?) -> Void)?) throws -> DocumentReferenceProtocol {
        let docRef = try ref.addDocument(from: value, completion: completion)
        return DefaultDocumentReference(docRef)
    }
    func whereField(_ field: String, arrayContains value: Any) -> QueryProtocol {
        return DefaultQuery(ref.whereField(field, arrayContains: value))
    }
    func order(by field: String, descending: Bool) -> QueryProtocol {
        return DefaultQuery(ref.order(by: field, descending: descending))
    }
    func addSnapshotListener(_ listener: @escaping (QuerySnapshotProtocol?, Error?) -> Void) -> ListenerRegistrationProtocol {
        let reg = ref.addSnapshotListener { snap, err in
            if let snap = snap { listener(DefaultQuerySnapshot(snap), err) }
            else { listener(nil, err) }
        }
        return DefaultListenerRegistration(reg)
    }
}

final class DefaultFirestore: @unchecked Sendable, FirestoreProtocol {
    private let db: Firestore
    init(_ db: Firestore = Firestore.firestore()) { self.db = db }
    func collection(_ collectionPath: String) -> CollectionReferenceProtocol {
        return DefaultCollectionReference(db.collection(collectionPath))
    }
}

final class DefaultStorageReference: @unchecked Sendable, StorageReferenceProtocol {
    private let ref: StorageReference
    init(_ ref: StorageReference) { self.ref = ref }
    func child(_ path: String) -> StorageReferenceProtocol {
        return DefaultStorageReference(ref.child(path))
    }
    func putData(_ uploadData: Data, metadata: StorageMetadata?, completion: ((StorageMetadata?, Error?) -> Void)?) {
        _ = ref.putData(uploadData, metadata: metadata) { metadata, error in
            completion?(metadata, error)
        }
    }
    func downloadURL(completion: @escaping (URL?, Error?) -> Void) {
        ref.downloadURL(completion: completion)
    }
    func delete(completion: ((Error?) -> Void)?) {
        ref.delete(completion: completion)
    }
}

final class DefaultStorage: @unchecked Sendable, StorageProtocol {
    private let storage: Storage
    init(_ storage: Storage) { self.storage = storage }
    func reference() -> StorageReferenceProtocol {
        return DefaultStorageReference(storage.reference())
    }
    func reference(forURL url: String) -> StorageReferenceProtocol {
        return DefaultStorageReference(storage.reference(forURL: url))
    }
}
