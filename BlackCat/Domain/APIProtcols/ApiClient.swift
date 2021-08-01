import Foundation

let apiClient = ApiClient.shared

final class ApiClient {
    static let shared: ApiClient = ApiClient()
    let basePath: String = "https://toi.kuronekoyamato.co.jp/cgi-bin"
    var baseURL: URL {
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
