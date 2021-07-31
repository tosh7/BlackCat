import Foundation

extension String {
    var isValidStatusCode: Bool {
        return self == "荷物受付" || self == "発送済み" || self == "輸送中" || self == "配達完了"
    }
}
