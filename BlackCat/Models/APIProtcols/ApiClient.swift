import Foundation

enum RequestType: String {
    case POST
    case GET
}

struct ApiClident {
    static let basePath: String = "http://nanoappli.com/tracking/api/"

    static func postRequest() {
        let method: RequestType = .POST
        guard let url = URL(string: self.basePath) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let json: [String : Any] = [
            "number00": 1,
            "number01": "429636181995"
        ]
        request.httpBody = try! NSKeyedArchiver.archivedData(withRootObject: json, requiringSecureCoding: false)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            print(error)
        }
        task.resume()
    }

    static func tracking(itemNumber: String) {
        let endpoint = "tracking"
        let method: RequestType = .GET

        guard let requestURL = URL(string: "\(basePath)/\(endpoint)/api/\(itemNumber).json") else { return }
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            do {
                let object = try JSONSerialization.jsonObject(with: data, options: [])
                print(object)
            } catch let error {
                print(error)
            }
        }
        task.resume()
    }
}
