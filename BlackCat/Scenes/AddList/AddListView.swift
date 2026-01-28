import SwiftUI

struct AddListView: View {
    @StateObject var viewModel = AddListViewModel()
    @State private var itemNumber: String = ""
    @State private var isTextFieldFocused: Bool = false
    @State private var showSuccessAnimation: Bool = false
    @State private var shakeOffset: CGFloat = 0
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.BlackCat.backgroundPrimary,
                    Color.BlackCat.backgroundSecondary
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: dynamicTypeSize.isAccessibilitySize ? 24 : 32) {
                    // Header
                    headerSection

                    // Carrier Selection
                    carrierSelectionSection

                    // Tracking Number Input
                    trackingNumberSection

                    // Barcode Scan Button
                    barcodeScanSection

                    // Register Button
                    registerButtonSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }

            // Success overlay
            if showSuccessAnimation {
                successOverlay
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.BlackCat.primaryGradient)
                .shadow(color: Color.BlackCat.primaryBlue.opacity(0.3), radius: 10, x: 0, y: 5)

            Text("新しい伝票番号を登録")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .accessibilityAddTraits(.isHeader)

            Text("荷物の追跡を開始します")
                .font(.subheadline)
                .foregroundColor(Color.BlackCat.shadowLevel3)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Carrier Selection Section
    private var carrierSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label {
                    Text("配送業者を選択")
                        .font(.headline)
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(Color.BlackCat.primaryBlue)
                }
                .accessibilityAddTraits(.isHeader)

                Spacer()

                // 自動判別インジケーター
                if viewModel.output.isCarrierAutoDetected {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("自動判別")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color.BlackCat.naturalGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.BlackCat.naturalGreen.opacity(0.15))
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }

            HStack(spacing: 12) {
                ForEach(DeliveryCarrier.allCases) { carrier in
                    CarrierCard(
                        carrier: carrier,
                        isSelected: viewModel.output.selectedCarrier == carrier,
                        isAutoDetected: viewModel.output.isCarrierAutoDetected && viewModel.output.selectedCarrier == carrier,
                        onSelect: {
                            HapticManager.shared.carrierSelection()
                            withAnimation(.quickSpring) {
                                viewModel.input.carrierDidChange(carrier: carrier)
                            }
                        }
                    )
                }
            }

            // 自動判別メッセージ
            if !viewModel.output.autoDetectionMessage.isEmpty {
                autoDetectionFeedback
            }
        }
        .animation(.quickSpring, value: viewModel.output.isCarrierAutoDetected)
        .animation(.quickSpring, value: viewModel.output.autoDetectionMessage)
    }

    // MARK: - Auto Detection Feedback
    private var autoDetectionFeedback: some View {
        HStack(spacing: 8) {
            Image(systemName: feedbackIcon)
                .font(.caption)
                .foregroundColor(feedbackColor)

            Text(viewModel.output.autoDetectionMessage)
                .font(.caption)
                .foregroundColor(feedbackColor)

            Spacer()

            // 複数候補がある場合、選択ボタンを表示
            if case .multipleCandidates(let carriers) = viewModel.output.carrierDetectionResult {
                Menu {
                    ForEach(carriers) { carrier in
                        Button(action: {
                            HapticManager.shared.carrierSelection()
                            withAnimation(.quickSpring) {
                                viewModel.input.carrierDidChange(carrier: carrier)
                            }
                        }) {
                            Label(carrier.displayName, systemImage: carrier.iconName)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("選択")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(Color.BlackCat.primaryBlue)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(feedbackBackgroundColor)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var feedbackIcon: String {
        switch viewModel.output.carrierDetectionResult {
        case .detected:
            return "checkmark.circle.fill"
        case .multipleCandidates:
            return "questionmark.circle.fill"
        case .unknown:
            return "exclamationmark.triangle.fill"
        case .insufficientInput:
            return "info.circle"
        }
    }

    private var feedbackColor: Color {
        switch viewModel.output.carrierDetectionResult {
        case .detected:
            return Color.BlackCat.naturalGreen
        case .multipleCandidates:
            return Color.BlackCat.primaryOrange
        case .unknown:
            return Color.BlackCat.primaryOrange
        case .insufficientInput:
            return Color.BlackCat.shadowLevel3
        }
    }

    private var feedbackBackgroundColor: Color {
        switch viewModel.output.carrierDetectionResult {
        case .detected:
            return Color.BlackCat.naturalGreen.opacity(0.1)
        case .multipleCandidates:
            return Color.BlackCat.primaryOrange.opacity(0.1)
        case .unknown:
            return Color.BlackCat.primaryOrange.opacity(0.1)
        case .insufficientInput:
            return Color.BlackCat.shadowLevel6
        }
    }

    // MARK: - Tracking Number Section
    private var trackingNumberSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("伝票番号")
                    .font(.headline)
                    .foregroundColor(.white)
            } icon: {
                Image(systemName: "number.circle.fill")
                    .foregroundColor(Color.BlackCat.primaryOrange)
            }
            .accessibilityAddTraits(.isHeader)

            // Input field with modern design
            ModernTextField(
                text: $itemNumber,
                placeholder: "伝票番号を入力",
                icon: "doc.text.magnifyingglass",
                isValid: viewModel.output.isButtonEnabled,
                hasError: !viewModel.output.cautionMessage.isEmpty && !itemNumber.isEmpty,
                onTextChange: { text in
                    viewModel.textFieldDidChange(text: text)
                    // テキストクリア時に自動判別をリセット
                    if text.isEmpty {
                        viewModel.resetAutoDetection()
                    }
                }
            )
            .offset(x: shakeOffset)

            // Input guidance
            HStack(spacing: 8) {
                if viewModel.output.cautionMessage.isEmpty {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(Color.BlackCat.shadowLevel3)
                    Text("伝票番号を入力すると配送業者を自動判別します")
                        .font(.caption)
                        .foregroundColor(Color.BlackCat.shadowLevel3)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(Color.BlackCat.primaryOrange)
                    Text(viewModel.output.cautionMessage)
                        .font(.caption)
                        .foregroundColor(Color.BlackCat.primaryOrange)
                }

                Spacer()

                // Character count (11-13桁対応)
                Text("\(itemNumber.count)桁")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(
                        (itemNumber.count >= 11 && itemNumber.count <= 13)
                            ? Color.BlackCat.naturalGreen
                            : Color.BlackCat.shadowLevel3
                    )
            }
            .padding(.horizontal, 4)
            .animation(.gentleEaseOut, value: viewModel.output.cautionMessage)
        }
    }

    // MARK: - Barcode Scan Section
    private var barcodeScanSection: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle()
                    .fill(Color.BlackCat.shadowLevel5)
                    .frame(height: 1)
                Text("または")
                    .font(.caption)
                    .foregroundColor(Color.BlackCat.shadowLevel3)
                Rectangle()
                    .fill(Color.BlackCat.shadowLevel5)
                    .frame(height: 1)
            }
            .padding(.vertical, 8)

            Button(action: {
                // Barcode scan action - not implemented yet
                triggerHapticFeedback()
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.BlackCat.accentPrimary.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 22))
                            .foregroundColor(Color.BlackCat.accentPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("バーコードをスキャン")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text("カメラで伝票番号を読み取り")
                            .font(.caption)
                            .foregroundColor(Color.BlackCat.shadowLevel3)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.BlackCat.shadowLevel4)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.BlackCat.backgroundCard.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.BlackCat.shadowLevel5, Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .accessibilityLabel("バーコードをスキャン")
            .accessibilityHint("カメラを使用して伝票番号を読み取ります")
        }
    }

    // MARK: - Register Button Section
    private var registerButtonSection: some View {
        Button(action: {
            if viewModel.output.isButtonEnabled {
                triggerHapticFeedback()
                viewModel.input.buttonDidTap()
            } else {
                triggerErrorShake()
            }
        }) {
            HStack(spacing: 12) {
                if viewModel.output.isButtonEnabled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                }
                Text("登録する")
                    .font(.body)
                    .fontWeight(.bold)
            }
            .foregroundColor(viewModel.output.isButtonEnabled ? .black : Color.BlackCat.shadowLevel4)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if viewModel.output.isButtonEnabled {
                        Color.BlackCat.successGradient
                    } else {
                        Color.BlackCat.shadowLevel6
                    }
                }
            )
            .cornerRadius(16)
            .shadow(
                color: viewModel.output.isButtonEnabled ? Color.BlackCat.naturalGreen.opacity(0.4) : Color.clear,
                radius: 12,
                x: 0,
                y: 6
            )
            .scaleEffect(viewModel.output.isButtonEnabled ? 1.0 : 0.98)
            .animation(.quickSpring, value: viewModel.output.isButtonEnabled)
        }
        .disabled(!viewModel.output.isButtonEnabled)
        .accessibilityLabel("登録する")
        .accessibilityHint(viewModel.output.isButtonEnabled ? "伝票番号を登録します" : "伝票番号を入力すると有効になります")
        .accessibilityAddTraits(viewModel.output.isButtonEnabled ? .isButton : [.isButton, .isNotEnabled])
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(
                title: Text(viewModel.output.errorMessage),
                dismissButton: .default(Text("OK")) {
                    if viewModel.output.errorMessage == "登録に成功しました" {
                        triggerSuccessFeedback()
                        showSuccessAnimation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            )
        }
        .padding(.top, 8)
    }

    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color.BlackCat.naturalGreen)
                    .scaleEffect(showSuccessAnimation ? 1.0 : 0.5)
                    .opacity(showSuccessAnimation ? 1.0 : 0)
                    .animation(.smoothSpring, value: showSuccessAnimation)

                Text("登録完了")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(showSuccessAnimation ? 1.0 : 0)
                    .animation(.gentleEaseOut.delay(0.2), value: showSuccessAnimation)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Helper Methods
    private func triggerHapticFeedback() {
        HapticManager.shared.mediumImpact()
    }

    private func triggerErrorShake() {
        HapticManager.shared.error()

        withAnimation(.default) {
            shakeOffset = 10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.default) {
                shakeOffset = -10
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.default) {
                shakeOffset = 5
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.default) {
                shakeOffset = 0
            }
        }
    }

    private func triggerSuccessFeedback() {
        HapticManager.shared.success()
    }
}

// MARK: - Carrier Card Component
struct CarrierCard: View {
    let carrier: DeliveryCarrier
    let isSelected: Bool
    var isAutoDetected: Bool = false
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? carrier.brandColor.opacity(0.2)
                                : Color.BlackCat.shadowLevel6
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: carrier.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(
                            isSelected
                                ? carrier.brandColor
                                : Color.BlackCat.shadowLevel3
                        )

                    // Auto-detected sparkle indicator
                    if isAutoDetected {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.BlackCat.naturalGreen)
                            .offset(x: 20, y: -20)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? carrier.brandColor : Color.clear,
                            lineWidth: 2
                        )
                )

                // Carrier name
                VStack(spacing: 2) {
                    Text(carrier.displayName)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? .white : Color.BlackCat.shadowLevel2)

                    Text(carrier.shortDescription)
                        .font(.caption2)
                        .foregroundColor(Color.BlackCat.shadowLevel4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected
                            ? Color.BlackCat.backgroundCard
                            : Color.BlackCat.backgroundCard.opacity(0.4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected
                                    ? (isAutoDetected ? Color.BlackCat.naturalGreen : carrier.brandColor.opacity(0.5))
                                    : Color.BlackCat.shadowLevel6,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? (isAutoDetected ? Color.BlackCat.naturalGreen.opacity(0.2) : carrier.brandColor.opacity(0.2)) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(carrier.displayName)、\(carrier.shortDescription)\(isAutoDetected ? "、自動判別" : "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(isSelected ? "選択中" : "タップして選択")
        .animation(.quickSpring, value: isAutoDetected)
    }
}

// MARK: - Modern TextField Component
struct ModernTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let isValid: Bool
    let hasError: Bool
    let onTextChange: (String) -> Void

    @FocusState private var isFocused: Bool
    @State private var animateIcon: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Leading icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 24)
                .scaleEffect(animateIcon ? 1.1 : 1.0)
                .animation(.quickSpring, value: animateIcon)

            // Text field
            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(Color.BlackCat.shadowLevel4)
                }
                .keyboardType(.numberPad)
                .foregroundColor(.white)
                .font(.body)
                .focused($isFocused)
                .onChange(of: text) { newValue in
                    onTextChange(newValue)
                    withAnimation(.quickSpring) {
                        animateIcon = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.quickSpring) {
                            animateIcon = false
                        }
                    }
                }
                .accessibilityLabel("伝票番号入力欄")
                .accessibilityHint("11から13桁の数字を入力してください。配送業者を自動判別します。")
                .accessibilityValue(text.isEmpty ? "未入力" : text)

            // Clear button or validation indicator
            if !text.isEmpty {
                Button(action: {
                    withAnimation(.quickSpring) {
                        text = ""
                        onTextChange("")
                    }
                    triggerHapticFeedback()
                }) {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isValid ? Color.BlackCat.naturalGreen : Color.BlackCat.shadowLevel4)
                }
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel(isValid ? "入力完了" : "クリア")
                .accessibilityHint(isValid ? "" : "タップして入力をクリア")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.BlackCat.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1)
                )
        )
        .shadow(
            color: isFocused ? borderColor.opacity(0.3) : Color.clear,
            radius: 8,
            x: 0,
            y: 4
        )
        .animation(.quickSpring, value: isFocused)
        .animation(.quickSpring, value: isValid)
        .animation(.quickSpring, value: hasError)
    }

    private var iconColor: Color {
        if isValid {
            return Color.BlackCat.naturalGreen
        } else if hasError {
            return Color.BlackCat.primaryOrange
        } else if isFocused {
            return Color.BlackCat.primaryBlue
        }
        return Color.BlackCat.shadowLevel4
    }

    private var borderColor: Color {
        if isValid {
            return Color.BlackCat.naturalGreen
        } else if hasError {
            return Color.BlackCat.primaryOrange
        } else if isFocused {
            return Color.BlackCat.primaryBlue
        }
        return Color.BlackCat.shadowLevel5
    }

    private func triggerHapticFeedback() {
        HapticManager.shared.lightImpact()
    }
}

// MARK: - Preview
struct AddListView_Previews: PreviewProvider {
    static var previews: some View {
        AddListView()
            .preferredColorScheme(.dark)
    }
}
