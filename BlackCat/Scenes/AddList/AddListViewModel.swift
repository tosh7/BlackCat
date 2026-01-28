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
    var carrierDetectionResult: CarrierDetectionResult { get }
    var autoDetectionMessage: String { get }
    var isCarrierAutoDetected: Bool { get }
}

protocol AddListViewModelType {
    var input: AddListViewModelInputs { get }
    var output: AddListViewModelOutputs { get }
}

final class AddListViewModel: ObservableObject, AddListViewModelType, AddListViewModelInputs, AddListViewModelOutputs {

    init() {
        // 伝票番号の自動判別
        $inputTextPublisher
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .map { text -> CarrierDetectionResult in
                let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !cleanedText.isEmpty else {
                    return .insufficientInput
                }
                return DeliveryCarrier.detect(from: cleanedText)
            }
            .sink { [weak self] result in
                guard let self = self else { return }
                self.carrierDetectionResult = result

                switch result {
                case .detected(let carrier):
                    // 自動判別成功: 配送業者を自動選択
                    if !self.isCarrierManuallySelected {
                        self.selectedCarrier = carrier
                        self.carrierPublisher = carrier
                        self.isCarrierAutoDetected = true
                        self.autoDetectionMessage = result.feedbackMessage ?? ""
                    }

                case .multipleCandidates:
                    // 複数候補: メッセージのみ表示（手動選択を促す）
                    self.isCarrierAutoDetected = false
                    self.autoDetectionMessage = result.feedbackMessage ?? ""

                case .unknown:
                    // 判別不可
                    self.isCarrierAutoDetected = false
                    self.autoDetectionMessage = result.feedbackMessage ?? ""

                case .insufficientInput:
                    // 入力不足: メッセージクリア
                    self.isCarrierAutoDetected = false
                    self.autoDetectionMessage = ""
                }
            }
            .store(in: &cancellables)

        // ボタン有効化判定（配送業者に応じた桁数チェック）
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

                // 配送業者のパターンにマッチするか確認
                return carrier.matches(trackingNumber: cleanedText)
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
            .withLatestFrom($inputTextPublisher) { $1 }
            .compactMap { Int($0) }
            .flatMap { itemNumber in
                return apiClient.tneko(.init(numbers: [itemNumber]))
                    .subscribe(on: DispatchQueue.global())
                    .receive(on: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { _ in
                self.errorMessage = "登録に失敗しました"
            }, receiveValue: { value in
                self.errorMessage = value.deliveryList[0].statusList.count != 0 ? "登録に成功しました" : "登録に失敗しました"
                self.showingAlert = true
                value.deliveryList.filter { $0.statusList.count != 0 }.forEach {
                    LocalDeliveryItems.shared.add($0.deliveryID)
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
    private var isCarrierManuallySelected: Bool = false

    func carrierDidChange(carrier: DeliveryCarrier) {
        carrierPublisher = carrier
        selectedCarrier = carrier
        isCarrierManuallySelected = true
        isCarrierAutoDetected = false
        autoDetectionMessage = ""
    }

    /// 自動判別をリセット（テキストクリア時など）
    func resetAutoDetection() {
        isCarrierManuallySelected = false
        isCarrierAutoDetected = false
        autoDetectionMessage = ""
        carrierDetectionResult = .insufficientInput
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
    @Published private(set) var carrierDetectionResult: CarrierDetectionResult = .insufficientInput
    @Published private(set) var autoDetectionMessage: String = ""
    @Published private(set) var isCarrierAutoDetected: Bool = false

    var input: AddListViewModelInputs { return self }
    var output: AddListViewModelOutputs { return self }
}
