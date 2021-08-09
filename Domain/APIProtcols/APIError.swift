import Foundation

public enum APIError: Error {
    case invalideURL
    case decodeErrror(String)
    case requestError(Error?)
}
