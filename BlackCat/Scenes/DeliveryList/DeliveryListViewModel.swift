import UIKit
import Domain
import Combine
import WidgetKit
import UserNotifications
import WatchConnectivity

// MARK: - Filter & Sort Types

/// ステータスフィルター用の列挙型
enum StatusFilter: String, CaseIterable, Identifiable {
    case all = "すべて"
    case received = "荷物受付"
    case sended = "発送済み"
    case shipping = "輸送中"
    case delivering = "配達中"
    case delivered = "配達完了"

    var id: String { self.rawValue }

    var displayName: String { self.rawValue }
}

/// 配送業者フィルター用の列挙型
enum CarrierFilter: String, CaseIterable, Identifiable {
    case all = "すべて"
    case yamato = "ヤマト運輸"
    case sagawa = "佐川急便"

    var id: String { self.rawValue }

    var displayName: String { self.rawValue }

    var carrier: DeliveryCarrier? {
        switch self {
        case .all:
            return nil
        case .yamato:
            return .yamato
        case .sagawa:
            return .sagawa
        }
    }
}

/// ソート順の列挙型
enum SortOption: String, CaseIterable, Identifiable {
    case registeredDateDesc = "登録日（新しい順）"
    case registeredDateAsc = "登録日（古い順）"
    case status = "ステータス順"
    case carrier = "配送業者順"

    var id: String { self.rawValue }

    var displayName: String { self.rawValue }
}

protocol DeliveryListViewModelInputs {
    func onAppear()
    func pullToRefresh()
    func updateSearchText(_ text: String)
    func updateStatusFilter(_ filter: StatusFilter)
    func updateCarrierFilter(_ filter: CarrierFilter)
    func updateSortOption(_ option: SortOption)
    func clearFilters()
}

protocol DeliveryListViewModelOutputs {
    var deliveryList: [DeliveryItem] { get }
    var filteredDeliveryList: [DeliveryItem] { get }
    var searchText: String { get }
    var statusFilter: StatusFilter { get }
    var carrierFilter: CarrierFilter { get }
    var sortOption: SortOption { get }
    var isFilterActive: Bool { get }
}

protocol DeliveryListViewModelType {
    var input: DeliveryListViewModelInputs { get }
    var output: DeliveryListViewModelOutputs { get }
}

final class DeliveryListViewModel: ObservableObject, DeliveryListViewModelType, DeliveryListViewModelInputs, DeliveryListViewModelOutputs {
    private var goodsIdList: [Int] {
        return LocalDeliveryItems.shared.items
    }
    @Published var deliveryList: [DeliveryItem] = []
    @Published var isLoading: Bool = false
    private var shouldReload: Bool = false
    private var cancellables: Set<AnyCancellable> = []
    private var isInitialLoad: Bool = true

    // MARK: - Search, Filter & Sort Properties

    /// 検索テキスト
    @Published var searchText: String = ""

    /// ステータスフィルター
    @Published var statusFilter: StatusFilter = .all

    /// 配送業者フィルター
    @Published var carrierFilter: CarrierFilter = .all

    /// ソートオプション
    @Published var sortOption: SortOption = .registeredDateDesc

    /// フィルターがアクティブかどうか
    var isFilterActive: Bool {
        return !searchText.isEmpty || statusFilter != .all || carrierFilter != .all
    }

    /// フィルター・ソート適用後の配達リスト
    @Published var filteredDeliveryList: [DeliveryItem] = []

    /// 前回の配達状況を保持（状態変更検知用）
    private var previousStatusMap: [Int: String] = [:]

    /// 通知マネージャー
    private let notificationManager = NotificationManager.shared

    /// Watch Connectivityマネージャー
    private let watchConnectivityManager = WatchConnectivityManager.shared

    init() {
        // Watch Connectivityのデータプロバイダーを設定
        setupWatchConnectivity()
        $onAppearPublisher.sink { [weak self] _ in
            guard let self,
                  self.shouldReload else { return }
            self.loadItem()
            self.shouldReload = false
        }
        .store(in: &cancellables)

        // Notifications
        Publishers.Merge3(
            NotificationCenter.default.publisher(for: .addItem),
            NotificationCenter.default.publisher(for: .removeItem),
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification))
        .sink { [weak self] _ in
            self?.shouldReload = true
        }
        .store(in: &cancellables)

        $pullToRefreshPublisher.sink { [weak self] _ in
            guard let self else { return }
            self.loadItem()
        }
        .store(in: &cancellables)

        // 検索・フィルター・ソートの変更を監視してfilteredDeliveryListを更新
        Publishers.CombineLatest4($deliveryList, $searchText, $statusFilter, $carrierFilter)
            .combineLatest($sortOption)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] combined, sortOption in
                let (deliveryList, searchText, statusFilter, carrierFilter) = combined
                self?.applyFiltersAndSort(
                    deliveryList: deliveryList,
                    searchText: searchText,
                    statusFilter: statusFilter,
                    carrierFilter: carrierFilter,
                    sortOption: sortOption
                )
            }
            .store(in: &cancellables)
    }

    // MARK: - Search, Filter & Sort Methods

    func updateSearchText(_ text: String) {
        searchText = text
    }

    func updateStatusFilter(_ filter: StatusFilter) {
        statusFilter = filter
    }

    func updateCarrierFilter(_ filter: CarrierFilter) {
        carrierFilter = filter
    }

    func updateSortOption(_ option: SortOption) {
        sortOption = option
    }

    func clearFilters() {
        searchText = ""
        statusFilter = .all
        carrierFilter = .all
        sortOption = .registeredDateDesc
    }

    /// フィルターとソートを適用
    private func applyFiltersAndSort(
        deliveryList: [DeliveryItem],
        searchText: String,
        statusFilter: StatusFilter,
        carrierFilter: CarrierFilter,
        sortOption: SortOption
    ) {
        var result = deliveryList

        // 検索フィルター（伝票番号）
        if !searchText.isEmpty {
            result = result.filter { item in
                String(item.deliveryID).contains(searchText)
            }
        }

        // ステータスフィルター
        if statusFilter != .all {
            result = result.filter { item in
                guard let latestStatus = item.latestStatus else { return false }
                return latestStatus.status == statusFilter.rawValue ||
                       (statusFilter == .delivered && latestStatus.status == "配達完了（宅配ボックス）")
            }
        }

        // 配送業者フィルター
        if let carrier = carrierFilter.carrier {
            result = result.filter { $0.carrier == carrier }
        }

        // ソート
        result = sortDeliveryList(result, by: sortOption)

        filteredDeliveryList = result
    }

    /// 配達リストをソート
    private func sortDeliveryList(_ list: [DeliveryItem], by option: SortOption) -> [DeliveryItem] {
        switch option {
        case .registeredDateDesc:
            return list.sorted { $0.registeredDate > $1.registeredDate }
        case .registeredDateAsc:
            return list.sorted { $0.registeredDate < $1.registeredDate }
        case .status:
            return list.sorted { item1, item2 in
                let priority1 = statusPriority(item1.latestStatusType)
                let priority2 = statusPriority(item2.latestStatusType)
                return priority1 < priority2
            }
        case .carrier:
            return list.sorted { $0.carrier.rawValue < $1.carrier.rawValue }
        }
    }

    /// ステータスの優先度を取得（配達中が最優先）
    private func statusPriority(_ statusType: DeliveryStatusType?) -> Int {
        guard let statusType = statusType else { return 999 }
        switch statusType {
        case .delivering:
            return 0
        case .shipping:
            return 1
        case .sended:
            return 2
        case .received:
            return 3
        case .delivered:
            return 4
        }
    }

    @Published private var onAppearPublisher: Void?
    func onAppear() {
        onAppearPublisher = ()
    }

    @Published private var pullToRefreshPublisher: Void?
    func pullToRefresh() {
        pullToRefreshPublisher = ()
    }

    private func loadItem() {
        guard !LocalDeliveryItems.shared.storedItems.isEmpty else {
            deliveryList = []
            return
        }

        Task { @MainActor in
            await loadItemAsync()
        }
    }

    /// データ読み込みの非同期実装（完了を待機可能）
    /// Multi-carrier support for Yamato and Sagawa
    @MainActor
    private func loadItemAsync() async {
        let allStoredItems = LocalDeliveryItems.shared.storedItems
        guard !allStoredItems.isEmpty else {
            deliveryList = []
            return
        }

        isLoading = true

        // Group by carrier
        let yamatoNumbers = allStoredItems
            .filter { $0.carrier == .yamato }
            .compactMap { $0.trackingNumberInt }
        let sagawaNumbers = allStoredItems
            .filter { $0.carrier == .sagawa }
            .compactMap { $0.trackingNumber as String? }
            .filter { !$0.isEmpty }

        var allDeliveryItems: [DeliveryItem] = []

        // Fetch Yamato and Sagawa in parallel
        async let yamatoItems = fetchYamatoItems(numbers: yamatoNumbers)
        async let sagawaItems = fetchSagawaItems(trackingNumbers: sagawaNumbers)

        let yamatoResult = await yamatoItems
        let sagawaResult = await sagawaItems

        allDeliveryItems.append(contentsOf: yamatoResult)
        allDeliveryItems.append(contentsOf: sagawaResult)

        isLoading = false

        if isInitialLoad {
            LocalDeliveryItems.shared.removeDeplicates(deliveryItems: allDeliveryItems)
            isInitialLoad = false
        }

        // 配達状況の変更を検知して通知を送信
        checkAndNotifyStatusChanges(newItems: allDeliveryItems)

        self.deliveryList = allDeliveryItems

        // ウィジェットにデータを同期
        BlackCatApp.syncWidgetData(deliveryItems: allDeliveryItems)

        // Apple Watchにデータを同期
        BlackCatApp.syncWatchData(deliveryItems: allDeliveryItems)
    }

    // MARK: - Carrier-specific Fetch Methods

    /// Fetch Yamato delivery info in batch
    private func fetchYamatoItems(numbers: [Int]) async -> [DeliveryItem] {
        guard !numbers.isEmpty else { return [] }
        let result = await apiClient.tneko(.init(numbers: numbers))
        guard let tneko = result.value else { return [] }
        return TnekoClient(tneko: tneko).deliveryList
    }

    /// Fetch Sagawa delivery info in parallel (one API call per item via TaskGroup)
    private func fetchSagawaItems(trackingNumbers: [String]) async -> [DeliveryItem] {
        guard !trackingNumbers.isEmpty else { return [] }

        return await withTaskGroup(of: DeliveryItem?.self, returning: [DeliveryItem].self) { group in
            for trackingNumber in trackingNumbers {
                group.addTask { [apiClient] in
                    let result = await apiClient.sagawa(SagawaRequest(trackingNumber: trackingNumber))
                    guard let sagawa = result.value,
                          let trackingInfo = sagawa.trackingList.first else {
                        return nil
                    }
                    return DeliveryItem(trackingInfo: trackingInfo)
                }
            }

            var items: [DeliveryItem] = []
            for await item in group {
                if let item = item {
                    items.append(item)
                }
            }
            return items
        }
    }

    // MARK: - Watch Connectivity Setup

    /// Watch Connectivityのセットアップ
    private func setupWatchConnectivity() {
        // データプロバイダーを設定
        watchConnectivityManager.setDeliveryDataProvider { [weak self] in
            guard let self = self else { return [] }
            return self.deliveryList.map { item in
                WatchDeliveryData(from: item, carrier: item.carrier)
            }
        }

        // ステータス更新ハンドラーを設定
        watchConnectivityManager.setStatusRefreshHandler { [weak self] completion in
            guard let self = self else {
                completion(false)
                return
            }

            // データを再読み込みし、完了を待ってからcompletionを呼び出す
            Task { @MainActor in
                await self.loadItemAsync()
                completion(true)
            }
        }
    }

    // MARK: - Notification Methods

    /// 配達状況の変更を検知して通知を送信
    /// - Parameter newItems: 新しい配達アイテムリスト
    private func checkAndNotifyStatusChanges(newItems: [DeliveryItem]) {
        for item in newItems {
            guard let latestStatus = item.statusList.last else { continue }

            let deliveryID = item.deliveryID
            let currentStatus = latestStatus.status
            let shopName = latestStatus.shopName

            // 前回の状態と比較
            if let previousStatus = previousStatusMap[deliveryID] {
                // 状態が変更された場合
                if previousStatus != currentStatus {
                    // 配達完了の場合は配達完了通知
                    if isDeliveryCompleted(status: currentStatus) {
                        notificationManager.scheduleDeliveryCompletedNotification(
                            deliveryID: deliveryID,
                            shopName: shopName
                        )
                    } else {
                        // それ以外は状態更新通知
                        notificationManager.scheduleStatusUpdateNotification(
                            deliveryID: deliveryID,
                            status: currentStatus,
                            shopName: shopName
                        )
                    }
                }
            }

            // 現在の状態を保存
            previousStatusMap[deliveryID] = currentStatus
        }
    }

    /// 配達完了かどうかを判定
    /// - Parameter status: 配達状態文字列
    /// - Returns: 配達完了の場合true
    private func isDeliveryCompleted(status: String) -> Bool {
        let completedStatuses = ["配達完了", "配達完了（宅配ボックス）"]
        return completedStatuses.contains(status)
    }

    /// 配達予定時間の通知をスケジュール
    /// - Parameters:
    ///   - deliveryID: 配達ID
    ///   - shopName: 店舗名
    ///   - scheduledDate: 配達予定日時
    func scheduleDeliveryReminder(deliveryID: Int, shopName: String, scheduledDate: Date) {
        notificationManager.scheduleDeliveryReminderNotification(
            deliveryID: deliveryID,
            shopName: shopName,
            scheduledDate: scheduledDate
        )
    }

    /// 特定の配達の通知をキャンセル
    /// - Parameter deliveryID: 配達ID
    func cancelNotifications(for deliveryID: Int) {
        notificationManager.cancelNotifications(for: deliveryID)
    }

    var input: DeliveryListViewModelInputs { return self }
    var output: DeliveryListViewModelOutputs { return self }
}
