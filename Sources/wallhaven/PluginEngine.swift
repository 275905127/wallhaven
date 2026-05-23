import Foundation

class PluginEngine {
    // 动态构建 URL
    static func buildSearchURL(config: SourceConfig, keyword: String, res: String) -> URL? {
        var components = URLComponents(string: config.apiBaseURL)
        components?.queryItems = [
            URLQueryItem(name: config.queryParam, value: keyword),
            URLQueryItem(name: config.resolutionParam, value: res)
        ]
        return components?.url
    }
    
    // 解析 JSON 配置文件
    static func loadConfig(from data: Data) -> SourceConfig? {
        return try? JSONDecoder().decode(SourceConfig.self, from: data)
    }
}