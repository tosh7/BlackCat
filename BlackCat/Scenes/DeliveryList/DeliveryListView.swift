import SwiftUI

struct DeliveryListView: View {

    @ObservedObject var viewModel = DeliveryListViewModel()
    private let columns: [GridItem] = Array(repeating: .init(.fixed(50)), count: 2)

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                LazyVGrid(columns: columns,
                          alignment: .center,
                          spacing: 8) {
                    if let tneko = viewModel.tneko {
                        ForEach((0..<tneko.deriveryList.count), id: \.self) { num in
                            ZStack {
                                LuggageItemGrid(deliveryStatus: tneko.deriveryList[num].statusList.last!)
                            }
                        }
                    }
                }
            }
            .navigationTitle("配達状況一覧")
        }
    }
}

struct DeliveryListView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryListView()
    }
}
