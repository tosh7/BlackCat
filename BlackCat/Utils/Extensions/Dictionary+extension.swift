import Foundation

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
