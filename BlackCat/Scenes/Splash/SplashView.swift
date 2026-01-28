import SwiftUI

// MARK: - Splash View

/// アプリ起動時に表示されるスプラッシュ画面
/// アニメーション付きでアプリロゴとアプリ名を表示
struct SplashView: View {

    // MARK: - Properties

    @Binding var isActive: Bool

    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var glowOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0

    /// アクセシビリティ: モーションを減らす設定
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.BlackCat.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Logo Container
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.BlackCat.accentPrimary.opacity(0.6),
                                    Color.BlackCat.accentPrimary.opacity(0.0)
                                ]),
                                center: .center,
                                startRadius: 50,
                                endRadius: 120
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.BlackCat.accentPrimary.opacity(0.3),
                                    Color.BlackCat.accentPrimary.opacity(0.0)
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 180, height: 180)
                        .opacity(glowOpacity)

                    // App Icon (using SF Symbol as placeholder)
                    ZStack {
                        // Icon background circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.BlackCat.backgroundCard,
                                        Color.BlackCat.backgroundSecondary
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(
                                color: Color.BlackCat.accentPrimary.opacity(0.4),
                                radius: 20,
                                x: 0,
                                y: 10
                            )

                        // Cat icon
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 50, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.BlackCat.accentPrimary,
                                        Color.BlackCat.primaryOrange
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                }
                .frame(height: 200)

                // App Name
                VStack(spacing: 8) {
                    Text("BlackCat")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white,
                                    Color.BlackCat.shadowLevel2
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("クロネコ配達状況")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.BlackCat.shadowLevel3)
                        .tracking(2)
                }
                .opacity(textOpacity)
                .offset(y: textOffset)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        if reduceMotion {
            // モーション軽減が有効な場合は即座に表示
            logoScale = 1.0
            logoOpacity = 1.0
            textOpacity = 1.0
            textOffset = 0
            glowOpacity = 1.0
            ringScale = 1.0
            ringOpacity = 1.0

            // 少し待ってからメイン画面へ遷移
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isActive = true
                }
            }
            return
        }

        // Logo fade in and scale
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // Glow effect
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            glowOpacity = 1.0
        }

        // Ring animation
        withAnimation(.spring(response: 0.7, dampingFraction: 0.5).delay(0.3)) {
            ringScale = 1.0
            ringOpacity = 0.8
        }

        // Text fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            textOpacity = 1.0
            textOffset = 0
        }

        // Transition to main content
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.4)) {
                isActive = true
            }
        }
    }
}

// MARK: - Preview

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(isActive: .constant(false))
            .preferredColorScheme(.dark)
    }
}
