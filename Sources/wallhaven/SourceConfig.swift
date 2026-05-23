import Foundation

// 定义图源的结构，符合 Decodable 即可直接解析 JSON
struct SourceConfig: Codable {
    let name: String
    let apiBaseURL: String
    let queryParam: String
    let resolutionParam: String
    let jsonPath: String // 用于指示 API 返回数据中图片列表的位置
}