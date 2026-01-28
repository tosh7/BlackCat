import SwiftUI

// MARK: - Confetti Particle Model
struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let shape: ConfettiShape
    let position: CGPoint
    let rotation: Double
    let rotationSpeed: Double
    let fallSpeed: Double
    let horizontalDrift: Double
    let size: CGFloat

    enum ConfettiShape: CaseIterable {
        case square
        case circle
        case rectangle
    }
}

// MARK: - Confetti View
struct ConfettiView: View {

    // MARK: - Environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Properties
    @Binding var isShowing: Bool
    @State private var particles: [ConfettiParticle] = []
    @State private var animationProgress: CGFloat = 0

    private let particleCount: Int = 50
    private let animationDuration: Double = 3.0

    /// Confetti colors using app theme
    private let confettiColors: [Color] = [
        Color.BlackCat.primaryBlue,
        Color.BlackCat.primaryGreen,
        Color.BlackCat.primaryOrange,
        Color.BlackCat.naturalGreen,
        Color.BlackCat.pureYellow,
        Color.BlackCat.purePink,
        Color.BlackCat.purePurple,
        Color.BlackCat.accentPrimary
    ]

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isShowing && !reduceMotion {
                    ForEach(particles) { particle in
                        ConfettiParticleView(
                            particle: particle,
                            progress: animationProgress,
                            screenHeight: geometry.size.height
                        )
                    }
                }
            }
            .onChange(of: isShowing) { newValue in
                if newValue && !reduceMotion {
                    startAnimation(in: geometry.size)
                }
            }
            .onAppear {
                if isShowing && !reduceMotion {
                    startAnimation(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Animation
    private func startAnimation(in size: CGSize) {
        // Generate particles
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                color: confettiColors.randomElement() ?? Color.BlackCat.primaryGreen,
                shape: ConfettiParticle.ConfettiShape.allCases.randomElement() ?? .square,
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: -100...(-20))
                ),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 180...720),
                fallSpeed: Double.random(in: 0.8...1.2),
                horizontalDrift: Double.random(in: -50...50),
                size: CGFloat.random(in: 8...16)
            )
        }

        // Reset and start animation
        animationProgress = 0

        withAnimation(.easeOut(duration: animationDuration)) {
            animationProgress = 1
        }

        // Hide after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            isShowing = false
            particles = []
        }
    }
}

// MARK: - Individual Particle View
struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    let progress: CGFloat
    let screenHeight: CGFloat

    private var currentY: CGFloat {
        let totalDistance = screenHeight + 200
        return particle.position.y + (totalDistance * progress * particle.fallSpeed)
    }

    private var currentX: CGFloat {
        let drift = particle.horizontalDrift * sin(progress * .pi * 2)
        return particle.position.x + drift
    }

    private var currentRotation: Double {
        return particle.rotation + (particle.rotationSpeed * Double(progress))
    }

    private var opacity: Double {
        if progress > 0.7 {
            return Double(1 - ((progress - 0.7) / 0.3))
        }
        return 1.0
    }

    var body: some View {
        particleShape
            .fill(particle.color)
            .frame(width: particle.size, height: shapeHeight)
            .rotationEffect(.degrees(currentRotation))
            .rotation3DEffect(
                .degrees(currentRotation * 0.5),
                axis: (x: 1, y: 0, z: 0)
            )
            .position(x: currentX, y: currentY)
            .opacity(opacity)
    }

    @ViewBuilder
    private var particleShape: some Shape {
        switch particle.shape {
        case .square:
            RoundedRectangle(cornerRadius: 2)
        case .circle:
            Circle()
        case .rectangle:
            RoundedRectangle(cornerRadius: 1)
        }
    }

    private var shapeHeight: CGFloat {
        switch particle.shape {
        case .square, .circle:
            return particle.size
        case .rectangle:
            return particle.size * 0.5
        }
    }
}

// MARK: - View Extension for Easy Use
extension View {
    /// Adds a confetti overlay to the view
    /// - Parameters:
    ///   - isShowing: Binding to control confetti visibility
    /// - Returns: View with confetti overlay
    func confetti(isShowing: Binding<Bool>) -> some View {
        ZStack {
            self
            ConfettiView(isShowing: isShowing)
        }
    }
}

// MARK: - Preview
struct ConfettiView_Previews: PreviewProvider {
    struct PreviewContainer: View {
        @State private var showConfetti = false

        var body: some View {
            ZStack {
                Color.BlackCat.backgroundPrimary
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Text("Confetti Test")
                        .font(.title)
                        .foregroundColor(.white)

                    Button("Show Confetti") {
                        showConfetti = true
                    }
                    .padding()
                    .background(Color.BlackCat.primaryBlue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .confetti(isShowing: $showConfetti)
        }
    }

    static var previews: some View {
        PreviewContainer()
            .preferredColorScheme(.dark)
    }
}
