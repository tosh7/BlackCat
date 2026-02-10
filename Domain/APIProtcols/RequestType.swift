import Foundation

public protocol RequestType {
    static var path: String { get }
    static var method: HTTPMethod { get }
}

public extension URLRequest {
    init?<Request>(_ request: Request, baseURL: URL) where Request: RequestType & URLQueryEncodable {
        guard let queryItems = [String: String](request) else { return nil }
        let url = URL(string: "\(baseURL)/\(type(of: request).path)")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!

        switch type(of: request).method {
        case .post:
            let queryData = queryItems.equalEncode().data(using: .utf8)
            self.init(url: url)
            self.httpBody = queryData
            self.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        case .get:
            if !queryItems.isEmpty {
                components.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
            }
            guard let urlWithQuery = components.url else { return nil }
            self.init(url: urlWithQuery)
        }
        self.httpMethod = type(of: request).method.rawValue
    }
}

public protocol URLQueryEncodable: Encodable {}
