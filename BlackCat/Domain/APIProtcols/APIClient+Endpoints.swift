import Foundation

extension ApiClient {
//    // It can't use send method, because this is not codable model.
    func tneko(_ request: TnekoRequest, completion: @escaping (Result<Tneko, APIError>) -> Void) {
        guard let urlRequest: URLRequest = URLRequest(request, baseURL: baseURL) else { return }
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let attributedString = try? NSAttributedString(data: data!, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                print(attributedString.string)
                let tneko = Tneko(
                    idList: [429636181995, 398629940844],
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
