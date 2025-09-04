import SwiftUI

struct OnboardingFlowView: View {
    /// Callback that runs when onboarding is complete
    var onFinish: () -> Void

    var body: some View {
        VStack {
            Text("Welcome to the App!")

            Button("Get Started") {
                // ✅ Call the completion handler
                onFinish()
            }
        }
        .padding()
    }
}

#Preview {
    OnboardingFlowView {
        print("Onboarding finished (preview)")
    }
}
