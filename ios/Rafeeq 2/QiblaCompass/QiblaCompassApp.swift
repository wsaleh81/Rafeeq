import SwiftUI
import UserNotifications

@main
struct QiblaCompassApp: App {
    @StateObject private var model = AppModel()
    init() {
        AppFont.registerAll()
        UNUserNotificationCenter.current().delegate = NotifDelegate.shared
    }
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model)
                .onOpenURL { url in
                    guard url.scheme == "rihal" else { return }
                    switch url.host {
                    case "mosques": model.tab = 3
                    case "prayer": model.tab = 0
                    default: break
                    }
                }
        }
    }
}
