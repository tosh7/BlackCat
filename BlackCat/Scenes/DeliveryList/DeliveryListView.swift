import SwiftUI

struct DeliveryListView: View {

    @ObservedObject var viewModel = DeliveryListViewModel()
    private let columns: [GridItem] = Array(repeating: .init(.fixed(50)), count: 2)

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
                              alignment: .center,
                              spacing: 8) {
                        ForEach(viewModel.deliveryList) { deliveryStatus in
                            LuggageItemGrid(deliveryStatus: deliveryStatus.statusList.last!)
                        }
                    }
                }
                .navigationTitle("配達状況一覧")
            }
        }
        .preferredColorScheme(.dark)
    }
}


struct DeliveryListView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryListView()
    }
}
