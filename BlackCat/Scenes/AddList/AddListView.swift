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

                    // Register Button
                    registerButtonSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }

            // Loading overlay
            if viewModel.output.isLoading {
                loadingOverlay
            }

            // Success overlay
            if showSuccessAnimation {
                successOverlay
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
        .transition(.opacity)
        .animation(.gentleEaseOut, value: viewModel.output.isLoading)
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
            Label {
                Text("配送業者を選択")
                    .font(.headline)
                    .foregroundColor(.white)
            } icon: {
                Image(systemName: "building.2.fill")
                    .foregroundColor(Color.BlackCat.primaryBlue)
            }
            .accessibilityAddTraits(.isHeader)

            HStack(spacing: 12) {
                ForEach(DeliveryCarrier.allCases) { carrier in
                    CarrierCard(
                        carrier: carrier,
                        isSelected: viewModel.output.selectedCarrier == carrier,
                        onSelect: {
                            HapticManager.shared.carrierSelection()
                            withAnimation(.quickSpring) {
                                viewModel.input.carrierDidChange(carrier: carrier)
                            }
                        }
                    )
                }
            }
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
                }
            )
            .offset(x: shakeOffset)

            // Input guidance
            HStack(spacing: 8) {
                if viewModel.output.cautionMessage.isEmpty {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(Color.BlackCat.shadowLevel3)
                    Text("11〜13桁の伝票番号を入力してください")
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

    // MARK: - Register Button Section
    private var registerButtonSection: some View {
        Button(action: {
            if viewModel.output.isButtonEnabled && !viewModel.output.isLoading {
                triggerHapticFeedback()
                viewModel.input.buttonDidTap()
            } else if !viewModel.output.isLoading {
                triggerErrorShake()
            }
        }) {
            HStack(spacing: 12) {
                if viewModel.output.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    if viewModel.output.isButtonEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                    }
                    Text("登録する")
                        .font(.body)
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(viewModel.output.isButtonEnabled && !viewModel.output.isLoading ? .black : Color.BlackCat.shadowLevel4)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if viewModel.output.isButtonEnabled && !viewModel.output.isLoading {
                        Color.BlackCat.successGradient
                    } else {
                        Color.BlackCat.shadowLevel6
                    }
                }
            )
            .cornerRadius(16)
            .shadow(
                color: viewModel.output.isButtonEnabled && !viewModel.output.isLoading ? Color.BlackCat.naturalGreen.opacity(0.4) : Color.clear,
                radius: 12,
                x: 0,
                y: 6
            )
            .scaleEffect(viewModel.output.isButtonEnabled && !viewModel.output.isLoading ? 1.0 : 0.98)
            .animation(.quickSpring, value: viewModel.output.isButtonEnabled)
            .animation(.quickSpring, value: viewModel.output.isLoading)
        }
        .disabled(!viewModel.output.isButtonEnabled || viewModel.output.isLoading)
        .accessibilityLabel("登録する")
        .accessibilityHint(viewModel.output.isLoading ? "読み込み中です" : (viewModel.output.isButtonEnabled ? "伝票番号を登録します" : "伝票番号を入力すると有効になります"))
        .accessibilityAddTraits(.isButton)
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
                                    ? carrier.brandColor.opacity(0.5)
                                    : Color.BlackCat.shadowLevel6,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? carrier.brandColor.opacity(0.2) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(carrier.displayName)、\(carrier.shortDescription)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(isSelected ? "選択中" : "タップして選択")
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
                .accessibilityHint("11から13桁の数字を入力してください")
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
