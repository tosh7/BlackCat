import Foundation

extension Dictionary where Key == String, Value == Int {
    func equalEncode() -> String {
        return map { key, value in
            return key + "=" + String(value)
        }
        .joined(separator: "&")
    }
}
