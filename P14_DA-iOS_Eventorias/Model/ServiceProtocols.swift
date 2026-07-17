import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Auth

protocol AppUserProtocol: Sendable {
    var uid: String { get }
    var displayName: String? { get }
    var email: String? { get }
    var photoURL: URL? { get }
}

extension User: @retroactive @unchecked Sendable {}
extension User: AppUserProtocol {}

protocol AuthServiceProtocol: Sendable {
    var currentAppUser: AppUserProtocol? { get }
    func addStateDidChangeListener(_ listener: @escaping (Auth, AppUserProtocol?) -> Void) -> AuthStateDidChangeListenerHandle
    func removeStateDidChangeListener(_ handle: AuthStateDidChangeListenerHandle)
    func signOut() throws
    func signIn(withEmail email: String, password: String, completion: ((AuthDataResult?, Error?) -> Void)?)
    func createUser(withEmail email: String, password: String, completion: ((AuthDataResult?, Error?) -> Void)?)
}

extension Auth: @retroactive @unchecked Sendable {}
extension Auth: AuthServiceProtocol {
    var currentAppUser: AppUserProtocol? { return currentUser }
    func addStateDidChangeListener(_ listener: @escaping (Auth, AppUserProtocol?) -> Void) -> AuthStateDidChangeListenerHandle {
        return self.addStateDidChangeListener { (auth: Auth, user: User?) in
            listener(auth, user)
        }
    }
}

// MARK: - Database

protocol EventRepositoryProtocol: Sendable {
    func fetchEvents(searchQuery: String, sortOption: SortOption, completion: @escaping ([Event]?, Error?) -> Void) -> ListenerRegistrationProtocol
    func addEvent(_ event: Event, completion: @escaping (Error?) -> Void)
    func deleteEvent(_ event: Event, completion: @escaping (Error?) -> Void)
}

protocol UserRepositoryProtocol: Sendable {
    func getProfile(uid: String, completion: @escaping (UserProfile?, Error?) -> Void)
    func updateProfile(uid: String, data: [AnyHashable: Any], completion: @escaping (Error?) -> Void)
    func saveProfile(_ profile: UserProfile, completion: @escaping (Error?) -> Void)
}

// MARK: - Storage

protocol ImageStorageServiceProtocol: Sendable {
    func uploadImage(_ imageData: Data, path: String, completion: @escaping (URL?, Error?) -> Void)
    func deleteImage(url: String, completion: @escaping (Error?) -> Void)
}
// MARK: - Geocoding

protocol GeocodingServiceProtocol: Sendable {
    func validateAddress(_ address: String, completion: @escaping (String?, Error?) -> Void)
}
