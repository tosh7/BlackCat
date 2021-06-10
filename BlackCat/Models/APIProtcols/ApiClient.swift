import Foundation

enum RequestType: String {
    case POST
    case GET
}

struct ApiClident {
    static let basePath: String = "https://toi.kuronekoyamato.co.jp/cgi-bin/tneko"
    static let method: RequestType = .POST

    static func postRequest() {
        guard let url = URL(string: self.basePath) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        let json: [String : Any] = [
            "number00": 1,
            "number01": "429636181995"
        ]
        request.httpBody = try! NSKeyedArchiver.archivedData(withRootObject: json, requiringSecureCoding: false)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            print(response!)
        }
        task.resume()
    }
}
