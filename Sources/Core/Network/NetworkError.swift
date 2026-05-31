import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingFailed(Error)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .invalidResponse: return "无效的服务器响应"
        case .httpError(let code, _): return "服务器错误 (HTTP \(code))"
        case .decodingFailed(let error): return "数据解析失败: \(error.localizedDescription)"
        case .cancelled: return "请求已取消"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .httpError(let code, _): return code >= 500 || code == 429
        case .invalidResponse: return true
        default: return false
        }
    }
}
