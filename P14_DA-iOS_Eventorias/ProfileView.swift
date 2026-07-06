import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(AuthManager.self) var authManager
    @State private var viewModel = ProfileViewModel()
    @FocusState private var isNameFocused: Bool
    
    @State private var showSourceSelector = false
    @State private var showImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.12, blue: 0.14)
                .ignoresSafeArea()
                .onTapGesture {
                    isNameFocused = false
                }
            
            VStack(alignment: .leading, spacing: 24) {
                // Header: Title and Avatar
                HStack {
                    Text("User profile")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Avatar
                    Button(action: {
                        showSourceSelector = true
                    }) {
                        ZStack(alignment: .bottomTrailing) {
                            if let avatarUrl = viewModel.profile?.avatarUrl, let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(ProgressView())
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                            }
                            
                            // Edit icon badge
                            Circle()
                                .fill(Color(red: 0.85, green: 0.1, blue: 0.15))
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Image(systemName: "pencil")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 4, y: 4)
                        }
                    }
                    .confirmationDialog("Choose Avatar", isPresented: $showSourceSelector, titleVisibility: .visible) {
                        Button("Camera") {
                            imageSource = .camera
                            showImagePicker = true
                        }
                        Button("Photo Library") {
                            imageSource = .photoLibrary
                            showImagePicker = true
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                    .fullScreenCover(isPresented: $showImagePicker) {
                        ImagePicker(selectedImage: $selectedImage, sourceType: imageSource)
                            .ignoresSafeArea()
                    }
                    .onChange(of: selectedImage) { _, newImage in
                        if let image = newImage {
                            viewModel.uploadAvatar(image: image, authManager: authManager)
                        }
                    }
                }
                .padding(.top, 16)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    // Name Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Name", text: Binding(
                            get: { viewModel.profile?.name ?? "" },
                            set: { viewModel.profile?.name = $0 }
                        ))
                        .focused($isNameFocused)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .submitLabel(.done)
                        .onSubmit {
                            isNameFocused = false
                        }
                        .onChange(of: isNameFocused) { oldValue, newValue in
                            if oldValue == true && newValue == false {
                                if let newName = viewModel.profile?.name {
                                    viewModel.saveName(authManager: authManager, newName: newName)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(white: 0.3))
                    .cornerRadius(8)
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("E-mail")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(viewModel.profile?.email ?? "")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color(white: 0.3))
                    .cornerRadius(8)
                    
                    // Notifications Toggle
                    Toggle(isOn: Binding(
                        get: { viewModel.profile?.notificationsEnabled ?? false },
                        set: { newValue in viewModel.toggleNotifications(authManager: authManager, isOn: newValue) }
                    )) {
                        Text("Notifications")
                            .foregroundColor(.white)
                    }
                    .tint(Color(red: 0.85, green: 0.1, blue: 0.15))
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.fetchProfile(authManager: authManager)
        }
    }
}

#Preview {
    let mockAuth = AuthManager()
    return ProfileView()
        .environment(mockAuth)
}
