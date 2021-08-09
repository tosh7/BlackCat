import Foundation

public final class ApiClient {
    public static let shared: ApiClient = ApiClient()
    public let basePath: String = "https://toi.kuronekoyamato.co.jp/cgi-bin"
    public var baseURL: URL {
        return URL(string: basePath)!
    }

    private func callback(onQueue callbackQueue: DispatchQueue?, execute block: @escaping () -> Void) {
        if let queue = callbackQueue {
            queue.async(execute: block)
        } else {
            block()
        }
    }

    func send<Request, Response>(request: Request, callbackQueue: DispatchQueue? = .main, completion: @escaping (Result<Response, APIError>) -> Void) where Request: RequestType & URLQueryEncodable, Response: ResponseType {
        let urlRequest: URLRequest = URLRequest(request, baseURL: baseURL)

        func requestToURLSession(handleResponse: @escaping (() -> Void)) -> URLSessionTask {
            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                guard error != nil else {
                    completion(.failure(.requestError(error)))
                    return
                }

                guard let data = data else {
                    completion(.failure(.decodeErrror("no data")))
                    return
                }

                do {
                    let response = try JSONDecoder().decode(Response.self, from: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(.decodeErrror("unknown error")))
                }
            }
            task.resume()
            return task
        }
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
