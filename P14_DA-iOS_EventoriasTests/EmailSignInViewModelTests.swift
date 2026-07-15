import XCTest
import FirebaseAuth
@testable import P14_DA_iOS_Eventorias

@MainActor
class EmailSignInViewModelTests: XCTestCase {
    var viewModel: EmailSignInViewModel!
    var mockAuthService: MockAuthService!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        viewModel = EmailSignInViewModel(authService: mockAuthService)
    }
    
    func testAuthenticate_SignIn_Success() async {
        viewModel.email = "test@example.com"
        viewModel.password = "password"
        viewModel.isRegistering = false
        
        mockAuthService.signInResult = nil // success is nil error
        
        viewModel.authenticate()
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.errorMessage.isEmpty)
    }

    func testAuthenticate_SignIn_Failure() async {
        viewModel.email = "test@example.com"
        viewModel.password = "wrongpassword"
        viewModel.isRegistering = false
        
        let error = NSError(domain: AuthErrorDomain, code: AuthErrorCode.wrongPassword.rawValue, userInfo: nil)
        mockAuthService.signInResult = .failure(error)
        
        viewModel.authenticate()
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Email ou mot de passe incorrect.")
    }

    func testAuthenticate_Register_Success() async {
        viewModel.email = "test@example.com"
        viewModel.password = "StrongPass1!" // Needs 20+ chars? No, the validation says > 20 chars! wait
        // Let's check validatePassword in EmailSignInViewModel.swift: count < 20.
        viewModel.password = "SuperStrongPassword123!" // 23 chars
        viewModel.isRegistering = true
        
        mockAuthService.createUserResult = nil
        
        viewModel.authenticate()
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.errorMessage.isEmpty)
    }

    func testAuthenticate_Register_WeakPassword() async {
        viewModel.email = "test@example.com"
        viewModel.password = "weak"
        viewModel.isRegistering = true
        
        viewModel.authenticate()
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Le mot de passe doit contenir au moins 20 caractères.")
    }
    
    func testToggleRegistering() {
        XCTAssertFalse(viewModel.isRegistering)
        viewModel.errorMessage = "Some error"
        
        viewModel.toggleRegistering()
        
        XCTAssertTrue(viewModel.isRegistering)
        XCTAssertTrue(viewModel.errorMessage.isEmpty)
    }
}
