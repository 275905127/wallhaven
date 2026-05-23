import SwiftUI

@main
struct WallhavenApp: App {
    var body: some Scene {
        WindowGroup {
            VStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("Wallhaven 引擎已启动")
                    .font(.title)
                    .padding()
                Text("准备加载图源配置...")
                    .foregroundColor(.gray)
            }
        }
    }
}