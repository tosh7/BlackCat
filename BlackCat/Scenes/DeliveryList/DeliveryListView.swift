import SwiftUI

struct DeliveryListView: View {

    @StateObject var viewModel = DeliveryListViewModel()
    private static let spacing: CGFloat = 16
    private let columns: [GridItem] = [.init(spacing: Self.spacing), .init(spacing: Self.spacing)]
    @State private var showingModal = false

    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().barTintColor = .black
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)

                ScrollView(.vertical) {
                    if viewModel.isLoading {
                        VStack {
                            Spacer(minLength: 200)
                            ProgressView()
                        }
                    } else {
                        ZStack {
                            LazyVGrid(columns: columns,
                                      spacing: Self.spacing) {
                                ForEach(viewModel.output.deliveryList) { deliveryStatus in
                                    if deliveryStatus.statusList.count != 0 {
                                        NavigationLink(destination: StateDetailView(deliveryDetail: deliveryStatus)) {
                                            LuggageItemGrid(deliveryItem: deliveryStatus)
                                                .frame(width: 150, height: 180, alignment: .center)
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }

                            if viewModel.output.deliveryList.count == 0 {
                                Text("アイテムが追加されていません。\n左上のボタンから追加してください。")
                            }
                        }
                    }
                }
                .navigationTitle("配達状況一覧")
                .refreshable {
                    viewModel.input.pullToRefresh()
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        self.showingModal.toggle()
                    }) {
                        Image(systemName: "plus")
                    }.sheet(isPresented: $showingModal, onDismiss: {
                        self.viewModel.input.onAppear()
                    }, content: {
                        AddListView()
                    })
                }
            }
            .onAppear {
                self.viewModel.input.onAppear()
            }
            .preferredColorScheme(.dark)
            .accentColor(.white)
        }
    }
}


struct DeliveryListView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryListView()
    }
}
