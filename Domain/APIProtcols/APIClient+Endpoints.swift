import UIKit

public extension ApiClient {
    // It can't use send method, because this is not codable model.
    func tneko(_ request: TnekoRequest, completion: @escaping (Result<Tneko, APIError>) -> Void) {
        guard let urlRequest: URLRequest = URLRequest(request, baseURL: baseURL) else { return }
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data else {
                completion(.failure(.unknownError("An unknown error has occured.")))
                return
            }

            if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
//                print(attributedString.string)
                let tneko = Tneko(
                    idList: request.idList(),
                    response: attributedString.string
                )
                completion(.success(tneko))
            } else {
                completion(.failure(.decodeErrror("This is not HTML")))
            }
        }
        task.resume()
    }
}

// MARK - Async & Await
public extension ApiClient {
    func tneko(_ request: TnekoRequest) async -> Result<Tneko, APIError> {
        guard let urlRequest: URLRequest = URLRequest(request, baseURL: baseURL) else { return .failure(.invalideURL) }
        do {
            let result = try await URLSession.shared.data(for: urlRequest)
            let data = result.0
            if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
//                print(attributedString.string)
                let tneko = Tneko(
                    idList: request.idList(),
                    response: attributedString.string
                )
                return .success(tneko)
            } else {
                return .failure(.decodeErrror("This is not HTML"))
            }
        } catch let error {
            return .failure(.unknownError(error.localizedDescription))
        }
    }
}
