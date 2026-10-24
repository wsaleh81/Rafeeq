import SwiftUI
import UserNotifications

/// The app is portrait only, except the Mushaf reader, which also turns to landscape (two pages side by side).
enum OrientationLock {
    static var mask: UIInterfaceOrientationMask = .portrait

    static func set(_ m: UIInterfaceOrientationMask) {
        mask = m
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
        scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: m)) { _ in }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        OrientationLock.mask
    }
}

@main
struct QiblaCompassApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
