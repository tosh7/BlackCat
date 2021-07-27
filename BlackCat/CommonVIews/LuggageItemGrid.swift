import SwiftUI

struct LuggageItemGrid: View {
    let state: String

    init(state: String) {
        self.state = state
    }

    var body: some View {
           Text(state)
    }
}

struct LuggageItemGrid_Previews: PreviewProvider {
    static var previews: some View {
        LuggageItemGrid(state: "配達中")
    }
}
