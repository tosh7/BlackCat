import Foundation
import Combine
import Domain

protocol AddListViewModelInputs {
    func textFieldDidChange(text: String)
    func carrierDidChange(carrier: DeliveryCarrier)
    func buttonDidTap()
}

protocol AddListViewModelOutputs {
    var selectedCarrier: DeliveryCarrier { get }
    var isButtonEnabled: Bool { get }
    var errorMessage: String { get }
    var cautionMessage: String { get }
    var isSuccessfullyAdded: Bool { get }
    var isLoading: Bool { get }
}

protocol AddListViewModelType {
    var input: AddListViewModelInputs { get }
    var output: AddListViewModelOutputs { get }
}

final class AddListViewModel: ObservableObject, AddListViewModelType, AddListViewModelInputs, AddListViewModelOutputs {

    init() {
        // ボタン有効化判定（桁数チェック）
        Publishers.CombineLatest($inputTextPublisher, $carrierPublisher)
            .map { text, carrier in
                let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: " ", with: "")

                // 数字のみの入力かチェック（日本郵便の国際郵便形式は除く）
                let isNumericOnly = cleanedText.allSatisfy { $0.isNumber }

                // 国際郵便形式のチェック（例: EA123456789JP）
                let isInternationalPost: Bool = {
                    guard cleanedText.count == 13 else { return false }
                    let pattern = "^[A-Z]{2}\\d{9}[A-Z]{2}$"
                    guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
                    return regex.firstMatch(in: cleanedText, range: NSRange(cleanedText.startIndex..., in: cleanedText)) != nil
                }()

                guard isNumericOnly || isInternationalPost else {
                    return false
                }

                // 桁数チェック（11〜13桁）
                return cleanedText.count >= 11 && cleanedText.count <= 13
            }
            .assign(to: \.isButtonEnabled, on: self)
            .store(in: &cancellables)

        $inputTextPublisher
            .compactMap { text in
                let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !cleanedText.isEmpty else { return "" }

                // 数字以外の文字チェック（国際郵便形式を除く）
                let isNumericOnly = cleanedText.allSatisfy { $0.isNumber }
                let hasLetters = cleanedText.contains(where: { $0.isLetter })

                if hasLetters {
                    // 国際郵便形式かチェック
                    let pattern = "^[A-Z]{2}\\d{9}[A-Z]{2}$"
                    if let regex = try? NSRegularExpression(pattern: pattern),
                       regex.firstMatch(in: cleanedText, range: NSRange(cleanedText.startIndex..., in: cleanedText)) != nil {
                        return ""
                    }
                    return "数字以外の文字が含まれています"
                }

                if !isNumericOnly {
                    return "数字以外の文字が含まれています"
                }

                // 桁数チェック
                if cleanedText.count < 11 {
                    return "伝票番号は11〜13桁です"
                } else if cleanedText.count > 13 {
                    return "伝票番号は11〜13桁です"
                }

                return ""
            }
            .assign(to: \.cautionMessage, on: self)
            .store(in: &cancellables)

        $buttonTappedPublisher
            .dropFirst() // 初期値の発行を無視
            .withLatestFrom(Publishers.CombineLatest($inputTextPublisher, $carrierPublisher)) { $1 }
            .handleEvents(receiveOutput: { _ in
                self.isLoading = true
            })
            .flatMap { (trackingNumber, carrier) -> AnyPublisher<UnifiedDeliveryInfo?, Never> in
                let cleanedNumber = trackingNumber
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: " ", with: "")
                return apiClient.fetchDeliveryInfoPublisher(
                    trackingNumber: cleanedNumber,
                    carrier: carrier.carrierType,
                    useCache: false
                )
                .subscribe(on: DispatchQueue.global())
                .receive(on: DispatchQueue.main)
                .map { Optional($0) }
                .catch { _ in Just(nil) }
                .eraseToAnyPublisher()
            }
            .sink(receiveValue: { deliveryInfo in
                self.isLoading = false
                guard let deliveryInfo = deliveryInfo else {
                    self.errorMessage = "登録に失敗しました"
                    self.showingAlert = true
                    return
                }
                let hasStatus = !deliveryInfo.statusList.isEmpty
                self.errorMessage = hasStatus ? "登録に成功しました" : "登録に失敗しました"
                self.showingAlert = true
                if hasStatus {
                    if let trackingInt = Int(deliveryInfo.trackingNumber) {
                        LocalDeliveryItems.shared.add(trackingInt)
                    }
                }
            })
            .store(in: &cancellables)
    }

    private var cancellables: Set<AnyCancellable> = []

    // MARK: Inputs
    @Published private var inputTextPublisher: String = ""
    func textFieldDidChange(text: String) {
        inputTextPublisher = text
    }

    @Published private var carrierPublisher: DeliveryCarrier = .yamato

    func carrierDidChange(carrier: DeliveryCarrier) {
        carrierPublisher = carrier
        selectedCarrier = carrier
    }

    @Published private var buttonTappedPublisher: Void = ()
    func buttonDidTap() {
        buttonTappedPublisher = ()
    }

    // MARK: Outputs
    @Published var showingAlert: Bool = false
    @Published private(set) var selectedCarrier: DeliveryCarrier = .yamato
    @Published private(set) var isButtonEnabled: Bool = false
    @Published private(set) var errorMessage: String = ""
    @Published private(set) var cautionMessage: String = ""
    @Published private(set) var isSuccessfullyAdded: Bool = false
    @Published private(set) var isLoading: Bool = false

    var input: AddListViewModelInputs { return self }
    var output: AddListViewModelOutputs { return self }
}
