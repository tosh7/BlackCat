import SwiftUI

struct DeliveryListView: View {

    @StateObject var viewModel = DeliveryListViewModel()
    private static let spacing: CGFloat = 16
    private let columns: [GridItem] = [.init(spacing: Self.spacing), .init(spacing: Self.spacing)]
    @State private var showingModal = false
    @State private var appearAnimation = false
    @State private var showingFilterSheet = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().barTintColor = .black
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.BlackCat.backgroundPrimary
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // 検索バー
                    searchBar

                    // フィルター表示（アクティブな場合）
                    if viewModel.output.isFilterActive {
                        activeFiltersView
                    }

                    ScrollView(.vertical) {
                        if viewModel.isLoading {
                            LoadingView()
                                .accessibilityLabel("読み込み中")
                                .accessibilityHint("配達情報を取得しています")
                        } else if viewModel.output.deliveryList.isEmpty {
                            EmptyStateView(showingModal: $showingModal)
                        } else if viewModel.output.filteredDeliveryList.isEmpty {
                            noResultsView
                        } else {
                            deliveryGridView
                        }
                    }
                    .refreshable {
                        viewModel.input.pullToRefresh()
                        HapticManager.shared.refreshComplete()
                    }
                }
                .navigationTitle("配達状況一覧")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundColor(Color.BlackCat.shadowLevel2)
                        }
                        .accessibilityLabel("設定")
                        .accessibilityHint("設定画面を開きます")

                        filterButton
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        HapticManager.shared.buttonTap()
                        self.showingModal.toggle()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.BlackCat.accentPrimary)
                    }
                    .accessibilityLabel("荷物を追加")
                    .accessibilityHint("新しい伝票番号を登録する画面を開きます")
                    .sheet(isPresented: $showingModal, onDismiss: {
                        self.viewModel.input.onAppear()
                    }, content: {
                        AddListView()
                    })
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSortSheet(viewModel: viewModel)
            }
            .onAppear {
                self.viewModel.input.onAppear()
                if !reduceMotion {
                    withAnimation(.easeOut(duration: 0.5)) {
                        appearAnimation = true
                    }
                } else {
                    appearAnimation = true
                }
            }
            .preferredColorScheme(.dark)
            .accentColor(.white)
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.BlackCat.shadowLevel3)

                TextField("伝票番号で検索", text: Binding(
                    get: { viewModel.output.searchText },
                    set: { viewModel.input.updateSearchText($0) }
                ))
                .foregroundColor(.white)
                .keyboardType(.numberPad)
                .accessibilityLabel("伝票番号検索")
                .accessibilityHint("伝票番号を入力して荷物を検索します")

                if !viewModel.output.searchText.isEmpty {
                    Button(action: {
                        viewModel.input.updateSearchText("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.BlackCat.shadowLevel3)
                    }
                    .accessibilityLabel("検索をクリア")
                }
            }
            .padding(12)
            .background(Color.BlackCat.backgroundCard)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Filter Button
    private var filterButton: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            showingFilterSheet = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                if viewModel.output.isFilterActive {
                    Circle()
                        .fill(Color.BlackCat.accentPrimary)
                        .frame(width: 8, height: 8)
                }
            }
            .foregroundColor(viewModel.output.isFilterActive ? Color.BlackCat.accentPrimary : .white)
        }
        .accessibilityLabel("フィルター")
        .accessibilityHint("フィルターとソートの設定画面を開きます")
        .accessibilityValue(viewModel.output.isFilterActive ? "フィルター適用中" : "フィルターなし")
    }

    // MARK: - Active Filters View
    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if viewModel.output.statusFilter != .all {
                    FilterChip(
                        title: viewModel.output.statusFilter.displayName,
                        onRemove: { viewModel.input.updateStatusFilter(.all) }
                    )
                }

                if viewModel.output.carrierFilter != .all {
                    FilterChip(
                        title: viewModel.output.carrierFilter.displayName,
                        onRemove: { viewModel.input.updateCarrierFilter(.all) }
                    )
                }

                if viewModel.output.isFilterActive {
                    Button(action: {
                        viewModel.input.clearFilters()
                    }) {
                        Text("クリア")
                            .font(.caption)
                            .foregroundColor(Color.BlackCat.accentPrimary)
                    }
                    .accessibilityLabel("すべてのフィルターをクリア")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - No Results View
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)

            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(Color.BlackCat.shadowLevel3)
                .accessibilityHidden(true)

            Text("検索結果がありません")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("検索条件を変更してください")
                .font(.body)
                .foregroundColor(Color.BlackCat.shadowLevel3)

            Button(action: {
                viewModel.input.clearFilters()
            }) {
                Text("フィルターをクリア")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.BlackCat.accentPrimary)
                    .cornerRadius(20)
            }
            .accessibilityLabel("フィルターをクリア")
            .accessibilityHint("すべてのフィルターと検索条件をリセットします")

            Spacer()
        }
        .padding()
    }

    // MARK: - Delivery Grid View
    private var deliveryGridView: some View {
        LazyVGrid(columns: columns, spacing: Self.spacing) {
            ForEach(Array(viewModel.output.filteredDeliveryList.enumerated()), id: \.element.id) { index, deliveryStatus in
                if deliveryStatus.statusList.count != 0 {
                    NavigationLink(destination: StateDetailView(deliveryDetail: deliveryStatus)) {
                        LuggageItemGrid(deliveryItem: deliveryStatus)
                            .frame(width: 150, height: 180, alignment: .center)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("詳細を表示するにはダブルタップしてください")
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                    .animation(reduceMotion ? nil : .cardAppear.delay(Double(index) * 0.05), value: viewModel.output.filteredDeliveryList.count)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("配達中の荷物一覧")
        .accessibilityHint("\(viewModel.output.filteredDeliveryList.count)件の荷物があります")
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    @Binding var showingModal: Bool
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 60)

            // Animated package icon
            ZStack {
                // Background circles
                Circle()
                    .fill(Color.BlackCat.backgroundCard.opacity(0.5))
                    .frame(width: 200, height: 200)
                    .scaleEffect(isAnimating && !reduceMotion ? 1.1 : 1.0)

                Circle()
                    .fill(Color.BlackCat.backgroundSecondary.opacity(0.7))
                    .frame(width: 150, height: 150)
                    .scaleEffect(isAnimating && !reduceMotion ? 1.05 : 1.0)

                // Package icon
                VStack(spacing: 8) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(Color.BlackCat.shadowLevel3)
                        .rotationEffect(.degrees(isAnimating && !reduceMotion ? 5 : -5))

                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.BlackCat.accentPrimary)
                        .offset(y: isAnimating && !reduceMotion ? -5 : 0)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
            .accessibilityHidden(true)

            // Text content
            VStack(spacing: 16) {
                Text("荷物がありません")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .accessibilityAddTraits(.isHeader)

                Text("追跡したい荷物の伝票番号を\n追加してください")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.BlackCat.shadowLevel3)
                    .lineSpacing(4)
            }

            // Add button
            Button(action: {
                HapticManager.shared.buttonTap()
                showingModal = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("荷物を追加")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.BlackCat.accentPrimary,
                            Color.BlackCat.accentSecondary
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: Color.BlackCat.accentPrimary.opacity(0.4), radius: 10, x: 0, y: 5)
            }
            .accessibilityLabel("荷物を追加")
            .accessibilityHint("新しい伝票番号を登録する画面を開きます")
            .accessibilityAddTraits(.isButton)

            Spacer()
        }
        .padding()
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 40) {
            Spacer(minLength: 100)

            // Animated truck with package
            ZStack {
                // Road
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.BlackCat.shadowLevel5)
                    .frame(width: 200, height: 8)
                    .offset(y: 50)

                // Moving dots on road
                if !reduceMotion {
                    HStack(spacing: 20) {
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .fill(Color.BlackCat.shadowLevel4)
                                .frame(width: 6, height: 6)
                                .offset(x: isAnimating ? 100 : -100)
                                .animation(
                                    .linear(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                    .offset(y: 50)
                }

                // Truck icon
                VStack(spacing: 0) {
                    Image(systemName: "box.truck.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.BlackCat.primaryOrange)
                        .offset(y: isAnimating && !reduceMotion ? -3 : 3)
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: 0.3)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }

                // Loading ring
                Circle()
                    .stroke(Color.BlackCat.shadowLevel6, lineWidth: 4)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.BlackCat.primaryBlue,
                                Color.BlackCat.primaryOrange
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(reduceMotion ? 0 : rotationAngle))
            }
            .accessibilityHidden(true)

            // Loading text
            VStack(spacing: 12) {
                Text("読み込み中...")
                    .font(.headline)
                    .foregroundColor(.white)

                if !reduceMotion {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.BlackCat.shadowLevel3)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                }
            }

            Spacer()
        }
        .onAppear {
            isAnimating = true
            guard !reduceMotion else { return }
            withAnimation(
                .linear(duration: 1.0)
                .repeatForever(autoreverses: false)
            ) {
                rotationAngle = 360
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("読み込み中")
        .accessibilityValue("配達情報を取得しています")
    }
}


// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(Color.BlackCat.shadowLevel3)
            }
            .accessibilityLabel("\(title)フィルターを削除")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.BlackCat.backgroundCard)
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Filter Sort Sheet
struct FilterSortSheet: View {
    @ObservedObject var viewModel: DeliveryListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.BlackCat.backgroundPrimary
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // ステータスフィルター
                        filterSection(
                            title: "ステータス",
                            options: StatusFilter.allCases,
                            selected: viewModel.statusFilter,
                            onSelect: { viewModel.input.updateStatusFilter($0) }
                        )

                        Divider()
                            .background(Color.BlackCat.shadowLevel5)

                        // 配送業者フィルター
                        filterSection(
                            title: "配送業者",
                            options: CarrierFilter.allCases,
                            selected: viewModel.carrierFilter,
                            onSelect: { viewModel.input.updateCarrierFilter($0) }
                        )

                        Divider()
                            .background(Color.BlackCat.shadowLevel5)

                        // ソートオプション
                        sortSection
                    }
                    .padding()
                }
            }
            .navigationTitle("フィルター・ソート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("リセット") {
                        viewModel.input.clearFilters()
                    }
                    .foregroundColor(Color.BlackCat.accentPrimary)
                    .accessibilityLabel("フィルターをリセット")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color.BlackCat.accentPrimary)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Filter Section
    private func filterSection<T: Identifiable & Equatable>(
        title: String,
        options: [T],
        selected: T,
        onSelect: @escaping (T) -> Void
    ) -> some View where T: RawRepresentable, T.RawValue == String {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(options) { option in
                    Button(action: {
                        HapticManager.shared.selection()
                        onSelect(option)
                    }) {
                        Text(option.rawValue)
                            .font(.subheadline)
                            .fontWeight(selected == option ? .semibold : .regular)
                            .foregroundColor(selected == option ? .white : Color.BlackCat.shadowLevel3)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                selected == option ?
                                Color.BlackCat.accentPrimary :
                                Color.BlackCat.backgroundCard
                            )
                            .cornerRadius(12)
                    }
                    .accessibilityLabel(option.rawValue)
                    .accessibilityAddTraits(selected == option ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Sort Section
    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("並び替え")
                .font(.headline)
                .foregroundColor(.white)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 8) {
                ForEach(SortOption.allCases) { option in
                    Button(action: {
                        HapticManager.shared.selection()
                        viewModel.input.updateSortOption(option)
                    }) {
                        HStack {
                            Text(option.displayName)
                                .font(.subheadline)
                                .foregroundColor(.white)

                            Spacer()

                            if viewModel.sortOption == option {
                                Image(systemName: "checkmark")
                                    .font(.subheadline)
                                    .foregroundColor(Color.BlackCat.accentPrimary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.BlackCat.backgroundCard)
                        .cornerRadius(12)
                    }
                    .accessibilityLabel(option.displayName)
                    .accessibilityAddTraits(viewModel.sortOption == option ? .isSelected : [])
                }
            }
        }
    }
}

struct DeliveryListView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryListView()
    }
}
