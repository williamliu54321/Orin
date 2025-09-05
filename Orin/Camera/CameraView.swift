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

enum AnalysisState {
    case idle
    case loading
    case completed
}

// MARK: - Data Models
struct PalmReading: Codable, Equatable {
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

struct PalmLines: Codable, Equatable {
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

struct PalmRating: Codable, Equatable {
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
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var palmReading: PalmReading?
    @State private var hasAnimated = false
    @State private var showLoadingScreen = false
    @State private var showAncientTomeView = false
    @State private var analysisState: AnalysisState = .idle
    
    let palmAnalysisPrompt = """
    Analyze this palm image and provide a detailed, personalized palm reading based on what you observe in the image. 

    Return your response as valid JSON with these fields:
    - summary: A personalized overview of what this specific palm reveals 
    - lines: An object with life_line, heart_line, head_line, and fate_line analyses
    - advice: Specific guidance based on this palm's unique characteristics
    - rating: An object with numeric scores (1-10) for clarity, spiritual_energy, and introspection

    Important: Create authentic, specific readings based on the actual palm features you observe. Do not use generic placeholder text or template language. Each reading should be unique and meaningful.

    If you cannot clearly analyze the image, set all rating values to 0 and provide a brief explanation in the summary.
    """

    var body: some View {
        ZStack {
            // Premium mystical background
            MysticalCameraBackground()
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                        if let image = capturedImage {
                            Spacer(minLength: 0)
                            
                            ZStack {
                                // Mystical corner decorations
                                VStack {
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .font(.title2)
                                            .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.6))
                                            .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 8)
                                        Spacer()
                                        Image(systemName: "moon.stars.fill")
                                            .font(.title2)
                                            .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.6))
                                            .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 8)
                                    }
                                    Spacer()
                                    HStack {
                                        Image(systemName: "star")
                                            .font(.title2)
                                            .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.6))
                                            .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 8)
                                        Spacer()
                                        Image(systemName: "circle.dotted")
                                            .font(.title2)
                                            .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.6))
                                            .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 8)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .opacity(hasAnimated ? 1 : 0)
                                .animation(.easeOut(duration: 1.0).delay(0.5), value: hasAnimated)
                                
                                VStack(spacing: 25) {
                                    // Enhanced header with mystical elements
                                    VStack(spacing: 12) {
                                        HStack(spacing: 8) {
                                            Rectangle()
                                                .fill(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.6))
                                                .frame(width: 30, height: 1)
                                                .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 3)
                                            
                                            Text("YOUR SACRED PALM")
                                                .font(.system(.caption, design: .serif, weight: .semibold))
                                                .tracking(2)
                                                .foregroundColor(.white.opacity(0.9))
                                                .shadow(color: Color.black.opacity(0.4), radius: 4)
                                                .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.3), radius: 6)
                                            
                                            Rectangle()
                                                .fill(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.6))
                                                .frame(width: 30, height: 1)
                                                .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 3)
                                        }
                                        .opacity(hasAnimated ? 1 : 0)
                                        .animation(.easeOut(duration: 0.8).delay(0.2), value: hasAnimated)
                                    }
                                    
                                    // Enhanced mystical palm image display
                                    ZStack {
                                        // Multiple layer glow background
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(
                                                RadialGradient(
                                                    colors: [
                                                        Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.4),
                                                        Color(.sRGB, red: 0.12, green: 0.25, blue: 0.45).opacity(0.3),
                                                        Color.clear
                                                    ],
                                                    center: .center,
                                                    startRadius: 20,
                                                    endRadius: 180
                                                )
                                            )
                                            .frame(maxHeight: 340)
                                            .blur(radius: 15)
                                            .scaleEffect(hasAnimated ? 1.0 : 0.8)
                                            .opacity(hasAnimated ? 1 : 0)
                                            .animation(.easeOut(duration: 1.0).delay(0.1), value: hasAnimated)
                                        
                                        // Outer mystical frame
                                        RoundedRectangle(cornerRadius: 28)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.6),
                                                        Color(.sRGB, red: 0.12, green: 0.25, blue: 0.45).opacity(0.4),
                                                        Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.6)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                            .frame(maxHeight: 320)
                                            .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.4), radius: 12)
                                        
                                        // Main image with enhanced mystical border
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 300)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [
                                                                Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.9),
                                                                Color(.sRGB, red: 0.12, green: 0.25, blue: 0.45).opacity(0.7),
                                                                Color.white.opacity(0.6),
                                                                Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.9)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 4
                                                    )
                                            )
                                            .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.5), radius: 20, x: 0, y: 10)
                                            .shadow(color: Color.black.opacity(0.4), radius: 25, x: 0, y: 12)
                                            .shadow(color: Color(.sRGB, red: 0.12, green: 0.25, blue: 0.45).opacity(0.3), radius: 30, x: 0, y: 8)
                                        
                                        // Corner ornaments
                                        VStack {
                                            HStack {
                                                Image(systemName: "plus")
                                                    .font(.caption)
                                                    .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.8))
                                                    .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 4)
                                                Spacer()
                                                Image(systemName: "plus")
                                                    .font(.caption)
                                                    .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.8))
                                                    .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 4)
                                            }
                                            Spacer()
                                            HStack {
                                                Image(systemName: "plus")
                                                    .font(.caption)
                                                    .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.8))
                                                    .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 4)
                                                Spacer()
                                                Image(systemName: "plus")
                                                    .font(.caption)
                                                    .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.8))
                                                    .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 4)
                                            }
                                        }
                                        .frame(maxWidth: 280, maxHeight: 280)
                                        .opacity(hasAnimated ? 0.7 : 0)
                                        .animation(.easeOut(duration: 1.2).delay(0.4), value: hasAnimated)
                                    }
                                }
                            }
                            
                            // Enhanced mystical action section
                            VStack(spacing: 20) {
                                // Mystical divider
                                HStack(spacing: 12) {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.7))
                                        .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 4)
                                    
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.8),
                                                    Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.3),
                                                    Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.8)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(height: 1)
                                        .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.4), radius: 2)
                                    
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.7))
                                        .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 4)
                                }
                                .padding(.horizontal, 40)
                                .opacity(hasAnimated ? 1 : 0)
                                .scaleEffect(hasAnimated ? 1.0 : 0.3)
                                .animation(.easeOut(duration: 0.8).delay(0.4), value: hasAnimated)
                                
                                // Enhanced mystical action buttons
                                HStack(spacing: 25) {
                                    MysticalButton(
                                        title: "Retake",
                                        icon: "camera.rotate",
                                        isPrimary: false,
                                        action: retakePhoto
                                    )
                                    
                                    MysticalButton(
                                        title: "Read Palm",
                                        icon: "hand.raised",
                                        isPrimary: true,
                                        action: {
                                            analysisState = .loading
                                        }
                                    )
                                }
                                .opacity(hasAnimated ? 1 : 0)
                                .animation(.easeOut(duration: 0.6).delay(0.3), value: hasAnimated)
                                }
                            
                            Spacer(minLength: 0)
                            
                        
                        } else {
                            // Enhanced initial state with mystical decorations
                            Spacer(minLength: 0)
                            
                            ZStack {
                                // Mystical background ornaments
                                ForEach(0..<8, id: \.self) { index in
                                    Image(systemName: ["moon.stars", "sparkles", "star", "circle.dotted"][index % 4])
                                        .font(.system(size: CGFloat.random(in: 20...35)))
                                        .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.3))
                                        .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.5), radius: 8)
                                        .position(
                                            x: CGFloat.random(in: 50...300),
                                            y: CGFloat.random(in: 100...400)
                                        )
                                        .opacity(hasAnimated ? 0.6 : 0)
                                        .scaleEffect(hasAnimated ? 1.0 : 0.3)
                                        .animation(
                                            .easeOut(duration: 1.5)
                                                .delay(Double(index) * 0.2 + 0.5),
                                            value: hasAnimated
                                        )
                                }
                                
                                VStack(spacing: 30) {
                                    // Ornate header decoration
                                    HStack(spacing: 16) {
                                        Image(systemName: "moon.stars.fill")
                                            .font(.title)
                                            .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.8))
                                            .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 8)
                                        
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.8),
                                                        Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.3),
                                                        Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.8)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(height: 2)
                                            .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.6), radius: 4)
                                        
                                        Image(systemName: "sparkles")
                                            .font(.title)
                                            .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.8))
                                            .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 8)
                                    }
                                    .opacity(hasAnimated ? 1 : 0)
                                    .animation(.easeOut(duration: 1.0).delay(0.3), value: hasAnimated)
                                    
                                    // Enhanced mystical hand icon with multiple layers
                                    ZStack {
                                        // Outer glow ring
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.4),
                                                        Color(.sRGB, red: 0.12, green: 0.25, blue: 0.45).opacity(0.3),
                                                        Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.4)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 3
                                            )
                                            .frame(width: 180, height: 180)
                                            .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.4), radius: 15)
                                            .scaleEffect(hasAnimated ? 1.1 : 1.0)
                                            .opacity(hasAnimated ? 0.4 : 0.8)
                                            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: hasAnimated)
                                        
                                        // Main hand icon
                                        Image(systemName: "hand.raised.fill")
                                            .font(.system(size: 120))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [
                                                        Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13),
                                                        Color(.sRGB, red: 0.12, green: 0.25, blue: 0.45),
                                                        Color.white.opacity(0.9)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.8), radius: 25)
                                            .shadow(color: Color(.sRGB, red: 0.12, green: 0.25, blue: 0.45).opacity(0.6), radius: 35)
                                            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                                        
                                        // Inner pulsing aura
                                        Circle()
                                            .stroke(
                                                Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.6),
                                                lineWidth: 2
                                            )
                                            .frame(width: 140, height: 140)
                                            .scaleEffect(hasAnimated ? 1.2 : 1.0)
                                            .opacity(hasAnimated ? 0.2 : 0.7)
                                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: hasAnimated)
                                        
                                        // Mystical symbols around the hand
                                        ForEach(0..<6, id: \.self) { index in
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.8))
                                                .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 6)
                                                .offset(
                                                    x: cos(Double(index) * .pi / 3) * 90,
                                                    y: sin(Double(index) * .pi / 3) * 90
                                                )
                                                .opacity(hasAnimated ? 1 : 0)
                                                .scaleEffect(hasAnimated ? 1.0 : 0.3)
                                                .animation(
                                                    .easeOut(duration: 0.8)
                                                        .delay(Double(index) * 0.1 + 1.0),
                                                    value: hasAnimated
                                                )
                                        }
                                    }
                                    .scaleEffect(hasAnimated ? 1.0 : 0.8)
                                    .opacity(hasAnimated ? 1 : 0)
                                    .animation(.spring(response: 1.5, dampingFraction: 0.6).delay(0.4), value: hasAnimated)
                                    
                                    VStack(spacing: 20) {
                                        Text("Discover Your Destiny")
                                            .font(.system(.largeTitle, design: .serif, weight: .bold))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white,
                                                        Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.9),
                                                        Color.white.opacity(0.8)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .multilineTextAlignment(.center)
                                            .shadow(color: Color.black.opacity(0.6), radius: 10, x: 0, y: 5)
                                            .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.5), radius: 15)
                                            .opacity(hasAnimated ? 1 : 0)
                                            .offset(y: hasAnimated ? 0 : 30)
                                            .animation(.easeOut(duration: 1.2).delay(0.8), value: hasAnimated)
                                        
                                        VStack(spacing: 8) {
                                            Text("Let the ancient wisdom of palm reading")
                                                .font(.system(.body, design: .serif, weight: .medium))
                                                .foregroundColor(.white.opacity(0.95))
                                                .multilineTextAlignment(.center)
                                                .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
                                            
                                            Text("reveal the mysteries written in your hands")
                                                .font(.system(.body, design: .serif, weight: .medium))
                                                .foregroundColor(.white.opacity(0.95))
                                                .multilineTextAlignment(.center)
                                                .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
                                        }
                                        .opacity(hasAnimated ? 1 : 0)
                                        .offset(y: hasAnimated ? 0 : 30)
                                        .animation(.easeOut(duration: 1.2).delay(1.0), value: hasAnimated)
                                        
                                        // Mystical divider
                                        HStack(spacing: 12) {
                                            Image(systemName: "star.fill")
                                                .font(.caption)
                                                .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.7))
                                                .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 4)
                                            
                                            Rectangle()
                                                .fill(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.5))
                                                .frame(width: 60, height: 1)
                                                .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.4), radius: 2)
                                            
                                            Image(systemName: "star.fill")
                                                .font(.caption)
                                                .foregroundColor(Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13).opacity(0.7))
                                                .shadow(color: Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13), radius: 4)
                                        }
                                        .opacity(hasAnimated ? 1 : 0)
                                        .scaleEffect(hasAnimated ? 1.0 : 0.3)
                                        .animation(.easeOut(duration: 0.8).delay(1.2), value: hasAnimated)
                                    }
                                }
                                .padding(.horizontal, 28)
                            }
                                
                                VStack(spacing: 16) {
                                    MysticalButton(
                                        title: "Capture Your Palm",
                                        icon: "camera.fill",
                                        isPrimary: true,
                                        action: { showCamera = true }
                                    )
                                    .scaleEffect(hasAnimated ? 1.0 : 0.8)
                                    .opacity(hasAnimated ? 1 : 0)
                                    .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.8), value: hasAnimated)
                                    
                                    Text("Hold your palm steady and capture a clear image")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .opacity(hasAnimated ? 1 : 0)
                                        .animation(.easeOut(duration: 0.8).delay(1.0), value: hasAnimated)
                                }
                            
                            Spacer(minLength: 0)
                        }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
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
            .fullScreenCover(isPresented: .constant(analysisState != .idle), content: {
                if analysisState == .loading {
                    MysticalLoadingView(
                        capturedImage: capturedImage,
                        palmAnalysisPrompt: palmAnalysisPrompt,
                        onComplete: { reading in
                            palmReading = reading
                            analysisState = .completed
                        },
                        onError: { errorMessage in
                            alertMessage = errorMessage
                            showAlert = true
                            analysisState = .idle
                        }
                    )
                } else if analysisState == .completed, let reading = palmReading {
                    AncientTomeView(palmReading: reading) {
                        analysisState = .idle
                        palmReading = nil
                    }
                }
            })
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
        
        palmReading = nil
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            alertMessage = "Failed to process image"
            showAlert = true
            analysisState = .idle
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        guard let url = URL(string: "https://processimagewithgpt4o-ncvbgosopa-uc.a.run.app") else {
            alertMessage = "Invalid endpoint URL"
            showAlert = true
            analysisState = .idle
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
            analysisState = .idle
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                
                if let error = error {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showAlert = true
                    analysisState = .idle
                    return
                }
                
                guard let data = data else {
                    alertMessage = "No data received"
                    showAlert = true
                    analysisState = .idle
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
                                    
                                    analysisState = .completed
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
                                        analysisState = .completed
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
                                        analysisState = .completed
                                    }
                                }
                            }
                        } else if let error = json["error"] as? String {
                            alertMessage = "Reading failed: \(error)"
                            showAlert = true
                            analysisState = .idle
                        }
                    }
                } catch {
                    print("=== COMPLETE FAILURE ===")
                    print("Error: \(error)")
                    alertMessage = "Unable to process the response"
                    showAlert = true
                    analysisState = .idle
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

// MARK: - Mystical Loading Screen
struct MysticalLoadingView: View {
    let capturedImage: UIImage?
    let palmAnalysisPrompt: String
    let onComplete: (PalmReading) -> Void
    let onError: (String) -> Void
    
    @State private var orbRotation: Double = 0
    @State private var orbScale: Double = 0.8
    @State private var particleOpacity: Double = 0
    @State private var centerGlow: Double = 0.3
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var loadingText = "Channeling cosmic energies..."
    @State private var dotCount = 0
    
    private let primaryGold = Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13)
    private let deepPurple = Color(.sRGB, red: 0.15, green: 0.05, blue: 0.35)
    private let mysticalBlue = Color(.sRGB, red: 0.12, green: 0.25, blue: 0.45)
    
    private let loadingTexts = [
        "Channeling cosmic energies",
        "Reading the sacred lines", 
        "Interpreting mystical patterns",
        "Unveiling spiritual insights",
        "Consulting ancient wisdom"
    ]
    
    var body: some View {
        ZStack {
            // Mystical gradient background
            LinearGradient(
                colors: [
                    deepPurple,
                    mysticalBlue.opacity(0.8),
                    deepPurple
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated particles
            ForEach(0..<15, id: \.self) { index in
                Circle()
                    .fill(primaryGold.opacity(0.3))
                    .frame(width: CGFloat.random(in: 2...6))
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -400...400)
                    )
                    .opacity(particleOpacity)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: particleOpacity
                    )
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Central mystical orb
                ZStack {
                    // Outer rings
                    ForEach(0..<3, id: \.self) { ring in
                        Circle()
                            .stroke(
                                primaryGold.opacity(0.3 - Double(ring) * 0.1),
                                lineWidth: 2
                            )
                            .frame(width: 120 + CGFloat(ring * 30))
                            .rotationEffect(.degrees(orbRotation + Double(ring * 120)))
                    }
                    
                    // Center orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    primaryGold.opacity(centerGlow),
                                    mysticalBlue.opacity(0.6),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(orbScale)
                        .overlay(
                            Image(systemName: "eye")
                                .font(.title)
                                .foregroundColor(primaryGold)
                                .opacity(0.8)
                        )
                }
                
                Spacer()
                
                // Loading text
                VStack(spacing: 16) {
                    Text("Reading Your Palm")
                        .font(.custom("Playfair Display", size: 28))
                        .fontWeight(.light)
                        .foregroundColor(.white)
                        .opacity(titleOpacity)
                    
                    Text(loadingText + String(repeating: ".", count: dotCount))
                        .font(.custom("Avenir Next", size: 16))
                        .foregroundColor(primaryGold.opacity(0.9))
                        .opacity(subtitleOpacity)
                }
                
                Spacer()
            }
        }
        .onAppear {
            startLoadingAnimation()
            startPalmAnalysis()
        }
    }
    
    private func startLoadingAnimation() {
        // Immediate animations
        withAnimation(.easeOut(duration: 0.8)) {
            titleOpacity = 1
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            subtitleOpacity = 1
            particleOpacity = 1
        }
        
        // Continuous animations
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            orbRotation = 360
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            orbScale = 1.2
            centerGlow = 0.8
        }
        
        // Loading text cycling
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.3)) {
                dotCount = (dotCount + 1) % 4
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.5)) {
                loadingText = loadingTexts.randomElement() ?? loadingTexts[0]
            }
        }
        
        // Minimum loading time - will complete when analysis finishes or after 5 seconds max
    }
    
    private func startPalmAnalysis() {
        guard let image = capturedImage else { 
            onError("No image to analyze")
            return 
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            onError("Failed to process image")
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        guard let url = URL(string: "https://processimagewithgpt4o-ncvbgosopa-uc.a.run.app") else {
            onError("Invalid endpoint URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "image": base64String,
            "prompt": palmAnalysisPrompt
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            onError("Failed to encode request")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    onError("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    onError("No data received")
                    return
                }
                
                // Parse response and handle all the existing logic
                self.parseAnalysisResponse(data: data)
            }
        }.resume()
    }
    
    private func parseAnalysisResponse(data: Data) {
        // Copy the same parsing logic from the original analyzePalm function
        if let rawResponse = String(data: data, encoding: .utf8) {
            print("=== RAW API RESPONSE ===")
            print(rawResponse)
            print("========================")
        }
        
        do {
            // Try to parse the outer JSON envelope first
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let success = json["success"] as? Bool, success,
                   let resultString = json["result"] as? String {
                    
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
                    
                    // Try to parse the JSON
                    if let resultData = cleanedString.data(using: .utf8) {
                        do {
                            let reading = try JSONDecoder().decode(PalmReading.self, from: resultData)
                            
                            // Check if all fields are empty
                            let isEmpty = reading.summary.isEmpty && 
                                         reading.lines.life_line.isEmpty && 
                                         reading.lines.heart_line.isEmpty && 
                                         reading.lines.head_line.isEmpty && 
                                         reading.lines.fate_line.isEmpty && 
                                         reading.advice.isEmpty
                            
                            if isEmpty {
                                onError("GPT-4o returned empty analysis - image may be unclear")
                                return
                            } else {
                                onComplete(reading)
                                return
                            }
                        } catch {
                            // Try manual parsing as last resort
                            if let genericJSON = try? JSONSerialization.jsonObject(with: resultData) as? [String: Any] {
                                let manualReading = PalmReading(
                                    summary: genericJSON["summary"] as? String ?? "Unable to read palm clearly",
                                    lines: PalmLines(
                                        life_line: (genericJSON["lines"] as? [String: Any])?["life_line"] as? String ?? "Analysis unavailable",
                                        heart_line: (genericJSON["lines"] as? [String: Any])?["heart_line"] as? String ?? "Analysis unavailable",
                                        head_line: (genericJSON["lines"] as? [String: Any])?["head_line"] as? String ?? "Analysis unavailable",
                                        fate_line: (genericJSON["lines"] as? [String: Any])?["fate_line"] as? String ?? "Analysis unavailable"
                                    ),
                                    advice: genericJSON["advice"] as? String ?? "Trust your intuition",
                                    rating: PalmRating(
                                        clarity: (genericJSON["rating"] as? [String: Any])?["clarity"] as? Int ?? 5,
                                        spiritual_energy: (genericJSON["rating"] as? [String: Any])?["spiritual_energy"] as? Int ?? 5,
                                        introspection: (genericJSON["rating"] as? [String: Any])?["introspection"] as? Int ?? 5
                                    )
                                )
                                onComplete(manualReading)
                                return
                            } else {
                                // Final fallback
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
                                onComplete(fallbackReading)
                                return
                            }
                        }
                    }
                } else if let error = json["error"] as? String {
                    onError("Reading failed: \(error)")
                    return
                }
            }
        } catch {
            onError("Unable to process the response")
            return
        }
        
        onError("Unexpected response format")
    }
}

struct AncientTomeView: View {
    let palmReading: PalmReading
    let onDone: () -> Void
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
        ZStack {
            // Mystical background
            MysticalCameraBackground()
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Enhanced Mystical Header
                VStack(spacing: 30) {
                    // Elaborate celestial ornament with multiple layers
                    VStack(spacing: 16) {
                        // Top ornamental line
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(primaryGold.opacity(0.6))
                                .shadow(color: primaryGold, radius: 4)
                            
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            primaryGold.opacity(0.8),
                                            primaryGold.opacity(0.3),
                                            primaryGold.opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 80, height: 1)
                                .shadow(color: primaryGold.opacity(0.4), radius: 2)
                            
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(primaryGold.opacity(0.6))
                                .shadow(color: primaryGold, radius: 4)
                            
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            primaryGold.opacity(0.8),
                                            primaryGold.opacity(0.3),
                                            primaryGold.opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 80, height: 1)
                                .shadow(color: primaryGold.opacity(0.4), radius: 2)
                            
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(primaryGold.opacity(0.6))
                                .shadow(color: primaryGold, radius: 4)
                        }
                        
                        // Main celestial symbol with enhanced decoration
                        ZStack {
                            // Outer glow ring
                            Circle()
                                .stroke(primaryGold.opacity(0.2), lineWidth: 2)
                                .frame(width: 80, height: 80)
                                .shadow(color: primaryGold.opacity(0.3), radius: 8)
                            
                            // Inner decorative elements
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(primaryGold.opacity(0.4))
                                    .frame(width: 12, height: 12)
                                    .shadow(color: primaryGold, radius: 6)
                                
                                Image(systemName: "moon.stars.fill")
                                    .font(.title)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                primaryGold,
                                                mysticalBlue.opacity(0.8),
                                                primaryGold.opacity(0.7)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: primaryGold.opacity(0.6), radius: 8)
                                    .shadow(color: mysticalBlue.opacity(0.4), radius: 12)
                                
                                Circle()
                                    .fill(primaryGold.opacity(0.4))
                                    .frame(width: 12, height: 12)
                                    .shadow(color: primaryGold, radius: 6)
                            }
                            
                            // Rotating mystical symbols
                            ForEach(0..<4, id: \.self) { index in
                                Image(systemName: "plus")
                                    .font(.caption2)
                                    .foregroundColor(primaryGold.opacity(0.5))
                                    .shadow(color: primaryGold, radius: 3)
                                    .offset(
                                        x: cos(Double(index) * .pi / 2) * 35,
                                        y: sin(Double(index) * .pi / 2) * 35
                                    )
                            }
                        }
                        
                        // Bottom ornamental line (mirror of top)
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(primaryGold.opacity(0.6))
                                .shadow(color: primaryGold, radius: 4)
                            
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            primaryGold.opacity(0.8),
                                            primaryGold.opacity(0.3),
                                            primaryGold.opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 80, height: 1)
                                .shadow(color: primaryGold.opacity(0.4), radius: 2)
                            
                            Image(systemName: "circle.dotted")
                                .font(.caption)
                                .foregroundColor(primaryGold.opacity(0.6))
                                .shadow(color: primaryGold, radius: 4)
                            
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            primaryGold.opacity(0.8),
                                            primaryGold.opacity(0.3),
                                            primaryGold.opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 80, height: 1)
                                .shadow(color: primaryGold.opacity(0.4), radius: 2)
                            
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(primaryGold.opacity(0.6))
                                .shadow(color: primaryGold, radius: 4)
                        }
                    }
                    
                    // Enhanced Title with background
                    VStack(spacing: 12) {
                        Text("PALM READING")
                            .font(.custom("Avenir Next", size: 13))
                            .fontWeight(.bold)
                            .tracking(4)
                            .foregroundColor(.white)
                            .shadow(color: primaryGold.opacity(0.8), radius: 8)
                            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                        
                        Text("Mystical Insights")
                            .font(.custom("Playfair Display", size: 32))
                            .fontWeight(.medium)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        primaryGold.opacity(0.9),
                                        Color.white.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: primaryGold.opacity(0.6), radius: 12)
                            .shadow(color: .black.opacity(0.8), radius: 6, x: 0, y: 3)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.4),
                                        deepPurple.opacity(0.3),
                                        Color.black.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                primaryGold.opacity(0.6),
                                                mysticalBlue.opacity(0.4),
                                                primaryGold.opacity(0.4)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    )
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
        .safeAreaInset(edge: .top, alignment: .trailing) {
            Button(action: onDone) {
                Text("Done")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(primaryGold.opacity(0.9))
                    )
                    .shadow(color: primaryGold.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .onAppear {
            startElegantAnimation()
        }
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

// MARK: - Mystical Camera Components

struct MysticalCameraBackground: View {
    @State private var starsOffset: [CGFloat] = Array(repeating: -50, count: 12)
    @State private var starsOpacity: [Double] = Array(repeating: 0, count: 12)
    
    private let primaryGold = Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13)
    private let mysticalBlue = Color(.sRGB, red: 0.12, green: 0.25, blue: 0.45)
    private let deepPurple = Color(.sRGB, red: 0.15, green: 0.05, blue: 0.35)
    
    var body: some View {
        ZStack {
            // Stable gradient background
            LinearGradient(
                colors: [
                    deepPurple,
                    mysticalBlue,
                    deepPurple.opacity(0.8),
                    Color.black.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Gentle falling stars
            ForEach(0..<12, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: CGFloat.random(in: 8...16)))
                    .foregroundColor(primaryGold.opacity(0.6))
                    .shadow(color: primaryGold.opacity(0.4), radius: 4)
                    .position(
                        x: CGFloat.random(in: 30...350),
                        y: starsOffset[index]
                    )
                    .opacity(starsOpacity[index])
                    .animation(
                        .linear(duration: Double.random(in: 8...15))
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.8),
                        value: starsOffset[index]
                    )
            }
            
            // Subtle center glow
            RadialGradient(
                colors: [
                    primaryGold.opacity(0.05),
                    Color.clear
                ],
                center: .center,
                startRadius: 100,
                endRadius: 300
            )
        }
        .onAppear {
            // Start gentle falling star animation
            for index in 0..<12 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.8) {
                    withAnimation {
                        starsOpacity[index] = 1.0
                    }
                    
                    // Animate falling with restart
                    Timer.scheduledTimer(withTimeInterval: Double.random(in: 8...15), repeats: true) { _ in
                        withAnimation(.linear(duration: 0.5)) {
                            starsOpacity[index] = 0
                            starsOffset[index] = -50
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            starsOffset[index] = UIScreen.main.bounds.height + 50
                            withAnimation(.linear(duration: Double.random(in: 8...15))) {
                                starsOffset[index] = -50
                                starsOpacity[index] = 1.0
                            }
                        }
                    }
                    
                    // Initial fall
                    starsOffset[index] = UIScreen.main.bounds.height + 50
                    withAnimation(.linear(duration: Double.random(in: 8...15))) {
                        starsOffset[index] = -50
                    }
                }
            }
        }
    }
}

struct MysticalButton: View {
    let title: String
    let icon: String
    let isPrimary: Bool
    let action: () -> Void
    
    @State private var glowIntensity: Double = 0.5
    @State private var shimmerOffset: CGFloat = -200
    
    private let primaryGold = Color(.sRGB, red: 0.85, green: 0.65, blue: 0.13)
    private let mysticalBlue = Color(.sRGB, red: 0.12, green: 0.25, blue: 0.45)
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background {
                ZStack {
                    // Base gradient
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: isPrimary ? [
                                    primaryGold.opacity(0.8),
                                    mysticalBlue.opacity(0.6),
                                    primaryGold.opacity(0.4)
                                ] : [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Shimmer effect
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                        .clipped()
                    
                    // Border glow
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: isPrimary ? [
                                    primaryGold.opacity(0.8),
                                    mysticalBlue.opacity(0.6)
                                ] : [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .opacity(glowIntensity)
                }
            }
            .shadow(color: isPrimary ? primaryGold.opacity(0.4) : Color.white.opacity(0.2), radius: 12, x: 0, y: 8)
            .shadow(color: isPrimary ? mysticalBlue.opacity(0.3) : Color.clear, radius: 20, x: 0, y: 4)
        }
        .onAppear {
            // Breathing glow effect
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowIntensity = isPrimary ? 1.0 : 0.8
            }
            
            // Periodic shimmer
            Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 1.5)) {
                    shimmerOffset = 200
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    shimmerOffset = -200
                }
            }
        }
    }
}

#Preview {
    CameraView()
}
