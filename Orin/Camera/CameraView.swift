import SwiftUI
import UIKit
import AVFoundation

struct CameraView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var analysisResult = ""
    @State private var customPrompt = "Analyze this image and provide a detailed description."
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(10)
                            .padding()
                        
                        VStack(spacing: 12) {
                            TextField("Enter analysis prompt...", text: $customPrompt, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(2...4)
                                .padding(.horizontal)
                            
                            HStack(spacing: 15) {
                                Button(action: retakePhoto) {
                                    Label("Retake", systemImage: "camera.rotate")
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                }
                                
                                Button(action: analyzePhoto) {
                                    if isProcessing {
                                        HStack {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                            Text("Analyzing...")
                                                .foregroundColor(.white)
                                        }
                                        .padding()
                                    } else {
                                        Label("Analyze", systemImage: "brain.head.profile")
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                                .disabled(isProcessing)
                            }
                        }
                        
                        if !analysisResult.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Analysis Result:")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                Text(analysisResult)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                        }
                        
                    } else {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                                .padding()
                            
                            Text("Take a photo to analyze with AI")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Text("Capture an image and get detailed AI analysis")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Spacer()
                            
                            Button(action: { showCamera = true }) {
                                Label("Take Photo", systemImage: "camera")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("AI Camera")
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $capturedImage, sourceType: .camera)
            }
            .alert("Analysis Status", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func retakePhoto() {
        capturedImage = nil
        analysisResult = ""
        showCamera = true
    }
    
    private func analyzePhoto() {
        guard let image = capturedImage else { return }
        
        isProcessing = true
        analysisResult = ""
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            alertMessage = "Failed to process image"
            showAlert = true
            isProcessing = false
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        guard let url = URL(string: "https://processimagewithgpt4o-ncvbgosopa-uc.a.run.app") else {
            alertMessage = "Invalid endpoint URL"
            showAlert = true
            isProcessing = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = [
            "image": base64String,
            "prompt": customPrompt
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            alertMessage = "Failed to encode request"
            showAlert = true
            isProcessing = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isProcessing = false
                
                if let error = error {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                guard let data = data else {
                    alertMessage = "No data received"
                    showAlert = true
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = json["success"] as? Bool,
                       success,
                       let result = json["result"] as? String {
                        analysisResult = result
                        alertMessage = "Analysis completed successfully!"
                        showAlert = true
                    } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let error = json["error"] as? String {
                        alertMessage = "Analysis failed: \(error)"
                        showAlert = true
                    } else {
                        alertMessage = "Invalid response format"
                        showAlert = true
                    }
                } catch {
                    alertMessage = "Failed to parse response: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }.resume()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct CameraPermissionHelper {
    static func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .authorized:
            completion(true)
        case .restricted, .denied:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
}

#Preview {
    CameraView()
}