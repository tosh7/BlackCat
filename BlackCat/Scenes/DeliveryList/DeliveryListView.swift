import SwiftUI

struct DeliveryListView: View {

    @ObservedObject var viewModel = DeliveryListViewModel()
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
                }
                .navigationTitle("配達状況一覧")
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        self.showingModal.toggle()
                    }) {
                        Image(systemName: "plus")
                    }.sheet(isPresented: $showingModal, content: {
                        AddListView()
                    })
                }
            }
        }
        .preferredColorScheme(.dark)
        .accentColor(.white)
    }
}


struct DeliveryListView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryListView()
    }
}
