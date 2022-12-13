import Foundation

public final class ApiClient {
    public static let shared: ApiClient = ApiClient()
    public let basePath: String = "https://toi.kuronekoyamato.co.jp/cgi-bin"
    public var baseURL: URL {
        return URL(string: basePath)!
    }
}

extension Dictionary where Key == String, Value == Int {
    init?<Request>(_ request: Request) where Request: RequestType & URLQueryEncodable {
        guard let json = ((try? JSONEncoder().encode(request))
            .flatMap {try? JSONSerialization.jsonObject(with: $0, options: []) as? [String: Int]}) else { return nil }
        self = json
    }

    func equalEncode() -> String {
        return map { key, value in
            return key + "=" + String(value)
        }
        .joined(separator: "&")
    }
}
