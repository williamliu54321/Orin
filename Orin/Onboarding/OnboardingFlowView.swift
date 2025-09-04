import SwiftUI
import StoreKit

// MARK: - Data Models
struct OnboardingQuestion {
    let id = UUID()
    let title: String
    let subtitle: String?
    let type: QuestionType
    let options: [OnboardingOption]
}

enum QuestionType {
    case multipleChoice
    case textInput
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
    @Published var textAnswers: [UUID: String] = [:]
    @Published var showReviews = false
    @Published var showPersonalizationLoading = false
    
    let questions = [
        OnboardingQuestion(
            title: "What name would you like us to use?",
            subtitle: "We'll personalize your guidance with your preferred name",
            type: .textInput,
            options: []
        ),
        OnboardingQuestion(
            title: "How do you identify?",
            subtitle: "Understanding your identity helps us provide relevant guidance",
            type: .multipleChoice,
            options: [
                OnboardingOption(text: "Woman", emoji: "💃"),
                OnboardingOption(text: "Man", emoji: "🕺"),
                OnboardingOption(text: "Non-binary", emoji: "🌈"),
                OnboardingOption(text: "Prefer not to say", emoji: "✨")
            ]
        ),
        OnboardingQuestion(
            title: "What stage of life are you in?",
            subtitle: "Different seasons bring different wisdom needs",
            type: .multipleChoice,
            options: [
                OnboardingOption(text: "Teen years (13-17)", emoji: "🌸"),
                OnboardingOption(text: "Young adult (18-29)", emoji: "🌱"),
                OnboardingOption(text: "Early adulthood (30-39)", emoji: "🌿"),
                OnboardingOption(text: "Mid-life (40-59)", emoji: "🌳"),
                OnboardingOption(text: "Mature wisdom (60+)", emoji: "🌲")
            ]
        ),
        OnboardingQuestion(
            title: "When you're alone with your thoughts, what emerges most often?",
            subtitle: "The mind's patterns reveal our deepest needs",
            type: .multipleChoice,
            options: [
                OnboardingOption(text: "A longing for something I can't quite name", emoji: "🌙"),
                OnboardingOption(text: "Questions about my life's meaning and impact", emoji: "🔍"),
                OnboardingOption(text: "Memories I haven't fully processed", emoji: "💭"),
                OnboardingOption(text: "Dreams of who I could become", emoji: "✨")
            ]
        ),
        OnboardingQuestion(
            title: "How do you relate to your own suffering?",
            subtitle: "Our relationship with pain shapes our path to healing",
            type: .multipleChoice,
            options: [
                OnboardingOption(text: "I see it as a teacher, though a harsh one", emoji: "📚"),
                OnboardingOption(text: "I resist it and wish it would disappear", emoji: "🛡️"),
                OnboardingOption(text: "I'm learning to hold it with compassion", emoji: "🤲"),
                OnboardingOption(text: "I feel overwhelmed and consumed by it", emoji: "🌊")
            ]
        ),
        OnboardingQuestion(
            title: "What aspect of being human feels most mysterious to you?",
            subtitle: "Wonder points us toward our growth edges",
            type: .multipleChoice,
            options: [
                OnboardingOption(text: "How we can feel so connected yet so alone", emoji: "🌌"),
                OnboardingOption(text: "The way love can heal and hurt simultaneously", emoji: "💫"),
                OnboardingOption(text: "How consciousness experiences itself", emoji: "👁️"),
                OnboardingOption(text: "Why some moments feel eternal while others vanish", emoji: "⏳")
            ]
        ),
        OnboardingQuestion(
            title: "When you imagine your most authentic self, what quality shines brightest?",
            subtitle: "Our essence reveals itself in authentic moments",
            type: .multipleChoice,
            options: [
                OnboardingOption(text: "A fierce tenderness that embraces all of life", emoji: "🔥"),
                OnboardingOption(text: "An unshakeable peace that anchors others", emoji: "⚓"),
                OnboardingOption(text: "A creative force that transforms everything I touch", emoji: "🎨"),
                OnboardingOption(text: "A wisdom that sees through illusion to truth", emoji: "💎")
            ]
        ),
        OnboardingQuestion(
            title: "What sacred practice calls to your soul right now?",
            subtitle: "Different seasons of life require different medicine",
            type: .multipleChoice,
            options: [
                OnboardingOption(text: "Deep listening—to others, nature, and silence", emoji: "👂"),
                OnboardingOption(text: "Radical honesty with myself and others", emoji: "🗣️"),
                OnboardingOption(text: "Cultivating presence in each moment", emoji: "🧘"),
                OnboardingOption(text: "Creating beauty as an offering to existence", emoji: "🌺")
            ]
        ),
        OnboardingQuestion(
            title: "How does your heart respond to the world's suffering?",
            subtitle: "Compassion reveals our interconnectedness",
            type: .multipleChoice,
            options: [
                OnboardingOption(text: "It breaks open, making me more tender", emoji: "💚"),
                OnboardingOption(text: "It ignites a fire to create change", emoji: "🔥"),
                OnboardingOption(text: "It feels too much, so I protect myself", emoji: "🛡️"),
                OnboardingOption(text: "It reminds me we're all walking each other home", emoji: "🏠")
            ]
        ),
        OnboardingQuestion(
            title: "What pattern in your life are you most ready to transform?",
            subtitle: "Awareness of our patterns is the doorway to freedom",
            type: .multipleChoice,
            options: [
                OnboardingOption(text: "Seeking external validation for my worth", emoji: "🪞"),
                OnboardingOption(text: "Avoiding difficult emotions or conversations", emoji: "🚪"),
                OnboardingOption(text: "Perfectionism that paralyzes my creativity", emoji: "❄️"),
                OnboardingOption(text: "Playing small to avoid disappointing others", emoji: "📦")
            ]
        ),
        OnboardingQuestion(
            title: "In moments of deep uncertainty, where do you find solid ground?",
            subtitle: "Our anchor points reveal our inner resources",
            type: .multipleChoice,
            options: [
                OnboardingOption(text: "In my breath, returning to this present moment", emoji: "💨"),
                OnboardingOption(text: "In nature's rhythms and eternal wisdom", emoji: "🌳"),
                OnboardingOption(text: "In trusted relationships and community", emoji: "👥"),
                OnboardingOption(text: "In a sense of something greater than myself", emoji: "🌟")
            ]
        ),
        OnboardingQuestion(
            title: "What does spiritual maturity mean to you?",
            subtitle: "Our definition shapes our destination",
            type: .multipleChoice,
            options: [
                OnboardingOption(text: "Holding paradox without needing to resolve it", emoji: "⚖️"),
                OnboardingOption(text: "Loving without attachment to outcome", emoji: "🕊️"),
                OnboardingOption(text: "Seeing the sacred in ordinary moments", emoji: "👀"),
                OnboardingOption(text: "Taking responsibility for my inner landscape", emoji: "🗺️")
            ]
        ),
        OnboardingQuestion(
            title: "What gift are you here to give to the world?",
            subtitle: "Your unique offering is needed in this time",
            type: .multipleChoice,
            options: [
                OnboardingOption(text: "A mirror that reflects others' hidden beauty", emoji: "🔮"),
                OnboardingOption(text: "A bridge between worlds that seem separate", emoji: "🌉"),
                OnboardingOption(text: "A reminder that healing and joy are possible", emoji: "🌈"),
                OnboardingOption(text: "A beacon for those lost in the darkness", emoji: "🕯️")
            ]
        ),
        OnboardingQuestion(
            title: "How do you want to be different one year from now?",
            subtitle: "Intention creates the pathway for transformation",
            type: .multipleChoice,
            options: [
                OnboardingOption(text: "More trusting of my own inner knowing", emoji: "🧭"),
                OnboardingOption(text: "Able to love more freely and fearlessly", emoji: "💖"),
                OnboardingOption(text: "Living from my center, unshaken by others' opinions", emoji: "🎯"),
                OnboardingOption(text: "At peace with all parts of myself", emoji: "☯️")
            ]
        ),
        OnboardingQuestion(
            title: "What would you most like to surrender?",
            subtitle: "Letting go creates space for what wants to emerge",
            type: .multipleChoice,
            options: [
                OnboardingOption(text: "The exhausting need to control outcomes", emoji: "🌊"),
                OnboardingOption(text: "Stories that keep me small and stuck", emoji: "📚"),
                OnboardingOption(text: "The armor that protects but also isolates", emoji: "⚔️"),
                OnboardingOption(text: "The belief that I'm not enough as I am", emoji: "🪶")
            ]
        )
    ]
    
    var isComplete: Bool {
        return showPersonalizationLoading
    }
    
    var shouldShowReviews: Bool {
        return currentQuestionIndex >= questions.count && !showReviews && !showPersonalizationLoading
    }
    
    func selectAnswer(questionId: UUID, optionId: UUID) {
        answers[questionId] = optionId
    }
    
    func setTextAnswer(questionId: UUID, text: String) {
        textAnswers[questionId] = text
    }
    
    func nextQuestion() {
        if currentQuestionIndex < questions.count {
            currentQuestionIndex += 1
        } else if !showReviews {
            showReviews = true
        }
    }
    
    func startPersonalization() {
        showPersonalizationLoading = true
    }
    
    func getUserName() -> String {
        if let nameQuestion = questions.first(where: { $0.title.contains("name") }),
           let name = textAnswers[nameQuestion.id], !name.isEmpty {
            return name
        }
        return "friend"
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
                    PersonalizationLoadingView(onboardingState: onboardingState, onFinish: onFinish)
                } else if onboardingState.shouldShowReviews {
                    ReviewsView(onboardingState: onboardingState)
                } else {
                    let currentQuestion = onboardingState.questions[onboardingState.currentQuestionIndex]
                    if currentQuestion.type == .textInput {
                        TextInputQuestionView(
                            question: currentQuestion,
                            onboardingState: onboardingState,
                            geometry: geometry
                        )
                    } else {
                        OnboardingQuestionView(
                            question: currentQuestion,
                            onboardingState: onboardingState,
                            geometry: geometry
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Text Input Question View
struct TextInputQuestionView: View {
    let question: OnboardingQuestion
    @ObservedObject var onboardingState: OnboardingState
    let geometry: GeometryProxy
    
    @State private var textInput: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Progress indicator
                ScrollView(.horizontal, showsIndicators: false) {
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
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 60)
                .padding(.bottom, 30)
                
                // Question and subtitle
                VStack(spacing: 16) {
                    Text(question.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .shadow(color: Color.purple.opacity(0.5), radius: 8, x: 0, y: 0)
                    
                    if let subtitle = question.subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
                            .shadow(color: Color.indigo.opacity(0.4), radius: 6, x: 0, y: 0)
                    }
                }
                .padding(.horizontal, 32)
                
                // Text input centered vertically
                VStack {
                    Spacer()
                    
                    TextField("Enter your preferred name", text: $textInput)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.05, blue: 0.2))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            isTextFieldFocused ?
                                            Color.white :
                                            Color.white.opacity(0.5),
                                            lineWidth: isTextFieldFocused ? 2 : 1
                                        )
                                )
                        )
                        .focused($isTextFieldFocused)
                        .onChange(of: textInput) { newValue in
                            onboardingState.setTextAnswer(questionId: question.id, text: newValue)
                        }
                        .padding(.horizontal, 32)
                    
                    Spacer()
                }
                
                // Space for continue button
                Color.clear
                    .frame(height: 100)
            }
            
            // Fixed continue button at bottom
            VStack {
                Spacer()
                
                Button(action: {
                    if !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        isTextFieldFocused = false
                        withAnimation(.easeInOut(duration: 0.5)) {
                            onboardingState.nextQuestion()
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Continue")
                            .font(.body)
                            .fontWeight(!textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .semibold : .medium)
                            .foregroundColor(!textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(red: 0.1, green: 0.05, blue: 0.2) : Color(red: 0.3, green: 0.25, blue: 0.35))
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(!textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(red: 0.1, green: 0.05, blue: 0.2) : Color(red: 0.3, green: 0.25, blue: 0.35))
                            .font(.system(size: 14, weight: .bold))
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                Color.white.opacity(0.95) :
                                Color.white.opacity(0.75)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                        Color.white :
                                        Color.white.opacity(0.5),
                                        lineWidth: !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 3 : 1
                                    )
                            )
                    )
                    .shadow(color: !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.white.opacity(0.5) : Color.clear, radius: 10, x: 0, y: 0)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .scaleEffect(!textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 1.03 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: textInput)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Load existing text if any
            if let existingText = onboardingState.textAnswers[question.id] {
                textInput = existingText
            }
        }
        .onChange(of: onboardingState.currentQuestionIndex) { _ in
            textInput = ""
        }
    }
}

// MARK: - Question View
struct OnboardingQuestionView: View {
    let question: OnboardingQuestion
    @ObservedObject var onboardingState: OnboardingState
    let geometry: GeometryProxy
    
    @State private var selectedOption: UUID?
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Progress indicator
                ScrollView(.horizontal, showsIndicators: false) {
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
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 60)
                .padding(.bottom, 30)
                
                // Question and subtitle
                VStack(spacing: 16) {
                    Text(question.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .shadow(color: Color.purple.opacity(0.5), radius: 8, x: 0, y: 0)
                    
                    if let subtitle = question.subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
                            .shadow(color: Color.indigo.opacity(0.4), radius: 6, x: 0, y: 0)
                    }
                }
                .padding(.horizontal, 32)
                
                // Options centered vertically
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        ForEach(question.options, id: \.id) { option in
                            OptionButton(
                                option: option,
                                isSelected: selectedOption == option.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selectedOption = option.id
                                    }
                                    onboardingState.selectAnswer(questionId: question.id, optionId: option.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
                
                // Space for continue button
                Color.clear
                    .frame(height: 100)
            }
            
            // Fixed continue button at bottom
            VStack {
                Spacer()
                
                Button(action: {
                    if selectedOption != nil {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            onboardingState.nextQuestion()
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Continue")
                            .font(.body)
                            .fontWeight(selectedOption != nil ? .semibold : .medium)
                            .foregroundColor(selectedOption != nil ? Color(red: 0.1, green: 0.05, blue: 0.2) : Color(red: 0.3, green: 0.25, blue: 0.35))
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(selectedOption != nil ? Color(red: 0.1, green: 0.05, blue: 0.2) : Color(red: 0.3, green: 0.25, blue: 0.35))
                            .font(.system(size: 14, weight: .bold))
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                selectedOption != nil ?
                                Color.white.opacity(0.95) :
                                Color.white.opacity(0.75)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        selectedOption != nil ?
                                        Color.white :
                                        Color.white.opacity(0.5),
                                        lineWidth: selectedOption != nil ? 3 : 1
                                    )
                            )
                    )
                    .shadow(color: selectedOption != nil ? Color.white.opacity(0.5) : Color.clear, radius: 10, x: 0, y: 0)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(selectedOption == nil)
                .scaleEffect(selectedOption != nil ? 1.03 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedOption)
                .padding(.bottom, 50)
            }
        }
        .onChange(of: onboardingState.currentQuestionIndex) { _ in
            selectedOption = nil
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
            HStack(spacing: 12) {
                Circle()
                    .fill(isSelected ? Color.white : Color.clear)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .overlay(
                        Circle()
                            .fill(Color(red: 0.4, green: 0.3, blue: 0.6))
                            .frame(width: 12, height: 12)
                            .opacity(isSelected ? 1 : 0)
                            .scaleEffect(isSelected ? 1 : 0.5)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                    )
                
                Text(option.emoji)
                    .font(.title2)
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                
                Text(option.text)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? Color(red: 0.1, green: 0.05, blue: 0.2) : Color(red: 0.2, green: 0.15, blue: 0.3))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ? 
                        Color.white.opacity(0.95) : 
                        Color.white.opacity(0.75)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? 
                                Color.white : 
                                Color.white.opacity(0.5),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .shadow(color: isSelected ? Color.white.opacity(0.5) : Color.clear, radius: 10, x: 0, y: 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Reviews View
struct ReviewsView: View {
    @ObservedObject var onboardingState: OnboardingState
    @State private var hasAnimated = false
    @State private var hasRequestedReview = false
    
    let reviews = [
        Review(name: "Sarah M.", rating: 5, text: "This app has transformed my daily spiritual practice. The personalized guidance feels like it's speaking directly to my soul.", date: "3 days ago"),
        Review(name: "Michael R.", rating: 5, text: "I've never felt more understood by an app. Every message arrives exactly when I need it most. Truly magical.", date: "1 week ago"),
        Review(name: "Luna K.", rating: 5, text: "The wisdom here is profound yet accessible. It's like having a spiritual mentor in my pocket 24/7.", date: "2 weeks ago"),
        Review(name: "David L.", rating: 5, text: "After years of searching, I finally found something that speaks to my heart. This app gets me on a level I didn't think was possible.", date: "3 weeks ago")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Title section
            VStack(spacing: 16) {
                Text("✨")
                    .font(.system(size: 35))
                    .scaleEffect(hasAnimated ? 1.0 : 0.5)
                    .opacity(hasAnimated ? 1 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: hasAnimated)
                
                Text("What Others Are Saying")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .opacity(hasAnimated ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: hasAnimated)
                
                Text("Join thousands finding their path")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .opacity(hasAnimated ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: hasAnimated)
            }
            .padding(.top, 40)
            
            // Reviews (non-scrollable, showing all 4)
            VStack(spacing: 8) {
                ForEach(Array(reviews.enumerated()), id: \.element.id) { index, review in
                    ReviewCard(review: review)
                        .opacity(hasAnimated ? 1 : 0)
                        .offset(y: hasAnimated ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.8 + Double(index) * 0.1), value: hasAnimated)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .overlay(
            VStack {
                Spacer()
                
                if !hasRequestedReview {
                    // Leave a Review button
                    Button(action: {
                        // Show native iOS review popup
                        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            hasRequestedReview = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text("Leave a Review")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 0.1, green: 0.05, blue: 0.2))
                            
                            Image(systemName: "star.fill")
                                .foregroundColor(Color(red: 0.1, green: 0.05, blue: 0.2))
                                .font(.system(size: 14, weight: .bold))
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.95))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        )
                        .shadow(color: Color.white.opacity(0.3), radius: 8, x: 0, y: 0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(hasAnimated ? 1 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(1.5), value: hasAnimated)
                } else {
                    // Get Started button (appears after review is requested)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            onboardingState.startPersonalization()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text("Get Started")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 0.1, green: 0.05, blue: 0.2))
                            
                            Image(systemName: "sparkles")
                                .foregroundColor(Color(red: 0.1, green: 0.05, blue: 0.2))
                                .font(.system(size: 14, weight: .bold))
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.95))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        )
                        .shadow(color: Color.white.opacity(0.3), radius: 8, x: 0, y: 0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(1.05)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: hasRequestedReview)
                    .padding(.bottom, 50)
                }
                
                // Skip button (always visible)
                if !hasRequestedReview {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            onboardingState.startPersonalization()
                        }
                    }) {
                        Text("Skip")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.7))
                            .underline()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(hasAnimated ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(2.0), value: hasAnimated)
                    .padding(.bottom, 30)
                }
            }
        )
        .onAppear {
            hasAnimated = true
        }
    }
}

struct Review {
    let id = UUID()
    let name: String
    let rating: Int
    let text: String
    let date: String
}

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.1, green: 0.05, blue: 0.2))
                    
                    HStack(spacing: 2) {
                        ForEach(0..<review.rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 13))
                        }
                    }
                }
                
                Spacer()
                
                Text(review.date)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.4))
            }
            
            Text(review.text)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.15, green: 0.1, blue: 0.25))
                .lineLimit(3)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.92))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        )
    }
}

// MARK: - Personalization Loading View
struct PersonalizationLoadingView: View {
    @ObservedObject var onboardingState: OnboardingState
    let onFinish: () -> Void
    
    @State private var currentMessageIndex = 0
    @State private var showMessage = false
    @State private var progressValue: CGFloat = 0
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    @State private var showSparkles = false
    
    let messages: [String]
    
    init(onboardingState: OnboardingState, onFinish: @escaping () -> Void) {
        self.onboardingState = onboardingState
        self.onFinish = onFinish
        
        let userName = onboardingState.getUserName()
        self.messages = [
            "Welcome, \(userName)...",
            "Analyzing your spiritual profile...",
            "Understanding your unique journey...",
            "Connecting with universal wisdom...",
            "Aligning with your inner truth...",
            "Personalizing your sacred space...",
            "Calibrating guidance frequencies...",
            "Your path is being illuminated..."
        ]
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.4 + progressValue * 0.2),
                    Color.indigo.opacity(0.5 + progressValue * 0.2),
                    Color.blue.opacity(0.4 + progressValue * 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.5), value: progressValue)
            
            VStack(spacing: 40) {
                Spacer()
                
                // Main animated icon
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 150, height: 150)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.8)
                        .animation(
                            Animation.easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                    
                    // Middle rotating ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(Angle(degrees: rotationAngle))
                        .animation(
                            Animation.linear(duration: 8)
                                .repeatForever(autoreverses: false),
                            value: rotationAngle
                        )
                    
                    // Center icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .scaleEffect(showSparkles ? 1.1 : 0.9)
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                            value: showSparkles
                        )
                }
                
                // Progress bar
                VStack(spacing: 20) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 250, height: 8)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 250 * progressValue, height: 8)
                            .animation(.easeInOut(duration: 0.5), value: progressValue)
                    }
                    
                    // Animated messages
                    Text(currentMessageIndex < messages.count ? messages[currentMessageIndex] : "")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(showMessage ? 1 : 0)
                        .animation(.easeIn(duration: 0.5), value: showMessage)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            
            // Floating particles
            ForEach(0..<12) { index in
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: CGFloat.random(in: 4...8))
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: showSparkles ? CGFloat.random(in: 100...700) : CGFloat.random(in: 100...700) + 50
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...5))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: showSparkles
                    )
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        pulseAnimation = true
        rotationAngle = 360
        showSparkles = true
        
        // Cycle through messages
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { timer in
            withAnimation {
                showMessage = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if currentMessageIndex < messages.count - 1 {
                    currentMessageIndex += 1
                    progressValue = CGFloat(currentMessageIndex + 1) / CGFloat(messages.count)
                    withAnimation {
                        showMessage = true
                    }
                } else {
                    timer.invalidate()
                    // Trigger paywall after loading completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onFinish()
                    }
                }
            }
        }
        
        // Show first message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showMessage = true
            }
        }
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
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .opacity(hasAnimated ? 1 : 0)
                        .offset(y: hasAnimated ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.5), value: hasAnimated)
                    
                    Text("Thank you for sharing your heart with us. Your personalized guidance awaits.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.95))
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
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
                        .foregroundColor(Color(red: 0.15, green: 0.1, blue: 0.25))
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(Color(red: 0.15, green: 0.1, blue: 0.25))
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white, lineWidth: 2)
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
