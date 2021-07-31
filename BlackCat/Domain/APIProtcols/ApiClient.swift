import Foundation

enum RequestType: String {
    case POST
    case GET
}

struct ApiClident {
    static let basePath: String = "https://toi.kuronekoyamato.co.jp/cgi-bin/tneko"

    static func postRequest(completion: @escaping (Result<Tneko, APIError>) -> Void) {
        let method: RequestType = .POST
        guard let url = URL(string: self.basePath) else {
            completion(.failure(.invalideURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        let json: [String: Int] = [
            "number00": 1,
            "number01": 429636181995,
            "number02": 398629940844
        ]
        request.httpBody = json.equalEncode().data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let attributedString = try? NSAttributedString(data: data!, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                print(attributedString.string)
                let tneko = Tneko(idList: [429636181995, 398629940844], response: attributedString.string)
                completion(.success(tneko))
            } else {
                completion(.failure(.decodeErrror("This is not HTML")))
            }
        }
        task.resume()
    }
}
