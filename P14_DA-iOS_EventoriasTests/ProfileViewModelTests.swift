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
        // Given
        let expectedProfile = UserProfile(id: "user123", name: "Test User", email: "test@example.com", avatarUrl: nil, notificationsEnabled: true)
        mockUserRepository.profileResult = .success(expectedProfile)

        // When
        viewModel.fetchProfile(authManager: mockAuthManager)

        // Wait for task to complete
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertEqual(viewModel.profile?.name, "Test User")
        XCTAssertEqual(viewModel.profile?.notificationsEnabled, true)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testToggleNotifications() async {
        // Given
        let initialProfile = UserProfile(id: "user123", name: "Test User", email: "test@example.com", avatarUrl: nil, notificationsEnabled: false)
        viewModel.profile = initialProfile
        mockUserRepository.updateResult = nil

        // When
        viewModel.toggleNotifications(authManager: mockAuthManager, isOn: true)

        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertEqual(viewModel.profile?.notificationsEnabled, true)
        XCTAssertEqual(mockUserRepository.updatedData["notificationsEnabled"] as? Bool, true)
    }

    func testSaveName() async {
        // Given
        let initialProfile = UserProfile(id: "user123", name: "Test User", email: "test@example.com", avatarUrl: nil, notificationsEnabled: false)
        viewModel.profile = initialProfile
        mockUserRepository.updateResult = nil

        // When
        viewModel.saveName(authManager: mockAuthManager, newName: "New Name")

        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertEqual(mockUserRepository.updatedData["name"] as? String, "New Name")
    }

    func testFetchProfile_newProfileCreated() async {
        // Given
        mockUserRepository.profileResult = .success(nil as UserProfile?) // No profile found
        mockUserRepository.saveResult = nil // success saving new profile

        // When
        viewModel.fetchProfile(authManager: mockAuthManager)

        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertEqual(viewModel.profile?.name, "Test User")
        XCTAssertEqual(viewModel.profile?.email, "test@example.com")
        XCTAssertFalse(viewModel.profile?.notificationsEnabled ?? true)
        XCTAssertEqual(mockUserRepository.savedProfile?.id, "user123")
    }

    func testFetchProfile_error() async {
        // Given
        mockUserRepository.profileResult = .failure(NSError(domain: "", code: -1, userInfo: nil))

        // When
        viewModel.fetchProfile(authManager: mockAuthManager)

        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertNil(viewModel.profile)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testUploadAvatar_invalidImage() {
        // Given
        let image = UIImage() // Empty image will fail jpegData extraction

        // When
        viewModel.uploadAvatar(image: image, authManager: mockAuthManager)

        // Then
        XCTAssertEqual(viewModel.errorMessage, "Impossible de traiter l'image.")
    }

    // MARK: - fetchProfile

    func testFetchProfile_notLoggedIn() {
        // Given
        let loggedOut = AuthManager(authService: MockAuthService(currentAppUser: nil))

        // When
        viewModel.fetchProfile(authManager: loggedOut)

        // Then
        XCTAssertNil(viewModel.profile)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Utilisateur non connecté.")
    }

    func testFetchProfile_createProfileFails() async {
        // Given
        mockUserRepository.profileResult = .success(nil as UserProfile?) // No profile found
        mockUserRepository.saveResult = NSError(domain: "", code: -1, userInfo: nil) // saving fails

        // When
        viewModel.fetchProfile(authManager: mockAuthManager)

        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertNil(viewModel.profile)
        XCTAssertEqual(viewModel.errorMessage, "Erreur lors de la création du profil.")
    }

    func testFetchProfile_loadingTimeoutStopsSpinner() async {
        // Given
        // With no configured result the repository never calls back, so only the
        // 2-second watchdog can clear the loading state.
        mockUserRepository.profileResult = nil

        // When
        viewModel.fetchProfile(authManager: mockAuthManager)
        XCTAssertTrue(viewModel.isLoading)

        try? await Task.sleep(nanoseconds: 2_300_000_000)

        // Then
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - toggleNotifications

    func testToggleNotifications_noProfile_doesNothing() async {
        // Given
        // profile is nil by default

        // When
        viewModel.toggleNotifications(authManager: mockAuthManager, isOn: true)

        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertNil(viewModel.profile)
        XCTAssertTrue(mockUserRepository.updatedData.isEmpty)
    }

    func testToggleNotifications_error_revertsAndSetsError() async {
        // Given
        viewModel.profile = UserProfile(id: "user123", name: "Test User", email: "test@example.com", avatarUrl: nil, notificationsEnabled: false)
        mockUserRepository.updateResult = NSError(domain: "", code: -1, userInfo: nil)

        // When
        viewModel.toggleNotifications(authManager: mockAuthManager, isOn: true)

        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        // Optimistic update is reverted on failure.
        XCTAssertEqual(viewModel.profile?.notificationsEnabled, false)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - saveName

    func testSaveName_noProfile_doesNothing() async {
        // Given
        // profile is nil by default

        // When
        viewModel.saveName(authManager: mockAuthManager, newName: "New Name")

        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertTrue(mockUserRepository.updatedData.isEmpty)
    }

    func testSaveName_error() async {
        // Given
        viewModel.profile = UserProfile(id: "user123", name: "Test User", email: "test@example.com", avatarUrl: nil, notificationsEnabled: false)
        mockUserRepository.updateResult = NSError(domain: "", code: -1, userInfo: nil)

        // When
        viewModel.saveName(authManager: mockAuthManager, newName: "New Name")

        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - uploadAvatar

    func testUploadAvatar_notLoggedIn() {
        // Given
        let loggedOut = AuthManager(authService: MockAuthService(currentAppUser: nil))

        // When
        viewModel.uploadAvatar(image: makeSolidImage(), authManager: loggedOut)

        // Then
        XCTAssertNil(mockStorageService.uploadedData)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testUploadAvatar_success() async {
        // Given
        viewModel.profile = UserProfile(id: "user123", name: "Test User", email: "test@example.com", avatarUrl: nil, notificationsEnabled: false)
        let uploadedURL = URL(string: "https://example.com/avatar.jpg")!
        mockStorageService.uploadResult = .success(uploadedURL)
        mockUserRepository.updateResult = nil

        // When
        viewModel.uploadAvatar(image: makeSolidImage(), authManager: mockAuthManager)

        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertNotNil(mockStorageService.uploadedData)
        XCTAssertEqual(viewModel.profile?.avatarUrl, uploadedURL.absoluteString)
        XCTAssertEqual(mockUserRepository.updatedData["avatarUrl"] as? String, uploadedURL.absoluteString)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testUploadAvatar_uploadError() async {
        // Given
        mockStorageService.uploadResult = .failure(NSError(domain: "", code: -1, userInfo: nil))

        // When
        viewModel.uploadAvatar(image: makeSolidImage(), authManager: mockAuthManager)

        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
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
