import SwiftUI
import UserNotifications

/// The app turns with the phone (portrait and landscape), except the Mushaf reader, which stays upright.
enum OrientationLock {
    static var mask: UIInterfaceOrientationMask = .allButUpsideDown
    /// Posted when the allowed orientations change, since the screen may turn without the phone moving.
    static let changed = Notification.Name("OrientationLockChanged")

    static func set(_ m: UIInterfaceOrientationMask) {
        mask = m
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
        // tell every screen in the stack, so an open full-screen view (the Mushaf) turns at once
        var vc = scene.keyWindow?.rootViewController
        while let v = vc { v.setNeedsUpdateOfSupportedInterfaceOrientations(); vc = v.presentedViewController }
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: m)) { _ in }
        NotificationCenter.default.post(name: changed, object: nil)
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
