import SwiftUI

struct DeliveryListView: View {

    var columns: [GridItem] = Array(repeating: .init(.fixed(50)), count: 5)
    // This is a mock data.
    var tneko: Tneko = Tneko(deriveryList: [
        Tneko.DeliveryList(deliveryID: 123456, statusList: [
            DeliveryStatus(status: "輸送中",
                           date: "6/13",
                           time: "12:41",
                           shopName: "羽田クロノゲートベース",
                           shopID: "032990")
        ])
    ])

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                LazyVGrid(columns: columns,
                          alignment: .center,
                          spacing: 8) {
                    ForEach((1...tneko.deriveryList.count), id: \.self) { num in
                        ZStack {
                            LuggageItemGrid(deliveryStatus: tneko.deriveryList[0].statusList.last!)
                        }
                    }
                }
            }
            .navigationTitle("配達状況一覧")
        }
        .onAppear(perform: {
            apiClient.tneko(.init(number01: 429636181995, number02: 398629940844)) { result in
                switch result {
                case let .success(tneko):
//                    self.tneko = tneko
                    print(tneko)
                    break
                case .failure: break
                }
            }
        })
    }
}

struct DeliveryListView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryListView()
    }
}
