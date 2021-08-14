import Foundation
import Domain

final class TnekoMock {
    static let tneko: Domain.Tneko = {
        let url = Bundle.main.url(forResource: "TnekoMock", withExtension: "json")
        let data = try! Data(contentsOf: url!)
        let jsonDecorder = try! JSONDecoder().decode(Domain.Tneko.self, from: data)
        return jsonDecorder
    }()
}
