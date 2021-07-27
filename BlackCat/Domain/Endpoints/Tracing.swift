import Foundation

struct Tracing: Codable {
    var itemType: String?
    var result: String
    var slipNo: String
    var status: String
    var statusList: [StatusResult]

    struct StatusResult: Codable {
        var date: String
        var placeCode: String
        var placeName: String
        var status: String
        var time: String
    }
}
