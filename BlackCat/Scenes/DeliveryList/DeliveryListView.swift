import SwiftUI

struct DeliveryListView: View {

    @ObservedObject var viewModel = DeliveryListViewModel()
    private static let spacing: CGFloat = 16
    private let columns: [GridItem] = [.init(spacing: Self.spacing), .init(spacing: Self.spacing)]

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
                            NavigationLink(destination: StateDetailView(deliveryDetail: deliveryStatus)) {
                                LuggageItemGrid(deliveryItem: deliveryStatus)
                                    .frame(width: 150, height: 180, alignment: .center)
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
                .navigationTitle("配達状況一覧")
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
