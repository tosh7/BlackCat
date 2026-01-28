import SwiftUI

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconName: String
    let accentColor: Color
}

// MARK: - Onboarding Manager

final class OnboardingManager {
    static let shared = OnboardingManager()

    private let hasSeenOnboardingKey = "hasSeenOnboarding"

    private init() {}

    var hasSeenOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeenOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeenOnboardingKey) }
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
    }

    func resetOnboarding() {
        hasSeenOnboarding = false
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isAnimating = false
    @Binding var isOnboardingComplete: Bool

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "荷物追跡を簡単に",
            subtitle: "BlackCatアプリで\nすべての荷物を一元管理",
            iconName: "shippingbox.fill",
            accentColor: Color.BlackCat.primaryBlue
        ),
        OnboardingPage(
            title: "伝票番号を入力するだけ",
            subtitle: "簡単な操作で\nリアルタイムに配送状況を確認",
            iconName: "barcode.viewfinder",
            accentColor: Color.BlackCat.primaryOrange
        ),
        OnboardingPage(
            title: "複数の配送業者に対応",
            subtitle: "ヤマト運輸、佐川急便など\n主要な配送業者をサポート",
            iconName: "truck.box.fill",
            accentColor: Color.BlackCat.primaryGreen
        ),
        OnboardingPage(
            title: "さあ、始めましょう",
            subtitle: "あなたの荷物を\n今すぐ追跡しましょう",
            iconName: "hand.thumbsup.fill",
            accentColor: Color.BlackCat.accentPrimary
        )
    ]

    var body: some View {
        ZStack {
            // Background
            Color.BlackCat.backgroundPrimary
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            HapticManager.shared.buttonTap()
                            completeOnboarding()
                        }) {
                            Text("スキップ")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.BlackCat.shadowLevel3)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.top, 16)
                .padding(.trailing, 8)
                .frame(height: 50)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(
                            page: page,
                            isAnimating: $isAnimating,
                            pageIndex: index,
                            currentPage: currentPage
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.smoothSpring, value: currentPage)

                // Bottom section
                VStack(spacing: 30) {
                    // Page indicator
                    PageIndicator(
                        numberOfPages: pages.count,
                        currentPage: currentPage
                    )

                    // Action button
                    Button(action: {
                        HapticManager.shared.pageTransition()
                        if currentPage < pages.count - 1 {
                            withAnimation(.smoothSpring) {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text(currentPage < pages.count - 1 ? "次へ" : "始める")
                                .fontWeight(.bold)

                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                                .font(.body.weight(.bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    pages[currentPage].accentColor,
                                    pages[currentPage].accentColor.opacity(0.7)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: pages[currentPage].accentColor.opacity(0.4),
                            radius: 15,
                            x: 0,
                            y: 8
                        )
                    }
                    .padding(.horizontal, 40)
                    .animation(.smoothSpring, value: currentPage)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }

    private func completeOnboarding() {
        OnboardingManager.shared.completeOnboarding()
        withAnimation(.smoothSpring) {
            isOnboardingComplete = true
        }
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var isAnimating: Bool
    let pageIndex: Int
    let currentPage: Int

    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -30
    @State private var textOpacity: Double = 0
    @State private var floatingOffset: CGFloat = 0

    private var isCurrentPage: Bool {
        pageIndex == currentPage
    }

    var body: some View {
        VStack(spacing: 50) {
            Spacer()

            // Animated icon container
            ZStack {
                // Outer glow circle
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                page.accentColor.opacity(0.3),
                                page.accentColor.opacity(0.0)
                            ]),
                            center: .center,
                            startRadius: 60,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .scaleEffect(isCurrentPage && isAnimating ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                // Background circle 1
                Circle()
                    .fill(Color.BlackCat.backgroundCard.opacity(0.6))
                    .frame(width: 200, height: 200)
                    .scaleEffect(isCurrentPage && isAnimating ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                // Background circle 2
                Circle()
                    .fill(Color.BlackCat.backgroundSecondary.opacity(0.8))
                    .frame(width: 150, height: 150)
                    .scaleEffect(isCurrentPage && isAnimating ? 1.08 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.8)
                        .repeatForever(autoreverses: true)
                        .delay(0.2),
                        value: isAnimating
                    )

                // Main icon
                Image(systemName: page.iconName)
                    .font(.system(size: 70, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                page.accentColor,
                                page.accentColor.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isCurrentPage ? iconScale : 0.8)
                    .rotationEffect(.degrees(isCurrentPage ? 0 : iconRotation))
                    .offset(y: floatingOffset)
                    .shadow(color: page.accentColor.opacity(0.5), radius: 20, x: 0, y: 10)

                // Decorative elements
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(page.accentColor.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .offset(
                            x: cos(Double(index) * 2.1 + (isAnimating ? 3.14 : 0)) * 80,
                            y: sin(Double(index) * 2.1 + (isAnimating ? 3.14 : 0)) * 80
                        )
                        .animation(
                            .easeInOut(duration: 3.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                            value: isAnimating
                        )
                }
            }
            .frame(height: 300)

            // Text content
            VStack(spacing: 20) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(Color.BlackCat.shadowLevel3)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .opacity(textOpacity)
            .offset(y: textOpacity == 1 ? 0 : 20)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
        .onChange(of: currentPage) { _ in
            if isCurrentPage {
                animatePageIn()
            }
        }
        .onAppear {
            if isCurrentPage {
                animatePageIn()
            }
        }
    }

    private func animatePageIn() {
        // Reset states
        iconScale = 0.5
        iconRotation = -30
        textOpacity = 0

        // Animate in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            iconScale = 1.0
            iconRotation = 0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            textOpacity = 1
        }

        // Start floating animation
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            floatingOffset = -10
        }
    }
}

// MARK: - Page Indicator

struct PageIndicator: View {
    let numberOfPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage
                          ? Color.BlackCat.accentPrimary
                          : Color.BlackCat.shadowLevel5)
                    .frame(
                        width: index == currentPage ? 24 : 8,
                        height: 8
                    )
                    .animation(.smoothSpring, value: currentPage)
            }
        }
    }
}

// MARK: - Root View with Onboarding

struct RootView: View {
    @State private var isOnboardingComplete: Bool

    init() {
        _isOnboardingComplete = State(initialValue: OnboardingManager.shared.hasSeenOnboarding)
    }

    var body: some View {
        ZStack {
            if isOnboardingComplete {
                DeliveryListView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            } else {
                OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                    .transition(.opacity)
            }
        }
        .animation(.smoothSpring, value: isOnboardingComplete)
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isOnboardingComplete: .constant(false))
            .preferredColorScheme(.dark)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .preferredColorScheme(.dark)
    }
}
