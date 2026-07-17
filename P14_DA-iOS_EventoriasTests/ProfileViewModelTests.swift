import XCTest
import UIKit
import FirebaseAuth
@testable import P14_DA_iOS_Eventorias

@MainActor
class ProfileViewModelTests: XCTestCase {
    var viewModel: ProfileViewModel!
    var mockUserRepository: MockUserRepository!
    var mockStorageService: MockImageStorageService!
    var mockAuthService: MockAuthService!
    var mockAuthManager: AuthManager!
    
    override func setUp() {
        super.setUp()
        mockUserRepository = MockUserRepository()
        mockStorageService = MockImageStorageService()
        
        let mockAppUser = MockAppUser(uid: "user123", displayName: "Test User", email: "test@example.com", photoURL: nil)
        mockAuthService = MockAuthService(currentAppUser: mockAppUser)
        mockAuthManager = AuthManager(authService: mockAuthService)
        
        viewModel = ProfileViewModel(userRepository: mockUserRepository, storageService: mockStorageService)
    }
    
    func testFetchProfile_existingUser() async {
        let expectedProfile = UserProfile(id: "user123", name: "Test User", email: "test@example.com", avatarUrl: nil, notificationsEnabled: true)
        mockUserRepository.profileResult = .success(expectedProfile)
        
        viewModel.fetchProfile(authManager: mockAuthManager)
        
        // Wait for task to complete
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertEqual(viewModel.profile?.name, "Test User")
        XCTAssertEqual(viewModel.profile?.notificationsEnabled, true)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testToggleNotifications() async {
        let initialProfile = UserProfile(id: "user123", name: "Test User", email: "test@example.com", avatarUrl: nil, notificationsEnabled: false)
        viewModel.profile = initialProfile
        mockUserRepository.updateResult = nil
        
        viewModel.toggleNotifications(authManager: mockAuthManager, isOn: true)
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertEqual(viewModel.profile?.notificationsEnabled, true)
        XCTAssertEqual(mockUserRepository.updatedData["notificationsEnabled"] as? Bool, true)
    }
    
    func testSaveName() async {
        let initialProfile = UserProfile(id: "user123", name: "Test User", email: "test@example.com", avatarUrl: nil, notificationsEnabled: false)
        viewModel.profile = initialProfile
        mockUserRepository.updateResult = nil
        
        viewModel.saveName(authManager: mockAuthManager, newName: "New Name")
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertEqual(mockUserRepository.updatedData["name"] as? String, "New Name")
    }
    
    func testFetchProfile_newProfileCreated() async {
        mockUserRepository.profileResult = .success(nil as UserProfile?) // No profile found
        mockUserRepository.saveResult = nil // success saving new profile
        
        viewModel.fetchProfile(authManager: mockAuthManager)
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertEqual(viewModel.profile?.name, "Test User")
        XCTAssertEqual(viewModel.profile?.email, "test@example.com")
        XCTAssertFalse(viewModel.profile?.notificationsEnabled ?? true)
        XCTAssertEqual(mockUserRepository.savedProfile?.id, "user123")
    }

    func testFetchProfile_error() async {
        mockUserRepository.profileResult = .failure(NSError(domain: "", code: -1, userInfo: nil))
        
        viewModel.fetchProfile(authManager: mockAuthManager)
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertNil(viewModel.profile)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testUploadAvatar_invalidImage() {
        let image = UIImage() // Empty image will fail jpegData extraction
        
        viewModel.uploadAvatar(image: image, authManager: mockAuthManager)
        
        XCTAssertEqual(viewModel.errorMessage, "Impossible de traiter l'image.")
    }
    
    // MARK: - fetchProfile
    
    func testFetchProfile_notLoggedIn() {
        let loggedOut = AuthManager(authService: MockAuthService(currentAppUser: nil))
        
        viewModel.fetchProfile(authManager: loggedOut)
        
        XCTAssertNil(viewModel.profile)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Utilisateur non connecté.")
    }
    
    func testFetchProfile_createProfileFails() async {
        mockUserRepository.profileResult = .success(nil as UserProfile?) // No profile found
        mockUserRepository.saveResult = NSError(domain: "", code: -1, userInfo: nil) // saving fails
        
        viewModel.fetchProfile(authManager: mockAuthManager)
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertNil(viewModel.profile)
        XCTAssertEqual(viewModel.errorMessage, "Erreur lors de la création du profil.")
    }
    
    func testFetchProfile_loadingTimeoutStopsSpinner() async {
        // With no configured result the repository never calls back, so only the
        // 2-second watchdog can clear the loading state.
        mockUserRepository.profileResult = nil
        
        viewModel.fetchProfile(authManager: mockAuthManager)
        XCTAssertTrue(viewModel.isLoading)
        
        try? await Task.sleep(nanoseconds: 2_300_000_000)
        
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - toggleNotifications
    
    func testToggleNotifications_noProfile_doesNothing() async {
        // profile is nil by default
        viewModel.toggleNotifications(authManager: mockAuthManager, isOn: true)
        
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        XCTAssertNil(viewModel.profile)
        XCTAssertTrue(mockUserRepository.updatedData.isEmpty)
    }
    
    func testToggleNotifications_error_revertsAndSetsError() async {
        viewModel.profile = UserProfile(id: "user123", name: "Test User", email: "test@example.com", avatarUrl: nil, notificationsEnabled: false)
        mockUserRepository.updateResult = NSError(domain: "", code: -1, userInfo: nil)
        
        viewModel.toggleNotifications(authManager: mockAuthManager, isOn: true)
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Optimistic update is reverted on failure.
        XCTAssertEqual(viewModel.profile?.notificationsEnabled, false)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - saveName
    
    func testSaveName_noProfile_doesNothing() async {
        // profile is nil by default
        viewModel.saveName(authManager: mockAuthManager, newName: "New Name")
        
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        XCTAssertTrue(mockUserRepository.updatedData.isEmpty)
    }
    
    func testSaveName_error() async {
        viewModel.profile = UserProfile(id: "user123", name: "Test User", email: "test@example.com", avatarUrl: nil, notificationsEnabled: false)
        mockUserRepository.updateResult = NSError(domain: "", code: -1, userInfo: nil)
        
        viewModel.saveName(authManager: mockAuthManager, newName: "New Name")
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - uploadAvatar
    
    func testUploadAvatar_notLoggedIn() {
        let loggedOut = AuthManager(authService: MockAuthService(currentAppUser: nil))
        
        viewModel.uploadAvatar(image: makeSolidImage(), authManager: loggedOut)
        
        XCTAssertNil(mockStorageService.uploadedData)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testUploadAvatar_success() async {
        viewModel.profile = UserProfile(id: "user123", name: "Test User", email: "test@example.com", avatarUrl: nil, notificationsEnabled: false)
        let uploadedURL = URL(string: "https://example.com/avatar.jpg")!
        mockStorageService.uploadResult = .success(uploadedURL)
        mockUserRepository.updateResult = nil
        
        viewModel.uploadAvatar(image: makeSolidImage(), authManager: mockAuthManager)
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertNotNil(mockStorageService.uploadedData)
        XCTAssertEqual(viewModel.profile?.avatarUrl, uploadedURL.absoluteString)
        XCTAssertEqual(mockUserRepository.updatedData["avatarUrl"] as? String, uploadedURL.absoluteString)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testUploadAvatar_uploadError() async {
        mockStorageService.uploadResult = .failure(NSError(domain: "", code: -1, userInfo: nil))
        
        viewModel.uploadAvatar(image: makeSolidImage(), authManager: mockAuthManager)
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Helpers
    
    /// A small non-empty image that produces valid JPEG data (unlike `UIImage()`).
    private func makeSolidImage() -> UIImage {
        let size = CGSize(width: 10, height: 10)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
