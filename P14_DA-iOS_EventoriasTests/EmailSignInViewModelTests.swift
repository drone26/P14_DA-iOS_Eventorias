//
//  EmailSignInViewModelTests.swift
//  EmailSignInViewModelTests
//
//  Created by Mathieu ARRIO on 09/07/2026.
//

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
    
    // MARK: - Register error path & handleError mappings
    
    func testAuthenticate_Register_Failure_EmailAlreadyInUse() async {
        viewModel.email = "test@example.com"
        viewModel.password = "SuperStrongPassword123!"
        viewModel.isRegistering = true
        
        mockAuthService.createUserResult = .failure(authError(.emailAlreadyInUse))
        
        viewModel.authenticate()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Un compte existe déjà pour cette adresse email.")
    }
    
    func testHandleError_WeakPassword() async {
        await assertSignInError(.weakPassword, message: "Le mot de passe est trop faible. Il doit contenir au moins 20 caractères.")
    }
    
    func testHandleError_InvalidEmail() async {
        await assertSignInError(.invalidEmail, message: "L'adresse email n'est pas valide.")
    }
    
    func testHandleError_UserNotFound() async {
        await assertSignInError(.userNotFound, message: "Email ou mot de passe incorrect.")
    }
    
    func testHandleError_InternalError() async {
        await assertSignInError(.internalError, message: "Une erreur interne s'est produite. Veuillez réessayer.")
    }
    
    func testHandleError_UnhandledAuthCode_UsesLocalizedDescription() async {
        // A valid AuthErrorCode that the switch does not special-case → default branch.
        let error = authError(.tooManyRequests)
        viewModel.isRegistering = false
        mockAuthService.signInResult = .failure(error)
        
        viewModel.authenticate()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(viewModel.errorMessage, error.localizedDescription)
    }
    
    func testHandleError_NonAuthError_UsesLocalizedDescription() async {
        // A code that maps to no AuthErrorCode → else branch.
        let error = NSError(domain: "CustomDomain", code: 999_999, userInfo: [NSLocalizedDescriptionKey: "Custom failure"])
        viewModel.isRegistering = false
        mockAuthService.signInResult = .failure(error)
        
        viewModel.authenticate()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(viewModel.errorMessage, "Custom failure")
    }
    
    // MARK: - Password validation rules
    
    func testValidatePassword_TooLong() {
        assertRegisterValidation(String(repeating: "a", count: 4097),
                                 message: "Le mot de passe ne peut excéder 4096 caractères.")
    }
    
    func testValidatePassword_MissingUppercase() {
        assertRegisterValidation("abcdefghij1234567890!",
                                 message: "Le mot de passe doit contenir au moins une lettre majuscule.")
    }
    
    func testValidatePassword_MissingLowercase() {
        assertRegisterValidation("ABCDEFGHIJ1234567890!",
                                 message: "Le mot de passe doit contenir au moins une lettre minuscule.")
    }
    
    func testValidatePassword_MissingDigit() {
        assertRegisterValidation("AbcdefghijKlmnopqrst!",
                                 message: "Le mot de passe doit contenir au moins un chiffre.")
    }
    
    func testValidatePassword_MissingSpecialCharacter() {
        assertRegisterValidation("Abcdefghij1234567890",
                                 message: "Le mot de passe doit contenir au moins un caractère spécial.")
    }
    
    // MARK: - Helpers
    
    private func authError(_ code: AuthErrorCode) -> NSError {
        NSError(domain: AuthErrorDomain, code: code.rawValue, userInfo: nil)
    }
    
    private func assertSignInError(_ code: AuthErrorCode, message: String,
                                   file: StaticString = #filePath, line: UInt = #line) async {
        viewModel.isRegistering = false
        mockAuthService.signInResult = .failure(authError(code))
        
        viewModel.authenticate()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertFalse(viewModel.isLoading, file: file, line: line)
        XCTAssertEqual(viewModel.errorMessage, message, file: file, line: line)
    }
    
    private func assertRegisterValidation(_ password: String, message: String,
                                          file: StaticString = #filePath, line: UInt = #line) {
        viewModel.email = "test@example.com"
        viewModel.password = password
        viewModel.isRegistering = true
        
        viewModel.authenticate()
        
        // Validation fails before any network call, so loading never starts.
        XCTAssertFalse(viewModel.isLoading, file: file, line: line)
        XCTAssertEqual(viewModel.errorMessage, message, file: file, line: line)
        XCTAssertTrue(mockAuthService.createUserResult == nil, file: file, line: line)
    }
}
