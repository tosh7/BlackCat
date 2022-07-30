import Foundation

extension Result {

    var isSuccess: Bool {
        switch self {
        case .success(_):
            return true
        case .failure(_):
            return false
        }
    }

    var value: Success? {
        switch self {
        case.success(let resource):
            return resource
        case .failure(_):
            return nil
        }
    }

    var error: Failure? {
        switch self {
        case .success(_):
            return nil
        case .failure(let error):
            return error
        }
    }
}
