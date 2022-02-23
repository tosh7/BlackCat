import Foundation
import Combine

public extension ApiClient {
    func tneko(_ request: TnekoRequest) -> Future<Tneko, APIError> {
        return Future() { promise in
            guard let urlRequest: URLRequest = URLRequest(request, baseURL: self.baseURL) else { return }
            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                guard let data = data else {
                    promise(Result.failure(.unknownError("An unknown error has occured.")))
                    return
                }

                if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                    let tneko = Tneko(
                        idList: request.idList(),
                        response: attributedString.string
                    )
                    promise(Result.success(tneko))
                } else {
                    promise(Result.failure(.decodeErrror("This is not HTML")))
                }
            }
            task.resume()
        }
    }
}
