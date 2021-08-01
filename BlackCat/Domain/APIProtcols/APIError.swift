import Foundation

enum APIError: Error {
    case invalideURL
    case decodeErrror(String)
    case requestError(Error?)
}
