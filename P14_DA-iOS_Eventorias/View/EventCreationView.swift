import SwiftUI
import PhotosUI

struct EventCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) var authManager
    @State private var viewModel = EventCreationViewModel()
    
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.12, blue: 0.14)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Title
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Title")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("New event", text: $viewModel.title)
                                .foregroundColor(.white)
                                .accessibilityIdentifier("event_title_field")
                        }
                        .padding()
                        .background(Color(white: 0.3))
                        .cornerRadius(8)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextEditor(text: $viewModel.description)
                                .frame(height: 100)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .foregroundColor(.white)
                                .accessibilityIdentifier("event_description_field")
                        }
                        .padding()
                        .background(Color(white: 0.3))
                        .cornerRadius(8)
                        
                        // Date and Time
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .accessibilityIdentifier("event_date_picker")
                            }
                            .padding()
                            .background(Color(white: 0.3))
                            .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                DatePicker("", selection: $viewModel.time, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .accessibilityIdentifier("event_time_picker")
                            }
                            .padding()
                            .background(Color(white: 0.3))
                            .cornerRadius(8)
                        }
                        
                        // Address
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Address")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Enter full address", text: $viewModel.address)
                                .foregroundColor(.white)
                                .accessibilityIdentifier("event_address_field")
                        }
                        .padding()
                        .background(Color(white: 0.3))
                        .cornerRadius(8)
                        
                        // Image selection buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                showCamera = true
                            }) {
                                Image(systemName: "camera")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white)
                                    .cornerRadius(16)
                            }
                            .accessibilityIdentifier("camera_button")
                            
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Image(systemName: "paperclip")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color(red: 0.85, green: 0.1, blue: 0.15))
                                    .cornerRadius(16)
                            }
                            .accessibilityIdentifier("photo_library_button")
                            .onChange(of: selectedPhotoItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        viewModel.selectedImage = image
                                    }
                                }
                            }
                        }
                        .padding(.top, 16)
                        
                        // Image preview
                        if let image = viewModel.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.top, 16)
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                }
                
                // Validate Button
                Button(action: {
                    viewModel.createEvent(authManager: authManager) { success in
                        if success {
                            dismiss()
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Validate")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.85, green: 0.1, blue: 0.15))
                    .cornerRadius(8)
                }
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier("save_event_button")
                .padding()
            }
        }
        .navigationTitle("Creation of an event")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: .camera)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    NavigationView {
        EventCreationView()
    }
}
