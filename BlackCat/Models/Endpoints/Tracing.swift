import Foundation

struct Tracing: Codable {
    var itemType: String?
    var result: Int
    var slipNo: String
    var status: String
    var statusResult: [StatusResult]?

    struct StatusResult: Codable {
        var date: String
        var placeCode: String
        var placeName: String
        var status: String
        var time: String
    }
}
