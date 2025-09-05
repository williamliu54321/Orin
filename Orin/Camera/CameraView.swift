import SwiftUI
import UIKit
import AVFoundation

// MARK: - Data Models
struct PalmReading: Codable {
    let summary: String
    let lines: PalmLines
    let advice: String
    let vibe: String
    let rating: PalmRating
}

struct PalmLines: Codable {
    let life_line: String
    let heart_line: String
    let head_line: String
    let fate_line: String
}

struct PalmRating: Codable {
    let clarity: Int
    let spiritual_energy: Int
    let introspection: Int
}

struct CameraView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var palmReading: PalmReading?
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
                            if let reading = palmReading {
                                AncientTomeView(palmReading: reading)
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
        palmReading = nil
        showCamera = true
        hasAnimated = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            hasAnimated = true
        }
    }
    
    private func analyzePalm() {
        guard let image = capturedImage else { return }
        
        isProcessing = true
        palmReading = nil
        
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
                       let resultString = json["result"] as? String {
                        
                        // Parse the structured JSON response
                        if let resultData = resultString.data(using: .utf8) {
                            do {
                                let reading = try JSONDecoder().decode(PalmReading.self, from: resultData)
                                palmReading = reading
                                alertMessage = "Your palm has been read successfully!"
                                showAlert = true
                            } catch {
                                // Fallback: treat as plain text if JSON parsing fails
                                let fallbackReading = PalmReading(
                                    summary: resultString,
                                    lines: PalmLines(
                                        life_line: "Your life line shows resilience and strength.",
                                        heart_line: "Your heart line reveals deep emotional intelligence.",
                                        head_line: "Your head line indicates balanced thinking.",
                                        fate_line: "Your fate line suggests an unfolding destiny."
                                    ),
                                    advice: "Trust your intuition and embrace the journey ahead.",
                                    vibe: "mystical",
                                    rating: PalmRating(clarity: 8, spiritual_energy: 8, introspection: 8)
                                )
                                palmReading = fallbackReading
                                alertMessage = "Your palm has been read successfully!"
                                showAlert = true
                            }
                        }
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
    let palmReading: PalmReading
    @State private var showTitle = false
    @State private var showOrnaments = false
    @State private var showSummary = false
    @State private var showLines = false
    @State private var showAdvice = false
    @State private var showRating = false
    
    // Vibe-based theming
    private var vibeTheme: VibeTheme {
        VibeTheme(for: palmReading.vibe)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Tome Header with Vibe-Based Theming
                VStack(spacing: 16) {
                    // Top Ornamental Border
                    if showOrnaments {
                        HStack {
                            Image(systemName: vibeTheme.ornamentIcon)
                                .foregroundColor(vibeTheme.accentColor.opacity(0.8))
                                .font(.title2)
                            
                            Spacer()
                            
                            Image(systemName: vibeTheme.centerIcon)
                                .foregroundColor(vibeTheme.accentColor.opacity(0.8))
                                .font(.title2)
                                .scaleEffect(1.2)
                            
                            Spacer()
                            
                            Image(systemName: vibeTheme.ornamentIcon)
                                .foregroundColor(vibeTheme.accentColor.opacity(0.8))
                                .font(.title2)
                        }
                        .opacity(showOrnaments ? 1 : 0)
                        .animation(.easeIn(duration: 0.8).delay(0.3), value: showOrnaments)
                    }
                    
                    // Title
                    if showTitle {
                        HStack {
                            Image(systemName: vibeTheme.titleIcon)
                                .foregroundColor(vibeTheme.accentColor.opacity(0.9))
                                .font(.title3)
                            
                            Text("Palm Reading Analysis")
                                .font(.custom("Georgia", size: 22))
                                .fontWeight(.medium)
                                .foregroundColor(vibeTheme.accentColor.opacity(0.9))
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                            
                            Image(systemName: vibeTheme.titleIcon)
                                .foregroundColor(vibeTheme.accentColor.opacity(0.9))
                                .font(.title3)
                        }
                        .opacity(showTitle ? 1 : 0)
                        .animation(.easeIn(duration: 0.8).delay(0.1), value: showTitle)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Summary Section
                if showSummary {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(vibeTheme.accentColor)
                            Text("Overview")
                                .font(.custom("Georgia", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(vibeTheme.accentColor)
                        }
                        
                        Text(palmReading.summary)
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(vibeTheme.textColor)
                            .lineSpacing(6)
                    }
                    .padding(20)
                    .background(vibeTheme.cardBackground)
                    .opacity(showSummary ? 1 : 0)
                    .animation(.easeIn(duration: 0.8).delay(0.5), value: showSummary)
                }
                
                // Lines Section
                if showLines {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "hand.draw")
                                .foregroundColor(vibeTheme.accentColor)
                            Text("The Lines Speak")
                                .font(.custom("Georgia", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(vibeTheme.accentColor)
                        }
                        
                        LineItemView(title: "Life Line", description: palmReading.lines.life_line, theme: vibeTheme)
                        LineItemView(title: "Heart Line", description: palmReading.lines.heart_line, theme: vibeTheme)
                        LineItemView(title: "Head Line", description: palmReading.lines.head_line, theme: vibeTheme)
                        LineItemView(title: "Fate Line", description: palmReading.lines.fate_line, theme: vibeTheme)
                    }
                    .padding(20)
                    .background(vibeTheme.cardBackground)
                    .opacity(showLines ? 1 : 0)
                    .animation(.easeIn(duration: 0.8).delay(0.7), value: showLines)
                }
                
                // Advice Section
                if showAdvice {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(vibeTheme.accentColor)
                            Text("Guidance")
                                .font(.custom("Georgia", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(vibeTheme.accentColor)
                        }
                        
                        Text(palmReading.advice)
                            .font(.custom("Georgia", size: 16))
                            .italic()
                            .foregroundColor(vibeTheme.textColor)
                            .lineSpacing(6)
                    }
                    .padding(20)
                    .background(vibeTheme.cardBackground)
                    .opacity(showAdvice ? 1 : 0)
                    .animation(.easeIn(duration: 0.8).delay(0.9), value: showAdvice)
                }
                
                // Rating Section
                if showRating {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(vibeTheme.accentColor)
                            Text("Energy Reading")
                                .font(.custom("Georgia", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(vibeTheme.accentColor)
                        }
                        
                        HStack {
                            RatingBar(label: "Clarity", value: palmReading.rating.clarity, theme: vibeTheme)
                            Spacer()
                            RatingBar(label: "Spiritual Energy", value: palmReading.rating.spiritual_energy, theme: vibeTheme)
                            Spacer()
                            RatingBar(label: "Introspection", value: palmReading.rating.introspection, theme: vibeTheme)
                        }
                    }
                    .padding(20)
                    .background(vibeTheme.cardBackground)
                    .opacity(showRating ? 1 : 0)
                    .animation(.easeIn(duration: 0.8).delay(1.1), value: showRating)
                }
                
                // Bottom Ornamental Border
                if showOrnaments {
                    HStack {
                        Image(systemName: vibeTheme.bottomIcon)
                            .foregroundColor(vibeTheme.accentColor.opacity(0.8))
                            .font(.caption)
                        
                        Spacer()
                        
                        Text(vibeTheme.bottomText)
                            .foregroundColor(vibeTheme.accentColor.opacity(0.7))
                            .font(.caption)
                        
                        Spacer()
                        
                        Image(systemName: vibeTheme.bottomIcon)
                            .foregroundColor(vibeTheme.accentColor.opacity(0.8))
                            .font(.caption)
                    }
                    .padding(.top, 20)
                    .opacity(showOrnaments ? 1 : 0)
                    .animation(.easeIn(duration: 0.8).delay(1.3), value: showOrnaments)
                }
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            startTomeAnimation()
        }
    }
    
    private func startTomeAnimation() {
        withAnimation(.easeIn(duration: 0.5)) {
            showTitle = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.8)) {
                showOrnaments = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeIn(duration: 0.8)) {
                showSummary = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeIn(duration: 0.8)) {
                showLines = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeIn(duration: 0.8)) {
                showAdvice = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeIn(duration: 0.8)) {
                showRating = true
            }
        }
    }
}

struct LineItemView: View {
    let title: String
    let description: String
    let theme: VibeTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("• \(title)")
                .font(.custom("Georgia", size: 14))
                .fontWeight(.medium)
                .foregroundColor(theme.accentColor.opacity(0.8))
            
            Text(description)
                .font(.custom("Georgia", size: 14))
                .foregroundColor(theme.textColor.opacity(0.9))
                .lineSpacing(3)
        }
    }
}

struct RatingBar: View {
    let label: String
    let value: Int
    let theme: VibeTheme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.custom("Georgia", size: 12))
                .foregroundColor(theme.accentColor.opacity(0.8))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 2) {
                ForEach(1...10, id: \.self) { index in
                    Circle()
                        .fill(index <= value ? theme.accentColor.opacity(0.8) : theme.accentColor.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
            
            Text("\(value)/10")
                .font(.custom("Georgia", size: 10))
                .foregroundColor(theme.textColor.opacity(0.7))
        }
    }
}

// MARK: - Vibe Theming System
struct VibeTheme {
    let accentColor: Color
    let textColor: Color
    let cardBackground: AnyShapeStyle
    let titleIcon: String
    let centerIcon: String
    let ornamentIcon: String
    let bottomIcon: String
    let bottomText: String
    
    init(for vibe: String) {
        switch vibe.lowercased() {
        case "mystical":
            accentColor = Color.purple.opacity(0.9)
            textColor = Color(.sRGB, red: 0.4, green: 0.3, blue: 0.5)
            cardBackground = AnyShapeStyle(LinearGradient(
                colors: [Color(.sRGB, red: 0.98, green: 0.95, blue: 0.98), Color(.sRGB, red: 0.94, green: 0.90, blue: 0.96)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            titleIcon = "sparkles"
            centerIcon = "eye"
            ornamentIcon = "sparkles"
            bottomIcon = "sparkles"
            bottomText = "✦ ✦ ✦"
            
        case "ethereal":
            accentColor = Color.cyan.opacity(0.8)
            textColor = Color(.sRGB, red: 0.3, green: 0.4, blue: 0.5)
            cardBackground = AnyShapeStyle(LinearGradient(
                colors: [Color(.sRGB, red: 0.95, green: 0.98, blue: 1.0), Color(.sRGB, red: 0.90, green: 0.95, blue: 0.98)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            titleIcon = "cloud"
            centerIcon = "moon.stars"
            ornamentIcon = "cloud"
            bottomIcon = "wind"
            bottomText = "～ ～ ～"
            
        case "cosmic":
            accentColor = Color.indigo.opacity(0.9)
            textColor = Color(.sRGB, red: 0.3, green: 0.3, blue: 0.4)
            cardBackground = AnyShapeStyle(LinearGradient(
                colors: [Color(.sRGB, red: 0.94, green: 0.94, blue: 0.98), Color(.sRGB, red: 0.88, green: 0.88, blue: 0.96)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            titleIcon = "star.fill"
            centerIcon = "moon.stars.fill"
            ornamentIcon = "star"
            bottomIcon = "star.fill"
            bottomText = "★ ★ ★"
            
        case "uplifting":
            accentColor = Color.orange.opacity(0.9)
            textColor = Color(.sRGB, red: 0.5, green: 0.3, blue: 0.2)
            cardBackground = AnyShapeStyle(LinearGradient(
                colors: [Color(.sRGB, red: 1.0, green: 0.98, blue: 0.92), Color(.sRGB, red: 0.98, green: 0.94, blue: 0.88)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            titleIcon = "sun.max.fill"
            centerIcon = "flame.fill"
            ornamentIcon = "sun.max"
            bottomIcon = "flame"
            bottomText = "☀ ☀ ☀"
            
        case "shadow":
            accentColor = Color.blue.opacity(0.8)
            textColor = Color(.sRGB, red: 0.2, green: 0.3, blue: 0.4)
            cardBackground = AnyShapeStyle(LinearGradient(
                colors: [Color(.sRGB, red: 0.92, green: 0.94, blue: 0.98), Color(.sRGB, red: 0.88, green: 0.90, blue: 0.96)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            titleIcon = "moon.fill"
            centerIcon = "eye.trianglebadge.exclamationmark"
            ornamentIcon = "moon"
            bottomIcon = "moon.phase.waxing.crescent"
            bottomText = "◐ ◑ ◒"
            
        default: // fallback to mystical
            accentColor = Color.purple.opacity(0.9)
            textColor = Color(.sRGB, red: 0.4, green: 0.3, blue: 0.5)
            cardBackground = AnyShapeStyle(LinearGradient(
                colors: [Color(.sRGB, red: 0.98, green: 0.95, blue: 0.98), Color(.sRGB, red: 0.94, green: 0.90, blue: 0.96)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            titleIcon = "sparkles"
            centerIcon = "eye"
            ornamentIcon = "sparkles"
            bottomIcon = "sparkles"
            bottomText = "✦ ✦ ✦"
        }
    }
}

#Preview {
    CameraView()
}