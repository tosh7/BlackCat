//
//  DomainTests.swift
//  DomainTests
//
//  Created by tosh on 2021/08/09.
//

import XCTest
@testable import Domain

class TnekoTests: XCTestCase {
    let apiClient = ApiClient.shared
    let item327754459830 = Tneko.DeliveryList(deliveryID: 327754459830, statusList: [
        .init(status: "荷物受付", date: "10/09", time: "17:36", shopName: "ＺＯＺＯつくば支店"),
        .init(status: "発送済み", date: "10/09", time: "17:36", shopName: "ＺＯＺＯつくば支店"),
        .init(status: "配達担当店保管中", date: "10/10", time: "02:24", shopName: "墨田ＥＣデリバリーセンター"),
        .init(status: "配達完了（宅配ボックス）", date: "10/10", time: "13:10", shopName: "墨田ＥＣデリバリーセンター")
    ])
    let item292125879511 = Tneko.DeliveryList(deliveryID: 292125879511, statusList: [
        .init(status: "荷物受付", date: "09/19", time: "20:45", shopName: "ＺＯＺＯつくば支店"),
        .init(status: "発送済み", date: "09/19", time: "20:45", shopName: "ＺＯＺＯつくば支店"),
        .init(status: "輸送中", date: "09/20", time: "02:35", shopName: "厚木ゲートウェイベース"),
        .init(status: "配達日・時間帯指定（保管中）", date: "09/20", time: "06:02", shopName: "茅ヶ崎赤羽根営業所（茅ヶ崎平和町）"),
        .init(status: "配達完了", date: "09/20", time: "16:10", shopName: "茅ヶ崎赤羽根営業所（茅ヶ崎平和町）")
    ])

    func test_Tneko_request_success_case() async {
        let result = await apiClient.tneko(.init(numbers: [327754459830, 292125879511]))
        XCTAssertEqual(Tneko(deliveryList: [item327754459830, item292125879511]), result.value)
    }

    func test_Tneko_request_single_success_case() async {
        let result = await apiClient.tneko(.init(numbers: [327754459830]))
        XCTAssertEqual(Tneko(deliveryList: [item327754459830]), result.value)
    }

    func test_Tneko_request_failure_case() async {
        let invalidId = 122
        let result = await apiClient.tneko(.init(numbers: [invalidId]))
        XCTAssertEqual(result.value, Tneko(deliveryList: [.init(deliveryID: invalidId, statusList: [])]))
    }

    func test_Tneko_request_empty_case() async {
        let result = await apiClient.tneko(.init(numbers: []))
        XCTAssertEqual(result.value, Tneko(deliveryList: []))
    }

    // MARK: - Debug Test for 508382115290

    func test_Debug_508382115290_TnekoRequest_creation() {
        // Step 1: TnekoRequestが正しく作成されるか
        let trackingNumber = 508382115290
        let request = TnekoRequest(numbers: [trackingNumber])
        let idList = request.idList()

        print("=== DEBUG: TnekoRequest ===")
        print("Input trackingNumber: \(trackingNumber)")
        print("idList(): \(idList)")
        XCTAssertEqual(idList, [trackingNumber], "TnekoRequest should contain the tracking number")
    }

    func test_Debug_508382115290_URLRequest_construction() {
        // Step 2: URLRequestが正しく構築されるか
        let trackingNumber = 508382115290
        let request = TnekoRequest(numbers: [trackingNumber])

        print("=== DEBUG: URLRequest Construction ===")

        // JSONエンコードテスト
        if let data = try? JSONEncoder().encode(request) {
            let jsonString = String(data: data, encoding: .utf8) ?? "nil"
            print("JSONEncoder result: \(jsonString)")

            // JSONSerializationテスト
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                print("JSONSerialization type: \(type(of: jsonObject))")
                if let dict = jsonObject as? [String: Any] {
                    print("Dict contents:")
                    for (key, value) in dict {
                        print("  \(key): \(value) (type: \(type(of: value)))")
                    }
                }
            }
        } else {
            print("JSONEncoder failed!")
        }

        // URLRequest構築テスト
        let baseURL = URL(string: "https://toi.kuronekoyamato.co.jp/cgi-bin")!
        if let urlRequest = URLRequest(request, baseURL: baseURL) {
            print("URLRequest created successfully")
            print("URL: \(urlRequest.url?.absoluteString ?? "nil")")
            print("Method: \(urlRequest.httpMethod ?? "nil")")
            if let body = urlRequest.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                print("Body: \(bodyString)")
            }
            XCTAssertNotNil(urlRequest.httpBody, "HTTP body should not be nil")
        } else {
            print("URLRequest construction FAILED!")
            XCTFail("URLRequest should be created successfully for tracking number \(trackingNumber)")
        }
    }

    func test_Debug_508382115290_API_response() async {
        // Step 3 & 4: APIレスポンスとHTMLパース
        let trackingNumber = 508382115290

        print("=== DEBUG: API Response ===")
        print("Calling API with trackingNumber: \(trackingNumber)")

        let result = await apiClient.tneko(.init(numbers: [trackingNumber]))

        switch result {
        case .success(let tneko):
            print("API call SUCCESS")
            print("deliveryList count: \(tneko.deliveryList.count)")
            for delivery in tneko.deliveryList {
                print("  deliveryID: \(delivery.deliveryID)")
                print("  statusList count: \(delivery.statusList.count)")
                for status in delivery.statusList {
                    print("    - \(status.status) | \(status.date) \(status.time ?? "") | \(status.shopName)")
                }
            }
            if tneko.deliveryList.first?.statusList.isEmpty == true {
                print("WARNING: statusList is empty - HTML parsing may have failed")
            }
        case .failure(let error):
            print("API call FAILED: \(error)")
            print("Error description: \(error.errorDescription ?? "none")")
        }
    }

    func test_Debug_508382115290_fetchDeliveryInfo() async {
        // AddListViewModelが使用するfetchDeliveryInfoPublisherをテスト
        let trackingNumber = "508382115290"

        print("=== DEBUG: fetchDeliveryInfo (as used by AddListViewModel) ===")
        print("trackingNumber (String): \(trackingNumber)")

        let result = await apiClient.fetchDeliveryInfo(
            trackingNumber: trackingNumber,
            carrier: .yamato,
            useCache: false
        )

        switch result {
        case .success(let info):
            print("fetchDeliveryInfo SUCCESS")
            print("  trackingNumber: \(info.trackingNumber)")
            print("  carrier: \(info.carrier)")
            print("  statusList count: \(info.statusList.count)")
            for status in info.statusList {
                print("    - \(status.status) | \(status.date) \(status.time ?? "") | \(status.location)")
            }
            XCTAssertFalse(info.statusList.isEmpty, "statusList should not be empty")
        case .failure(let error):
            print("fetchDeliveryInfo FAILED: \(error)")
            print("Error description: \(error.errorDescription ?? "none")")
            XCTFail("fetchDeliveryInfo should succeed for \(trackingNumber)")
        }
    }

    func test_Debug_HTMLParsing() async {
        // HTMLパースのデバッグテスト
        print("=== DEBUG: HTML Parsing ===")

        // 実際のAPIからHTMLを取得
        let trackingNumber = 508382115290
        let request = TnekoRequest(numbers: [trackingNumber])
        let baseURL = URL(string: "https://toi.kuronekoyamato.co.jp/cgi-bin")!

        guard let urlRequest = URLRequest(request, baseURL: baseURL) else {
            print("URLRequest creation failed")
            XCTFail("URLRequest should be created")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            print("Received data size: \(data.count) bytes")

            // NSAttributedStringでHTMLをパース
            guard let attributedString = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
            ) else {
                print("NSAttributedString parsing failed")
                XCTFail("HTML parsing should succeed")
                return
            }

            let plainText = attributedString.string
            print("Plain text length: \(plainText.count) characters")

            // 改行で分割
            let lines = plainText.components(separatedBy: "\n")
            print("Number of lines: \(lines.count)")

            // 「お届け予定日時：」を含む行を探す
            var foundIndex = -1
            for (index, line) in lines.enumerated() {
                if line.contains("お届け予定日時：") {
                    foundIndex = index
                    print("Found 'お届け予定日時：' at line \(index)")
                    print("Line content: '\(line)'")

                    // 前後の行も表示
                    if index > 0 {
                        print("Previous line [\(index-1)]: '\(lines[index-1])'")
                    }
                    if index + 1 < lines.count {
                        print("Next line [\(index+1)]: '\(lines[index+1])'")
                    }
                    if index + 2 < lines.count {
                        print("Line [\(index+2)]: '\(lines[index+2])'")
                    }
                    if index + 3 < lines.count {
                        print("Line [\(index+3)]: '\(lines[index+3])'")
                    }
                    if index + 4 < lines.count {
                        print("Line [\(index+4)]: '\(lines[index+4])'")
                    }
                    break
                }
            }

            if foundIndex == -1 {
                print("'お届け予定日時：' NOT FOUND in parsed text!")
                // テキストの一部を出力
                let preview = String(plainText.prefix(2000))
                print("First 2000 chars of parsed text:")
                print(preview)
            }

            // Tnekoパースを試す
            let tneko = Tneko(idList: [trackingNumber], response: plainText)
            print("\n=== Tneko Parse Result ===")
            print("deliveryList count: \(tneko.deliveryList.count)")
            for delivery in tneko.deliveryList {
                print("deliveryID: \(delivery.deliveryID)")
                print("statusList count: \(delivery.statusList.count)")
                for status in delivery.statusList {
                    print("  - \(status.status) | \(status.date) \(status.time ?? "") | \(status.shopName)")
                }
            }

        } catch {
            print("Network error: \(error)")
            XCTFail("Network request should succeed")
        }
    }

}
