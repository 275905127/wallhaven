import Foundation

struct WallhavenSourceConfigurationStore {
    private let defaults: UserDefaults
    private let categoriesKey = "wallhaven.source.categories"
    private let puritiesKey = "wallhaven.source.purities"
    private let orderKey = "wallhaven.source.order"
    private let topRangeKey = "wallhaven.source.topRange"
    private let apiKeyKey = "wallhaven.source.apiKey"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> WallhavenSourceConfiguration {
        var configuration = WallhavenSourceConfiguration()
        if let categories = loadSet(forKey: categoriesKey, values: WallhavenCategory.allCases) {
            configuration.categories = categories
        }
        if let purities = loadSet(forKey: puritiesKey, values: WallhavenPurity.allCases) {
            configuration.purities = purities
        }
        if let orderValue = defaults.string(forKey: orderKey),
           let order = WallhavenOrder(rawValue: orderValue) {
            configuration.order = order
        }
        if let topRangeValue = defaults.string(forKey: topRangeKey),
           let topRange = WallhavenTopRange(rawValue: topRangeValue) {
            configuration.topRange = topRange
        }
        configuration.setAPIKey(defaults.string(forKey: apiKeyKey) ?? "")
        return configuration
    }

    func save(_ configuration: WallhavenSourceConfiguration) {
        defaults.set(configuration.categories.map(\.rawValue), forKey: categoriesKey)
        defaults.set(configuration.purities.map(\.rawValue), forKey: puritiesKey)
        defaults.set(configuration.order.rawValue, forKey: orderKey)
        defaults.set(configuration.topRange.rawValue, forKey: topRangeKey)
        defaults.set(configuration.trimmedAPIKey, forKey: apiKeyKey)
    }

    private func loadSet<Value: RawRepresentable & Hashable>(forKey key: String, values: [Value]) -> Set<Value>? where Value.RawValue == String {
        guard let storedValues = defaults.stringArray(forKey: key) else { return nil }
        let allowedValues = Set(values)
        let decodedValues = Set(storedValues.compactMap(Value.init(rawValue:))).intersection(allowedValues)
        return decodedValues.isEmpty ? nil : decodedValues
    }
}
