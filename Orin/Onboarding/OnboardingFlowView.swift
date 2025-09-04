import SwiftUI

// MARK: - Data Models
struct OnboardingQuestion {
    let id = UUID()
    let title: String
    let subtitle: String?
    let options: [OnboardingOption]
}

struct OnboardingOption {
    let id = UUID()
    let text: String
    let emoji: String
}

// MARK: - Onboarding State
class OnboardingState: ObservableObject {
    @Published var currentQuestionIndex = 0
    @Published var answers: [UUID: UUID] = [:]
    
    let questions = [
        OnboardingQuestion(
            title: "What draws you most to seek guidance?",
            subtitle: "Your journey begins with understanding your deeper calling",
            options: [
                OnboardingOption(text: "Finding my life purpose", emoji: "🌟"),
                OnboardingOption(text: "Healing from past experiences", emoji: "💚"),
                OnboardingOption(text: "Growing spiritually", emoji: "🕊️"),
                OnboardingOption(text: "Building meaningful relationships", emoji: "💝")
            ]
        ),
        OnboardingQuestion(
            title: "How do you prefer to connect with your inner wisdom?",
            subtitle: "Every soul has its own language of understanding",
            options: [
                OnboardingOption(text: "Through meditation and stillness", emoji: "🧘‍♀️"),
                OnboardingOption(text: "In nature and sacred spaces", emoji: "🌲"),
                OnboardingOption(text: "Through dreams and intuition", emoji: "✨"),
                OnboardingOption(text: "In community with others", emoji: "🤝")
            ]
        ),
        OnboardingQuestion(
            title: "What challenges you most right now?",
            subtitle: "Acknowledging our struggles is the first step to transformation",
            options: [
                OnboardingOption(text: "Feeling lost or disconnected", emoji: "🌊"),
                OnboardingOption(text: "Overcoming fear and doubt", emoji: "💪"),
                OnboardingOption(text: "Making important decisions", emoji: "⚖️"),
                OnboardingOption(text: "Finding balance and peace", emoji: "☯️")
            ]
        ),
        OnboardingQuestion(
            title: "What kind of wisdom speaks to your soul?",
            subtitle: "Different paths lead to the same universal truths",
            options: [
                OnboardingOption(text: "Ancient spiritual teachings", emoji: "📿"),
                OnboardingOption(text: "Modern mindfulness practices", emoji: "🎋"),
                OnboardingOption(text: "Nature's lessons and cycles", emoji: "🌙"),
                OnboardingOption(text: "Stories of human resilience", emoji: "🦋")
            ]
        ),
        OnboardingQuestion(
            title: "How do you want to feel after receiving guidance?",
            subtitle: "Your intention shapes the wisdom you'll receive",
            options: [
                OnboardingOption(text: "Peaceful and centered", emoji: "🕯️"),
                OnboardingOption(text: "Inspired and motivated", emoji: "🔥"),
                OnboardingOption(text: "Clear and confident", emoji: "🎯"),
                OnboardingOption(text: "Connected and loved", emoji: "💫")
            ]
        )
    ]
    
    var isComplete: Bool {
        return currentQuestionIndex >= questions.count
    }
    
    func selectAnswer(questionId: UUID, optionId: UUID) {
        answers[questionId] = optionId
    }
    
    func nextQuestion() {
        currentQuestionIndex += 1
    }
}

struct OnboardingFlowView: View {
    /// Callback that runs when onboarding is complete
    var onFinish: () -> Void
    
    @StateObject private var onboardingState = OnboardingState()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient background
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
                
                if onboardingState.isComplete {
                    CompletionView(onFinish: onFinish)
                } else {
                    OnboardingQuestionView(
                        question: onboardingState.questions[onboardingState.currentQuestionIndex],
                        onboardingState: onboardingState,
                        geometry: geometry
                    )
                }
            }
        }
    }
}

// MARK: - Question View
struct OnboardingQuestionView: View {
    let question: OnboardingQuestion
    @ObservedObject var onboardingState: OnboardingState
    let geometry: GeometryProxy
    
    @State private var selectedOption: UUID?
    @State private var hasAnimated = false
    @State private var showContinueButton = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack {
                ForEach(0..<onboardingState.questions.count, id: \.self) { index in
                    Circle()
                        .fill(index <= onboardingState.currentQuestionIndex ? 
                              Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == onboardingState.currentQuestionIndex ? 1.2 : 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: onboardingState.currentQuestionIndex)
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            // Question content
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text(question.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(hasAnimated ? 1 : 0)
                        .offset(y: hasAnimated ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: hasAnimated)
                    
                    if let subtitle = question.subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .opacity(hasAnimated ? 1 : 0)
                            .offset(y: hasAnimated ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.4), value: hasAnimated)
                    }
                }
                .padding(.horizontal, 32)
                
                // Options
                VStack(spacing: 16) {
                    ForEach(Array(question.options.enumerated()), id: \.element.id) { index, option in
                        OptionButton(
                            option: option,
                            isSelected: selectedOption == option.id,
                            onTap: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedOption = option.id
                                    showContinueButton = true
                                }
                                onboardingState.selectAnswer(questionId: question.id, optionId: option.id)
                            }
                        )
                        .opacity(hasAnimated ? 1 : 0)
                        .offset(y: hasAnimated ? 0 : 30)
                        .animation(.easeOut(duration: 0.6).delay(0.6 + Double(index) * 0.1), value: hasAnimated)
                    }
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Continue button
            if showContinueButton {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        onboardingState.nextQuestion()
                    }
                }) {
                    HStack {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(showContinueButton ? 1.0 : 0.8)
                .opacity(showContinueButton ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showContinueButton)
                .padding(.bottom, 60)
            } else {
                // Placeholder to maintain consistent spacing
                Color.clear
                    .frame(height: 60)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            hasAnimated = true
        }
        .onChange(of: onboardingState.currentQuestionIndex) { _ in
            selectedOption = nil
            showContinueButton = false
            hasAnimated = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                hasAnimated = true
            }
        }
    }
}

// MARK: - Option Button
struct OptionButton: View {
    let option: OnboardingOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(option.emoji)
                    .font(.title2)
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                
                Text(option.text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ? 
                        Color.white.opacity(0.3) : 
                        Color.white.opacity(0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? 
                                Color.white.opacity(0.6) : 
                                Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Completion View
struct CompletionView: View {
    let onFinish: () -> Void
    @State private var hasAnimated = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("✨")
                    .font(.system(size: 60))
                    .scaleEffect(hasAnimated ? 1.0 : 0.5)
                    .opacity(hasAnimated ? 1 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: hasAnimated)
                
                VStack(spacing: 16) {
                    Text("Your Journey Begins")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(hasAnimated ? 1 : 0)
                        .offset(y: hasAnimated ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.5), value: hasAnimated)
                    
                    Text("Thank you for sharing your heart with us. Your personalized guidance awaits.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .opacity(hasAnimated ? 1 : 0)
                        .offset(y: hasAnimated ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.7), value: hasAnimated)
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    onFinish()
                }
            }) {
                HStack {
                    Text("Enter Your Sacred Space")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(hasAnimated ? 1.0 : 0.8)
            .opacity(hasAnimated ? 1 : 0)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(1.0), value: hasAnimated)
            
            Spacer()
        }
        .onAppear {
            hasAnimated = true
        }
    }
}

#Preview {
    OnboardingFlowView {
        print("Onboarding finished (preview)")
    }
}
