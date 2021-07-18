import SwiftUI

struct DeliveryListView: View {

    var columns: [GridItem] = Array(repeating: .init(.fixed(50)), count: 5)

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns,
                      alignment: .center,
                      spacing: 8) {
                ForEach((1...1000), id: \.self) { num in
                    ZStack {
                        Rectangle().foregroundColor(.accentColor)
                        Text("\(num)").foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear(perform: {
            ApiClident.tracking(itemNumber: "429636181995")
        })
    }
}

struct DeliveryListView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryListView()
    }
}
