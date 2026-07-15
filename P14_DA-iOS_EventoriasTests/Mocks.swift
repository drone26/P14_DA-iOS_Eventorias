import Foundation
import FirebaseAuth
import FirebaseFirestore
@testable import P14_DA_iOS_Eventorias

struct MockAppUser: AppUserProtocol {
    var uid: String
    var displayName: String?
    var email: String?
    var photoURL: URL?
}

final class MockAuthService: @unchecked Sendable, AuthServiceProtocol {
    var currentAppUser: AppUserProtocol?
    var signInResult: Result<AuthDataResult, Error>?
    var createUserResult: Result<AuthDataResult, Error>?
    var didSignOut = false
    
    init(currentAppUser: AppUserProtocol? = nil) {
        self.currentAppUser = currentAppUser
    }
    
    func addStateDidChangeListener(_ listener: @escaping (Auth, AppUserProtocol?) -> Void) -> AuthStateDidChangeListenerHandle {
        listener(Auth.auth(), currentAppUser)
        return NSObject() as AuthStateDidChangeListenerHandle
    }
    
    func removeStateDidChangeListener(_ handle: AuthStateDidChangeListenerHandle) {}
    
    func signOut() throws {
        didSignOut = true
        currentAppUser = nil
    }
    
    func signIn(withEmail email: String, password: String, completion: ((AuthDataResult?, Error?) -> Void)?) {
        if let result = signInResult {
            switch result {
            case .success(let data): completion?(data, nil)
            case .failure(let error): completion?(nil, error)
            }
        } else {
            completion?(nil, nil)
        }
    }
    
    func createUser(withEmail email: String, password: String, completion: ((AuthDataResult?, Error?) -> Void)?) {
        if let result = createUserResult {
            switch result {
            case .success(let data): completion?(data, nil)
            case .failure(let error): completion?(nil, error)
            }
        } else {
            completion?(nil, nil)
        }
    }
}

final class MockListenerRegistration: @unchecked Sendable, ListenerRegistrationProtocol {
    var didRemove = false
    func remove() {
        didRemove = true
    }
}

final class MockEventRepository: @unchecked Sendable, EventRepositoryProtocol {
    var fetchResult: Result<[Event], Error>?
    var addResult: Error?
    var addedEvents: [Event] = []
    var deleteResult: Error?
    var deletedEvents: [Event] = []
    
    func fetchEvents(searchQuery: String, sortOption: SortOption, completion: @escaping ([Event]?, Error?) -> Void) -> ListenerRegistrationProtocol {
        if let result = fetchResult {
            switch result {
            case .success(let events): completion(events, nil)
            case .failure(let error): completion(nil, error)
            }
        }
        return MockListenerRegistration()
    }
    
    func addEvent(_ event: Event, completion: @escaping (Error?) -> Void) {
        addedEvents.append(event)
        completion(addResult)
    }
    
    func deleteEvent(_ event: Event, completion: @escaping (Error?) -> Void) {
        deletedEvents.append(event)
        completion(deleteResult)
    }
}

final class MockUserRepository: @unchecked Sendable, UserRepositoryProtocol {
    var profileResult: Result<UserProfile?, Error>?
    var updateResult: Error?
    var saveResult: Error?
    var savedProfile: UserProfile?
    var updatedData: [AnyHashable: Any] = [:]
    
    func getProfile(uid: String, completion: @escaping (UserProfile?, Error?) -> Void) {
        if let result = profileResult {
            switch result {
            case .success(let profile): completion(profile, nil)
            case .failure(let error): completion(nil, error)
            }
        }
    }
    
    func updateProfile(uid: String, data: [AnyHashable : Any], completion: @escaping (Error?) -> Void) {
        updatedData.merge(data) { _, new in new }
        completion(updateResult)
    }
    
    func saveProfile(_ profile: UserProfile, completion: @escaping (Error?) -> Void) {
        savedProfile = profile
        completion(saveResult)
    }
}

final class MockImageStorageService: @unchecked Sendable, ImageStorageServiceProtocol {
    var uploadResult: Result<URL, Error>?
    var uploadedData: Data?
    var deleteResult: Error?
    var deletedImageUrl: String?
    
    func uploadImage(_ imageData: Data, path: String, completion: @escaping (URL?, Error?) -> Void) {
        uploadedData = imageData
        if let result = uploadResult {
            switch result {
            case .success(let url): completion(url, nil)
            case .failure(let error): completion(nil, error)
            }
        }
    }
    
    func deleteImage(url: String, completion: @escaping (Error?) -> Void) {
        deletedImageUrl = url
        completion(deleteResult)
    }
}

final class MockGeocodingService: @unchecked Sendable, GeocodingServiceProtocol {
    var validateAddressResult: Result<String?, Error>?
    var validatedAddressPassedIn: String?
    
    func validateAddress(_ address: String, completion: @escaping (String?, Error?) -> Void) {
        validatedAddressPassedIn = address
        if let result = validateAddressResult {
            switch result {
            case .success(let addr): completion(addr, nil)
            case .failure(let error): completion(nil, error)
            }
        }
    }
}
