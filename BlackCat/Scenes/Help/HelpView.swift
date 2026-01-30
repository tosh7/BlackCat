import SwiftUI

// MARK: - Help Item Model

struct HelpItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let icon: String
    let iconColor: Color
}

// MARK: - Help Section Model

struct HelpSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let iconColor: Color
    let items: [HelpItem]
}

// MARK: - Help View

struct HelpView: View {
    @State private var searchText = ""
    @State private var expandedSections: Set<UUID> = []
    @State private var expandedItems: Set<UUID> = []
    @Environment(\.openURL) private var openURL

    private let sections: [HelpSection] = [
        // Usage Section
        HelpSection(
            title: "使い方",
            icon: "book.fill",
            iconColor: Color.BlackCat.primaryBlue,
            items: [
                HelpItem(
                    question: "荷物の追加方法",
                    answer: """
                    1. ホーム画面右下の「+」ボタンをタップします
                    2. 配送業者を選択します（ヤマト運輸、佐川急便、日本郵便）
                    3. 追跡番号（12桁）を入力します
                    4. 任意でメモを追加できます
                    5. 「追加」ボタンをタップして完了です

                    追跡番号は、配送業者から届いた伝票や通知メールに記載されています。
                    """,
                    icon: "plus.circle.fill",
                    iconColor: Color.BlackCat.naturalGreen
                ),
                HelpItem(
                    question: "配達状況の確認方法",
                    answer: """
                    ホーム画面に登録済みの荷物がカード形式で表示されます。

                    各カードには以下の情報が表示されます：
                    - 配送業者のアイコン
                    - 追跡番号
                    - 現在のステータス（発送済み、配達中、配達完了など）
                    - 最終更新日時

                    カードをタップすると、詳細な配送履歴を確認できます。

                    画面を下にスワイプすると、最新の配達状況に更新されます。
                    """,
                    icon: "magnifyingglass",
                    iconColor: Color.BlackCat.primaryBlue
                ),
                HelpItem(
                    question: "荷物の削除方法",
                    answer: """
                    荷物を削除するには、以下の2つの方法があります：

                    【方法1】スワイプで削除
                    ホーム画面で荷物カードを左にスワイプし、「削除」ボタンをタップします。

                    【方法2】詳細画面から削除
                    荷物カードをタップして詳細画面を開き、右上のメニューから「削除」を選択します。

                    ※削除した荷物は復元できませんのでご注意ください。
                    """,
                    icon: "trash.fill",
                    iconColor: Color.BlackCat.naturalRed
                )
            ]
        ),

        // FAQ Section
        HelpSection(
            title: "よくある質問",
            icon: "questionmark.circle.fill",
            iconColor: Color.BlackCat.primaryOrange,
            items: [
                HelpItem(
                    question: "対応している配送業者は？",
                    answer: """
                    現在、以下の配送業者に対応しています：

                    - ヤマト運輸（クロネコヤマト）
                    - 佐川急便（飛脚宅配便）
                    - 日本郵便（ゆうパック）

                    今後、対応業者を順次追加予定です。
                    ご要望がありましたら、お問い合わせよりご連絡ください。
                    """,
                    icon: "truck.box.fill",
                    iconColor: Color.BlackCat.primaryOrange
                ),
                HelpItem(
                    question: "追跡番号が見つからない場合は？",
                    answer: """
                    追跡番号が見つからない場合、以下の原因が考えられます：

                    1. 追跡番号の入力ミス
                       - 数字の間違いがないか確認してください
                       - 12桁全て入力されているか確認してください

                    2. 配送業者の選択ミス
                       - 伝票に記載の配送業者と一致しているか確認してください

                    3. まだ発送されていない
                       - 発送前の荷物は追跡できません
                       - 発送通知が届いてから登録してください

                    4. 追跡期限切れ
                       - 配達完了から一定期間経過すると追跡できなくなります
                    """,
                    icon: "exclamationmark.triangle.fill",
                    iconColor: Color.BlackCat.naturalYellow
                ),
                HelpItem(
                    question: "通知が届かない場合は？",
                    answer: """
                    通知が届かない場合、以下を確認してください：

                    1. アプリの通知設定を確認
                       - 設定アプリ > BlackCat > 通知
                       - 「通知を許可」がオンになっているか確認

                    2. アプリ内の通知設定を確認
                       - BlackCatアプリ > 設定 > 通知設定
                       - 必要な通知がオンになっているか確認

                    3. おやすみモードを確認
                       - おやすみモードが有効だと通知が届きません

                    4. 集中モードを確認
                       - 集中モードでBlackCatが許可されているか確認
                    """,
                    icon: "bell.slash.fill",
                    iconColor: Color.BlackCat.purePurple
                ),
                HelpItem(
                    question: "バックグラウンド更新が動作しない場合は？",
                    answer: """
                    バックグラウンド更新が動作しない場合：

                    1. システム設定を確認
                       - 設定アプリ > 一般 > Appのバックグラウンド更新
                       - BlackCatがオンになっているか確認

                    2. アプリ内設定を確認
                       - BlackCatアプリ > 設定 > バックグラウンド更新
                       - 「バックグラウンド更新」がオンになっているか確認

                    3. 低電力モードを確認
                       - 低電力モードでは更新間隔が自動的に延長されます

                    4. バッテリー最適化の影響
                       - iOSがバッテリー節約のため更新を制限する場合があります
                       - これはiOSの仕様であり、アプリで制御できません

                    ※バックグラウンド更新はiOSにより最適化されるため、
                    　設定した間隔通りに動作しない場合があります。
                    """,
                    icon: "arrow.clockwise.circle.fill",
                    iconColor: Color.BlackCat.primaryBlue
                )
            ]
        ),

        // Troubleshooting Section
        HelpSection(
            title: "トラブルシューティング",
            icon: "wrench.and.screwdriver.fill",
            iconColor: Color.BlackCat.naturalGreen,
            items: [
                HelpItem(
                    question: "データの更新方法",
                    answer: """
                    配達状況を手動で更新するには：

                    【ホーム画面で更新】
                    ホーム画面を下にスワイプ（プルダウン）すると、
                    全ての荷物の配達状況が更新されます。

                    【個別の荷物を更新】
                    荷物カードをタップして詳細画面を開き、
                    画面を下にスワイプすると、その荷物のみ更新されます。

                    更新中は画面上部にインジケーターが表示されます。
                    """,
                    icon: "arrow.clockwise",
                    iconColor: Color.BlackCat.primaryBlue
                ),
                HelpItem(
                    question: "アプリの再起動方法",
                    answer: """
                    アプリが正常に動作しない場合、再起動をお試しください：

                    1. アプリを完全に終了
                       - ホームバーを上にスワイプしてAppスイッチャーを開く
                       - BlackCatアプリを上にスワイプして終了

                    2. 数秒待ってからアプリを再度起動

                    それでも問題が解決しない場合：
                    - iPhoneを再起動してみてください
                    - アプリを削除して再インストールしてみてください
                      （設定 > データ管理 からデータのバックアップを推奨）
                    """,
                    icon: "power",
                    iconColor: Color.BlackCat.naturalRed
                )
            ]
        )
    ]

    // Contact items
    private let contactItems: [(title: String, subtitle: String, icon: String, color: Color, action: ContactAction)] = [
        (
            title: "メールでお問い合わせ",
            subtitle: "support@blackcat-app.example.com",
            icon: "envelope.fill",
            color: Color.BlackCat.primaryBlue,
            action: .email
        ),
        (
            title: "App Storeでレビュー",
            subtitle: "ご意見・ご感想をお聞かせください",
            icon: "star.fill",
            color: Color.BlackCat.naturalYellow,
            action: .appStoreReview
        )
    ]

    private enum ContactAction {
        case email
        case appStoreReview
    }

    // Filtered sections based on search
    private var filteredSections: [HelpSection] {
        guard !searchText.isEmpty else { return sections }

        return sections.compactMap { section in
            let filteredItems = section.items.filter { item in
                item.question.localizedCaseInsensitiveContains(searchText) ||
                item.answer.localizedCaseInsensitiveContains(searchText)
            }

            if filteredItems.isEmpty {
                return nil
            }

            return HelpSection(
                title: section.title,
                icon: section.icon,
                iconColor: section.iconColor,
                items: filteredItems
            )
        }
    }

    var body: some View {
        ZStack {
            Color.BlackCat.backgroundPrimary
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 24) {
                    // Search Bar
                    searchBar

                    if filteredSections.isEmpty && !searchText.isEmpty {
                        noResultsView
                    } else {
                        // Help Sections
                        ForEach(filteredSections) { section in
                            helpSectionView(section)
                        }

                        // Contact Section (only show when not searching)
                        if searchText.isEmpty {
                            contactSection
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("ヘルプ・FAQ")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .onAppear {
            // Expand all sections by default
            expandedSections = Set(sections.map { $0.id })
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.BlackCat.shadowLevel3)
                .font(.body)

            TextField("FAQを検索", text: $searchText)
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !searchText.isEmpty {
                Button(action: {
                    withAnimation(.quickSpring) {
                        searchText = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.BlackCat.shadowLevel3)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.BlackCat.backgroundCard)
        .cornerRadius(12)
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Color.BlackCat.shadowLevel4)

            Text("検索結果がありません")
                .font(.headline)
                .foregroundColor(.white)

            Text("別のキーワードで検索してみてください")
                .font(.subheadline)
                .foregroundColor(Color.BlackCat.shadowLevel3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Help Section View

    private func helpSectionView(_ section: HelpSection) -> some View {
        VStack(spacing: 0) {
            // Section Header
            Button(action: {
                withAnimation(.smoothSpring) {
                    if expandedSections.contains(section.id) {
                        expandedSections.remove(section.id)
                    } else {
                        expandedSections.insert(section.id)
                    }
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: section.icon)
                        .font(.title3)
                        .foregroundColor(section.iconColor)
                        .frame(width: 32)

                    Text(section.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: expandedSections.contains(section.id) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color.BlackCat.shadowLevel3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.BlackCat.backgroundCard)
            }
            .buttonStyle(PlainButtonStyle())

            // Section Items
            if expandedSections.contains(section.id) {
                VStack(spacing: 1) {
                    ForEach(section.items) { item in
                        helpItemView(item)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    // MARK: - Help Item View

    private func helpItemView(_ item: HelpItem) -> some View {
        VStack(spacing: 0) {
            // Question (always visible)
            Button(action: {
                withAnimation(.smoothSpring) {
                    if expandedItems.contains(item.id) {
                        expandedItems.remove(item.id)
                    } else {
                        expandedItems.insert(item.id)
                    }
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.body)
                        .foregroundColor(item.iconColor)
                        .frame(width: 24)

                    Text(item.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: expandedItems.contains(item.id) ? "minus.circle.fill" : "plus.circle.fill")
                        .font(.body)
                        .foregroundColor(expandedItems.contains(item.id) ? Color.BlackCat.accentPrimary : Color.BlackCat.shadowLevel4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.BlackCat.backgroundSecondary)
            }
            .buttonStyle(PlainButtonStyle())

            // Answer (expandable)
            if expandedItems.contains(item.id) {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .background(Color.BlackCat.shadowLevel6)

                    Text(item.answer)
                        .font(.subheadline)
                        .foregroundColor(Color.BlackCat.shadowLevel2)
                        .lineSpacing(6)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.BlackCat.backgroundSecondary.opacity(0.7))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Contact Section

    private var contactSection: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: "envelope.badge.fill")
                    .font(.title3)
                    .foregroundColor(Color.BlackCat.accentPrimary)
                    .frame(width: 32)

                Text("お問い合わせ")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.BlackCat.backgroundCard)

            // Contact Items
            VStack(spacing: 1) {
                ForEach(contactItems.indices, id: \.self) { index in
                    let item = contactItems[index]
                    Button(action: {
                        handleContactAction(item.action)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.body)
                                .foregroundColor(item.color)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)

                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundColor(Color.BlackCat.shadowLevel3)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(Color.BlackCat.shadowLevel4)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.BlackCat.backgroundSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    // MARK: - Actions

    private func handleContactAction(_ action: ContactAction) {
        switch action {
        case .email:
            if let url = URL(string: "mailto:support@blackcat-app.example.com?subject=BlackCat%20App%20サポート") {
                openURL(url)
            }
        case .appStoreReview:
            // Replace with actual App Store ID
            if let url = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
                openURL(url)
            }
        }
    }
}

// MARK: - Preview

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HelpView()
        }
    }
}
