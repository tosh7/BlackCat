import Foundation

enum RequestType: String {
    case POST
    case GET
}

struct ApiClident {
    static let basePath: String = "https://toi.kuronekoyamato.co.jp/cgi-bin/tneko"

    static func postRequest() {
        let method: RequestType = .POST
        guard let url = URL(string: self.basePath) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("text/html", forHTTPHeaderField: "Content-Type")
        let json: [String: Any] = [
            "number00": 1,
            "number01": "429636181995"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            print(error)
            if let attributedString = try? NSAttributedString(data: data!, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                print(attributedString.string)
            }
        }
        task.resume()
    }

    static func tracking(itemNumber: String, completion: @escaping (Result<Tracing, Error>) -> Void) {
        let endpoint = "tracking"
        let method: RequestType = .GET

        guard let requestURL = URL(string: "\(basePath)/\(endpoint)/api/\(itemNumber).json") else { return }
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            do {
                let json = try JSONDecoder().decode(Tracing.self, from: data)
                completion(.success(json))
            } catch let error {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
