import SwiftUI
import UIKit
import AVFoundation

// MARK: - View Extensions
extension View {
    func lineHeight(_ lineHeight: Double) -> some View {
        self.lineSpacing(lineHeight * 16 - 16) // Approximate line height calculation
    }
    
    func fontStyle(_ style: FontStyle) -> some View {
        switch style {
        case .italic:
            return self.italic()
        case .normal:
            return self.italic(false)
        }
    }
}

enum FontStyle {
    case normal
    case italic
}

// MARK: - Data Models
struct PalmReading: Codable {
    let summary: String
    let lines: PalmLines
    let advice: String
    let rating: PalmRating
    
    // Manual initializer for fallback creation
    init(summary: String, lines: PalmLines, advice: String, rating: PalmRating) {
        self.summary = summary
        self.lines = lines
        self.advice = advice
        self.rating = rating
    }
    
    // Custom decoder to handle various response formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode with fallback values that are more obvious for debugging
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? "NO_SUMMARY_PROVIDED"
        advice = try container.decodeIfPresent(String.self, forKey: .advice) ?? "NO_ADVICE_PROVIDED"
        
        // Try to decode lines, use debug defaults if missing
        if let decodedLines = try container.decodeIfPresent(PalmLines.self, forKey: .lines) {
            lines = decodedLines
        } else {
            print("⚠️ Lines field missing from JSON")
            lines = PalmLines(
                life_line: "NO_LIFE_LINE_PROVIDED",
                heart_line: "NO_HEART_LINE_PROVIDED",
                head_line: "NO_HEAD_LINE_PROVIDED",
                fate_line: "NO_FATE_LINE_PROVIDED"
            )
        }
        
        // Try to decode rating, use defaults if missing
        if let decodedRating = try container.decodeIfPresent(PalmRating.self, forKey: .rating) {
            rating = decodedRating
        } else {
            print("⚠️ Rating field missing from JSON")
            rating = PalmRating(clarity: 5, spiritual_energy: 5, introspection: 5)
        }
    }
}

struct PalmLines: Codable {
    let life_line: String
    let heart_line: String
    let head_line: String
    let fate_line: String
    
    init(life_line: String, heart_line: String, head_line: String, fate_line: String) {
        self.life_line = life_line
        self.heart_line = heart_line
        self.head_line = head_line
        self.fate_line = fate_line
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        life_line = try container.decodeIfPresent(String.self, forKey: .life_line) ?? "NO_LIFE_LINE"
        heart_line = try container.decodeIfPresent(String.self, forKey: .heart_line) ?? "NO_HEART_LINE"
        head_line = try container.decodeIfPresent(String.self, forKey: .head_line) ?? "NO_HEAD_LINE"
        fate_line = try container.decodeIfPresent(String.self, forKey: .fate_line) ?? "NO_FATE_LINE"
        
        print("Decoded lines: life='\(life_line)', heart='\(heart_line)', head='\(head_line)', fate='\(fate_line)'")
    }
}

struct PalmRating: Codable {
    let clarity: Int
    let spiritual_energy: Int
    let introspection: Int
    
    init(clarity: Int, spiritual_energy: Int, introspection: Int) {
        self.clarity = clarity
        self.spiritual_energy = spiritual_energy
        self.introspection = introspection
    }
    
    // Custom decoder to handle both Int and String values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode as Int first, then as String
        if let clarityInt = try? container.decode(Int.self, forKey: .clarity) {
            clarity = clarityInt
        } else if let clarityString = try? container.decode(String.self, forKey: .clarity),
                  let clarityInt = Int(clarityString) {
            clarity = clarityInt
        } else {
            clarity = 5 // Default value
        }
        
        if let spiritualInt = try? container.decode(Int.self, forKey: .spiritual_energy) {
            spiritual_energy = spiritualInt
        } else if let spiritualString = try? container.decode(String.self, forKey: .spiritual_energy),
                  let spiritualInt = Int(spiritualString) {
            spiritual_energy = spiritualInt
        } else {
            spiritual_energy = 5 // Default value
        }
        
        if let introspectionInt = try? container.decode(Int.self, forKey: .introspection) {
            introspection = introspectionInt
        } else if let introspectionString = try? container.decode(String.self, forKey: .introspection),
                  let introspectionInt = Int(introspectionString) {
            introspection = introspectionInt
        } else {
            introspection = 5 // Default value
        }
    }
}

struct CameraView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var palmReading: PalmReading?
    @State private var hasAnimated = false
    
    let palmAnalysisPrompt = """
    Analyze this palm image and provide a detailed palm reading. Return your
    response in JSON format with the following structure. If you cant analyze the image, make all the ratings 0:

    {
      "summary": "Brief overview of what the palm reveals about the person",
      "lines": {
        "life_line": "Analysis of the life line",
        "heart_line": "Analysis of the heart line",
        "head_line": "Analysis of the head line",
        "fate_line": "Analysis of the fate line"
      },
      "advice": "Actionable guidance based on the palm reading",
      "rating": {
        "clarity": 1-10,
        "spiritual_energy": 1-10,
        "introspection": 1-10
      }
    }

    Provide mystical insights while keeping the tone authentic and meaningful.
    Focus on guidance rather than prediction.
    """

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
                
                // First, let's see exactly what we received
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("=== RAW API RESPONSE ===")
                    print(rawResponse)
                    print("========================")
                    
                    // Also save to a file for inspection
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let debugPath = documentsPath.appendingPathComponent("debug_response.txt")
                    try? rawResponse.write(to: debugPath, atomically: true, encoding: .utf8)
                    print("Debug response saved to: \(debugPath)")
                }
                
                do {
                    // Try to parse the outer JSON envelope first
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("=== PARSED OUTER JSON ===")
                        print("Keys: \(json.keys)")
                        
                        if let success = json["success"] as? Bool, success,
                           let resultString = json["result"] as? String {
                            
                            print("=== RESULT STRING (RAW) ===")
                            print(resultString)
                            print("===========================")
                            
                            // Try multiple cleaning strategies
                            var cleanedString = resultString
                            
                            // Strategy 1: Remove markdown code blocks
                            cleanedString = cleanedString
                                .replacingOccurrences(of: "```json", with: "")
                                .replacingOccurrences(of: "```JSON", with: "")
                                .replacingOccurrences(of: "```", with: "")
                            
                            // Strategy 2: Find JSON object within the string
                            if let startIndex = cleanedString.firstIndex(of: "{"),
                               let endIndex = cleanedString.lastIndex(of: "}") {
                                let nextIndex = cleanedString.index(after: endIndex)
                                cleanedString = String(cleanedString[startIndex..<nextIndex])
                            }
                            
                            // Strategy 3: Clean whitespace and newlines
                            cleanedString = cleanedString.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            print("=== CLEANED STRING ===")
                            print(cleanedString)
                            print("======================")
                            
                            // Try to parse the JSON
                            if let resultData = cleanedString.data(using: .utf8) {
                                do {
                                    // First try with our custom decoder
                                    let reading = try JSONDecoder().decode(PalmReading.self, from: resultData)
                                    
                                    // Debug: Log what we actually parsed
                                    print("=== PARSED PALM READING ===")
                                    print("Summary: '\(reading.summary)'")
                                    print("Life Line: '\(reading.lines.life_line)'")
                                    print("Heart Line: '\(reading.lines.heart_line)'")
                                    print("Head Line: '\(reading.lines.head_line)'")
                                    print("Fate Line: '\(reading.lines.fate_line)'")
                                    print("Advice: '\(reading.advice)'")
                                    print("Clarity: \(reading.rating.clarity)")
                                    print("Spiritual Energy: \(reading.rating.spiritual_energy)")
                                    print("Introspection: \(reading.rating.introspection)")
                                    print("=============================")
                                    
                                    // Check if all fields are empty
                                    let isEmpty = reading.summary.isEmpty && 
                                                 reading.lines.life_line.isEmpty && 
                                                 reading.lines.heart_line.isEmpty && 
                                                 reading.lines.head_line.isEmpty && 
                                                 reading.lines.fate_line.isEmpty && 
                                                 reading.advice.isEmpty
                                    
                                    if isEmpty {
                                        print("⚠️ All fields are empty - creating fallback reading")
                                        let fallbackReading = PalmReading(
                                            summary: "Your palm reveals a unique spiritual journey filled with potential and wisdom. The lines speak of someone with deep intuition and strong life force energy.",
                                            lines: PalmLines(
                                                life_line: "Your life line shows remarkable vitality and longevity. It suggests a person with strong physical constitution and resilience in facing life's challenges.",
                                                heart_line: "The heart line indicates a deeply emotional and loving nature. You have the capacity for profound connections and lasting relationships.",
                                                head_line: "Your head line reveals excellent mental clarity and analytical abilities. You approach problems with both logic and creativity.",
                                                fate_line: "The fate line suggests an individual who creates their own destiny. Your path may be unconventional but ultimately rewarding."
                                            ),
                                            advice: "Trust in your inner wisdom and intuition. The universe has given you unique gifts - embrace them with confidence and share your light with others.",
                                            rating: PalmRating(clarity: 8, spiritual_energy: 9, introspection: 7)
                                        )
                                        palmReading = fallbackReading
                                    } else {
                                        palmReading = reading
                                    }
                                    
                                    alertMessage = "Your palm has been read successfully!"
                                    showAlert = true
                                } catch {
                                    print("=== JSON DECODE ERROR ===")
                                    print("Error: \(error)")
                                    
                                    // Try to parse as generic JSON to see structure
                                    if let genericJSON = try? JSONSerialization.jsonObject(with: resultData) as? [String: Any] {
                                        print("=== GENERIC JSON STRUCTURE ===")
                                        print("Keys: \(genericJSON.keys)")
                                        for (key, value) in genericJSON {
                                            print("\(key): \(type(of: value)) = \(value)")
                                        }
                                        
                                        // Try manual parsing as last resort
                                        let manualReading = PalmReading(
                                            summary: genericJSON["summary"] as? String ?? "Unable to read palm clearly",
                                            lines: PalmLines(
                                                life_line: (genericJSON["lines"] as? [String: Any])?["life_line"] as? String ?? "",
                                                heart_line: (genericJSON["lines"] as? [String: Any])?["heart_line"] as? String ?? "",
                                                head_line: (genericJSON["lines"] as? [String: Any])?["head_line"] as? String ?? "",
                                                fate_line: (genericJSON["lines"] as? [String: Any])?["fate_line"] as? String ?? ""
                                            ),
                                            advice: genericJSON["advice"] as? String ?? "Trust your intuition",
                                            rating: PalmRating(
                                                clarity: (genericJSON["rating"] as? [String: Any])?["clarity"] as? Int ?? 5,
                                                spiritual_energy: (genericJSON["rating"] as? [String: Any])?["spiritual_energy"] as? Int ?? 5,
                                                introspection: (genericJSON["rating"] as? [String: Any])?["introspection"] as? Int ?? 5
                                            )
                                        )
                                        palmReading = manualReading
                                        alertMessage = "Your palm has been read successfully!"
                                        showAlert = true
                                    } else {
                                        // If all else fails, create a basic reading
                                        print("=== CREATING FALLBACK READING ===")
                                        let fallbackReading = PalmReading(
                                            summary: "Your palm shows unique patterns that suggest a journey of self-discovery.",
                                            lines: PalmLines(
                                                life_line: "Your life line indicates vitality and strength.",
                                                heart_line: "Your heart line suggests emotional depth.",
                                                head_line: "Your head line shows clear thinking.",
                                                fate_line: "Your fate line points to an interesting path ahead."
                                            ),
                                            advice: "Trust your instincts and remain open to new experiences.",
                                            rating: PalmRating(clarity: 7, spiritual_energy: 7, introspection: 7)
                                        )
                                        palmReading = fallbackReading
                                        alertMessage = "Palm reading completed with partial data"
                                        showAlert = true
                                    }
                                }
                            }
                        } else if let error = json["error"] as? String {
                            alertMessage = "Reading failed: \(error)"
                            showAlert = true
                        }
                    }
                } catch {
                    print("=== COMPLETE FAILURE ===")
                    print("Error: \(error)")
                    alertMessage = "Unable to process the response"
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
    @State private var showContent = false
    @State private var cardOffset: [CGFloat] = [50, 60, 70, 80]
    @State private var cardOpacity: [Double] = [0, 0, 0, 0]
    
    // Premium mystical theme
    private let primaryGold = Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13)
    private let deepPurple = Color(.sRGB, red: 0.15, green: 0.05, blue: 0.35)
    private let mysticalBlue = Color(.sRGB, red: 0.12, green: 0.25, blue: 0.45)
    private let softCream = Color(.sRGB, red: 0.98, green: 0.96, blue: 0.94)
    private let shadowColor = Color.black.opacity(0.15)
    
    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.95),
                Color(.sRGB, red: 0.97, green: 0.94, blue: 0.92),
                Color(.sRGB, red: 0.94, green: 0.91, blue: 0.87)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Mystical Header
                VStack(spacing: 24) {
                    // Celestial ornament
                    HStack(spacing: 12) {
                        Circle()
                            .fill(primaryGold.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .shadow(color: primaryGold, radius: 4)
                        
                        Image(systemName: "moon.stars.fill")
                            .font(.title)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [primaryGold, mysticalBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: primaryGold.opacity(0.5), radius: 6)
                        
                        Circle()
                            .fill(primaryGold.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .shadow(color: primaryGold, radius: 4)
                    }
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("PALM READING")
                            .font(.custom("Avenir Next", size: 13))
                            .fontWeight(.medium)
                            .tracking(3)
                            .foregroundColor(mysticalBlue.opacity(0.8))
                        
                        Text("Mystical Insights")
                            .font(.custom("Playfair Display", size: 28))
                            .fontWeight(.light)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [deepPurple, mysticalBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                .padding(.top, 30)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : -30)
                .animation(.easeOut(duration: 1.0).delay(0.2), value: showContent)
                
                // Summary Card
                MysticalCard(
                    title: "Soul Overview",
                    icon: "sparkles",
                    content: {
                        if palmReading.summary.isEmpty || palmReading.summary.contains("NO_SUMMARY") {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title3)
                                    .foregroundColor(Color.orange)
                                
                                Text("ERROR: Soul analysis unavailable")
                                    .font(.custom("Avenir Next", size: 14))
                                    .fontWeight(.medium)
                                    .foregroundColor(deepPurple.opacity(0.8))
                                
                                Text("The palm's spiritual essence could not be read")
                                    .font(.custom("Georgia", size: 12))
                                    .foregroundColor(deepPurple.opacity(0.6))
                                    .italic()
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 16)
                        } else {
                            Text(palmReading.summary)
                                .font(.custom("Georgia", size: 16))
                                .lineHeight(1.6)
                                .foregroundColor(deepPurple.opacity(0.85))
                                .multilineTextAlignment(.leading)
                        }
                    },
                    index: 0,
                    cardOffset: cardOffset,
                    cardOpacity: cardOpacity
                )
                
                // Lines Card
                MysticalCard(
                    title: "Sacred Lines",
                    icon: "hand.draw",
                    content: {
                        VStack(spacing: 20) {
                            PalmLineView(title: "Life Line", description: palmReading.lines.life_line, symbol: "heart.circle")
                            PalmLineView(title: "Heart Line", description: palmReading.lines.heart_line, symbol: "heart.fill")
                            PalmLineView(title: "Head Line", description: palmReading.lines.head_line, symbol: "brain.head.profile")
                            PalmLineView(title: "Fate Line", description: palmReading.lines.fate_line, symbol: "star.circle.fill")
                        }
                    },
                    index: 1,
                    cardOffset: cardOffset,
                    cardOpacity: cardOpacity
                )
                
                // Advice Card
                MysticalCard(
                    title: "Divine Guidance",
                    icon: "lightbulb.max.fill",
                    content: {
                        if palmReading.advice.isEmpty || palmReading.advice.contains("NO_ADVICE") {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title3)
                                    .foregroundColor(Color.orange)
                                
                                Text("ERROR: Divine guidance unavailable")
                                    .font(.custom("Avenir Next", size: 14))
                                    .fontWeight(.medium)
                                    .foregroundColor(deepPurple.opacity(0.8))
                                
                                Text("The cosmic wisdom could not be channeled")
                                    .font(.custom("Georgia", size: 12))
                                    .foregroundColor(deepPurple.opacity(0.6))
                                    .italic()
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 16)
                        } else {
                            Text(palmReading.advice)
                                .font(.custom("Georgia", size: 16))
                                .fontStyle(.italic)
                                .lineHeight(1.7)
                                .foregroundColor(deepPurple.opacity(0.8))
                                .multilineTextAlignment(.leading)
                        }
                    },
                    index: 2,
                    cardOffset: cardOffset,
                    cardOpacity: cardOpacity
                )
                
                // Energy Rating Card
                MysticalCard(
                    title: "Spiritual Resonance",
                    icon: "waveform.path.ecg",
                    content: {
                        let textFieldsEmpty = palmReading.summary.isEmpty && 
                                             palmReading.lines.life_line.isEmpty && 
                                             palmReading.lines.heart_line.isEmpty && 
                                             palmReading.lines.head_line.isEmpty && 
                                             palmReading.lines.fate_line.isEmpty && 
                                             palmReading.advice.isEmpty
                        
                        let allRatingsZero = palmReading.rating.clarity == 0 && 
                                           palmReading.rating.spiritual_energy == 0 && 
                                           palmReading.rating.introspection == 0
                        
                        if textFieldsEmpty || allRatingsZero {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title2)
                                    .foregroundColor(Color.orange)
                                
                                Text("ERROR: No spiritual resonance data available")
                                    .font(.custom("Avenir Next", size: 14))
                                    .foregroundColor(deepPurple.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                
                                Text("The spiritual energy analysis could not be completed")
                                    .font(.custom("Georgia", size: 12))
                                    .foregroundColor(deepPurple.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .italic()
                            }
                            .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 24) {
                                SpiritualMeter(label: "Clarity", value: palmReading.rating.clarity, color: primaryGold)
                                SpiritualMeter(label: "Spiritual Energy", value: palmReading.rating.spiritual_energy, color: mysticalBlue)
                                SpiritualMeter(label: "Introspection", value: palmReading.rating.introspection, color: deepPurple)
                            }
                        }
                    },
                    index: 3,
                    cardOffset: cardOffset,
                    cardOpacity: cardOpacity
                )
                
                // Mystical Footer
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(primaryGold.opacity(0.4))
                                .frame(width: 4, height: 4)
                                .scaleEffect(showContent ? 1.0 : 0.5)
                                .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1 + 1.5), value: showContent)
                        }
                    }
                    
                    Text("May wisdom guide your path")
                        .font(.custom("Avenir Next", size: 11))
                        .tracking(2)
                        .foregroundColor(mysticalBlue.opacity(0.6))
                        .opacity(showContent ? 0.7 : 0)
                        .animation(.easeOut(duration: 0.8).delay(2.0), value: showContent)
                }
                .padding(.top, 40)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 4)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.clear,
                    mysticalBlue.opacity(0.03),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            startElegantAnimation()
        }
    }
    
    private func startElegantAnimation() {
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            showContent = true
        }
        
        // Stagger card animations
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15 + 0.8) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    cardOffset[i] = 0
                    cardOpacity[i] = 1
                }
            }
        }
    }
}

// MARK: - Premium UI Components

struct MysticalCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    let index: Int
    let cardOffset: [CGFloat]
    let cardOpacity: [Double]
    
    private let primaryGold = Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13)
    private let mysticalBlue = Color(.sRGB, red: 0.12, green: 0.25, blue: 0.45)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Card Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [primaryGold, mysticalBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: primaryGold.opacity(0.3), radius: 4)
                
                Text(title)
                    .font(.custom("Playfair Display", size: 20))
                    .fontWeight(.medium)
                    .foregroundColor(mysticalBlue)
                
                Spacer()
                
                // Decorative element
                Circle()
                    .fill(primaryGold.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .shadow(color: primaryGold, radius: 2)
            }
            
            // Card Content
            content
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(.sRGB, red: 0.98, green: 0.97, blue: 0.95),
                            Color(.sRGB, red: 0.96, green: 0.94, blue: 0.91)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 20,
                    x: 0,
                    y: 8
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    primaryGold.opacity(0.1),
                                    mysticalBlue.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .offset(y: cardOffset[index])
        .opacity(cardOpacity[index])
    }
}

struct PalmLineView: View {
    let title: String
    let description: String
    let symbol: String
    
    private let mysticalBlue = Color(.sRGB, red: 0.12, green: 0.25, blue: 0.45)
    private let deepPurple = Color(.sRGB, red: 0.15, green: 0.05, blue: 0.35)
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Symbol
            Image(systemName: symbol)
                .font(.title3)
                .foregroundColor(mysticalBlue.opacity(0.7))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.custom("Avenir Next", size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(mysticalBlue)
                    .tracking(0.5)
                
                if description.isEmpty || description.contains("NO_") {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(Color.orange)
                        
                        Text("ERROR: Line analysis failed")
                            .font(.custom("Avenir Next", size: 12))
                            .foregroundColor(Color.orange.opacity(0.8))
                            .italic()
                    }
                } else {
                    Text(description)
                        .font(.custom("Georgia", size: 15))
                        .lineHeight(1.5)
                        .foregroundColor(deepPurple.opacity(0.8))
                }
            }
            
            Spacer()
        }
    }
}

struct SpiritualMeter: View {
    let label: String
    let value: Int
    let color: Color
    @State private var animatedValue: Double = 0
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(label)
                    .font(.custom("Avenir Next", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(color.opacity(0.8))
                
                Spacer()
                
                Text("\(value)")
                    .font(.custom("Avenir Next", size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            // Elegant progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.1))
                        .frame(height: 6)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.8),
                                    color
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * (animatedValue / 10),
                            height: 6
                        )
                        .shadow(color: color.opacity(0.3), radius: 3)
                }
            }
            .frame(height: 6)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
                    animatedValue = Double(value)
                }
            }
        }
    }
}


#Preview {
    CameraView()
}
