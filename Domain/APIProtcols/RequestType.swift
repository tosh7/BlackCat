import Foundation

public protocol RequestType {
    static var path: String { get }
    static var method: HTTPMethod { get }
}

public extension URLRequest {
    init?<Request>(_ request: Request, baseURL: URL) where Request: RequestType & URLQueryEncodable {
        guard let queryItems = [String: Int](request) else { return nil }
        let url = URL(string: "\(baseURL)/\(type(of: request).path)")!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)!

        switch type(of: request).method {
        case .post:
            let queryData = queryItems.equalEncode().data(using: .utf8)
            self.init(url: url)
            self.httpBody = queryData
        case .get:
            guard let urlWithQuery = components.url else { return nil }
            self.init(url: urlWithQuery)
        }
        self.httpMethod = type(of: request).method.rawValue
    }
}

public protocol URLQueryEncodable: Encodable {}
