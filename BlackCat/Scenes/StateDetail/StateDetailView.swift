import SwiftUI

struct StateDetailView: View {
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            Text("Hogehoge")
                .foregroundColor(.white)
        }
    }
}

struct StateDetailView_Previews: PreviewProvider {
    static var previews: some View {
        StateDetailView()
    }
}
