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
    @State private var hasAnimated = false
    
    let palmAnalysisPrompt = "Analyze this palm image for palm reading. Provide insights about the person's life path, personality traits, love life, career prospects, and spiritual journey based on the lines, mounts, and overall palm structure. Make it mystical and spiritual in tone, as if you're a wise palm reader with ancient knowledge."
    
    var body: some View {
        ZStack {
            // Background gradient matching onboarding style
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.4),
                    Color.indigo.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                        if let image = capturedImage {
                            VStack(spacing: 20) {
                                // Palm image display
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .cornerRadius(20)
                                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                                    .padding(.horizontal, 20)
                                    .scaleEffect(hasAnimated ? 1.0 : 0.95)
                                    .opacity(hasAnimated ? 1 : 0)
                                    .animation(.easeOut(duration: 0.6).delay(0.1), value: hasAnimated)
                                
                                // Action buttons
                                HStack(spacing: 16) {
                                    Button(action: retakePhoto) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "camera.rotate")
                                            Text("Retake")
                                        }
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white.opacity(0.2))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                    }
                                    
                                    Button(action: analyzePalm) {
                                        HStack(spacing: 8) {
                                            if isProcessing {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(0.8)
                                                Text("Reading...")
                                            } else {
                                                Image(systemName: "hand.raised")
                                                Text("Read Palm")
                                            }
                                        }
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white.opacity(0.25))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                                )
                                        )
                                        .shadow(color: Color.white.opacity(0.2), radius: 8, x: 0, y: 0)
                                    }
                                    .disabled(isProcessing)
                                }
                                .opacity(hasAnimated ? 1 : 0)
                                .animation(.easeOut(duration: 0.6).delay(0.3), value: hasAnimated)
                            }
                            
                            // Ancient Tome Reading Results
                            if !analysisResult.isEmpty {
                                AncientTomeView(reading: analysisResult)
                                    .padding(.horizontal, 16)
                                    .opacity(hasAnimated ? 1 : 0)
                                    .animation(.easeOut(duration: 1.0).delay(0.5), value: hasAnimated)
                            }
                        
                        } else {
                            // Initial state - capture palm
                            VStack(spacing: 24) {
                                Spacer()
                                
                                VStack(spacing: 20) {
                                    Image(systemName: "hand.raised.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.white.opacity(0.8))
                                        .scaleEffect(hasAnimated ? 1.0 : 0.8)
                                        .opacity(hasAnimated ? 1 : 0)
                                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: hasAnimated)
                                    
                                    VStack(spacing: 12) {
                                        Text("Discover Your Destiny")
                                            .font(.largeTitle)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                            .opacity(hasAnimated ? 1 : 0)
                                            .offset(y: hasAnimated ? 0 : 20)
                                            .animation(.easeOut(duration: 0.8).delay(0.4), value: hasAnimated)
                                        
                                        Text("Let the ancient art of palm reading reveal the secrets written in your hands")
                                            .font(.body)
                                            .foregroundColor(.white.opacity(0.9))
                                            .multilineTextAlignment(.center)
                                            .lineSpacing(4)
                                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                                            .opacity(hasAnimated ? 1 : 0)
                                            .offset(y: hasAnimated ? 0 : 20)
                                            .animation(.easeOut(duration: 0.8).delay(0.6), value: hasAnimated)
                                    }
                                }
                                .padding(.horizontal, 32)
                                
                                Spacer()
                                
                                VStack(spacing: 16) {
                                    Button(action: { showCamera = true }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "camera.fill")
                                            Text("Capture Your Palm")
                                        }
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 25)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.white.opacity(0.25),
                                                            Color.white.opacity(0.15)
                                                        ],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 25)
                                                        .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                                )
                                        )
                                        .shadow(color: Color.white.opacity(0.2), radius: 10, x: 0, y: 0)
                                    }
                                    .scaleEffect(hasAnimated ? 1.0 : 0.8)
                                    .opacity(hasAnimated ? 1 : 0)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.8), value: hasAnimated)
                                    
                                    Text("Hold your palm steady and capture a clear image")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .opacity(hasAnimated ? 1 : 0)
                                        .animation(.easeOut(duration: 0.8).delay(1.0), value: hasAnimated)
                                }
                                .padding(.bottom, 60)
                            }
                        }
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $capturedImage, sourceType: .camera)
            }
            .alert("Palm Reading", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                hasAnimated = true
            }
        }
    }
    
    private func retakePhoto() {
        capturedImage = nil
        analysisResult = ""
        showCamera = true
        hasAnimated = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            hasAnimated = true
        }
    }
    
    private func analyzePalm() {
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
            "prompt": palmAnalysisPrompt
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
                        alertMessage = "Your palm has been read successfully!"
                        showAlert = true
                    } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let error = json["error"] as? String {
                        alertMessage = "Reading failed: \(error)"
                        showAlert = true
                    } else {
                        alertMessage = "The spirits are unclear today. Please try again."
                        showAlert = true
                    }
                } catch {
                    alertMessage = "Unable to interpret the reading: \(error.localizedDescription)"
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

struct AncientTomeView: View {
    let reading: String
    @State private var displayedText = ""
    @State private var showTitle = false
    @State private var showOrnaments = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tome Header with Ornamental Border
            VStack(spacing: 16) {
                // Top Ornamental Border
                if showOrnaments {
                    HStack {
                        Image(systemName: "fleuron")
                            .foregroundColor(.yellow.opacity(0.8))
                            .font(.title2)
                        
                        Spacer()
                        
                        Image(systemName: "eye")
                            .foregroundColor(.yellow.opacity(0.8))
                            .font(.title2)
                            .scaleEffect(1.2)
                        
                        Spacer()
                        
                        Image(systemName: "fleuron")
                            .foregroundColor(.yellow.opacity(0.8))
                            .font(.title2)
                    }
                    .opacity(showOrnaments ? 1 : 0)
                    .animation(.easeIn(duration: 0.8).delay(0.3), value: showOrnaments)
                }
                
                // Title
                if showTitle {
                    HStack {
                        Image(systemName: "book.closed")
                            .foregroundColor(.yellow.opacity(0.9))
                            .font(.title3)
                        
                        Text("Palm Reading Analysis")
                            .font(.custom("Georgia", size: 22))
                            .fontWeight(.medium)
                            .foregroundColor(.yellow.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        
                        Image(systemName: "book.closed")
                            .foregroundColor(.yellow.opacity(0.9))
                            .font(.title3)
                    }
                    .opacity(showTitle ? 1 : 0)
                    .animation(.easeIn(duration: 0.8).delay(0.1), value: showTitle)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Parchment Background with Reading
            VStack(alignment: .leading, spacing: 0) {
                Text(displayedText)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(Color(.sRGB, red: 0.4, green: 0.3, blue: 0.2))
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(
                // Parchment texture effect
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(.sRGB, red: 0.96, green: 0.92, blue: 0.84),
                                    Color(.sRGB, red: 0.94, green: 0.88, blue: 0.78)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Aged paper effect
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.brown.opacity(0.05),
                                    Color.brown.opacity(0.15)
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 200
                            )
                        )
                    
                    // Golden border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.yellow.opacity(0.6),
                                    Color.orange.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Bottom Ornamental Border
            if showOrnaments {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow.opacity(0.8))
                        .font(.caption)
                    
                    Spacer()
                    
                    Text("✦ ✦ ✦")
                        .foregroundColor(.yellow.opacity(0.7))
                        .font(.caption)
                    
                    Spacer()
                    
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow.opacity(0.8))
                        .font(.caption)
                }
                .padding(.top, 12)
                .opacity(showOrnaments ? 1 : 0)
                .animation(.easeIn(duration: 0.8).delay(0.5), value: showOrnaments)
            }
        }
        .onAppear {
            startTomeAnimation()
        }
    }
    
    private func startTomeAnimation() {
        // Show title first
        withAnimation(.easeIn(duration: 0.5)) {
            showTitle = true
        }
        
        // Show ornaments
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.8)) {
                showOrnaments = true
            }
        }
        
        // Start typewriter effect for text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            animateText()
        }
    }
    
    private func animateText() {
        displayedText = ""
        let characters = Array(reading)
        
        for (index, character) in characters.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.02) {
                displayedText.append(character)
            }
        }
    }
}

#Preview {
    CameraView()
}