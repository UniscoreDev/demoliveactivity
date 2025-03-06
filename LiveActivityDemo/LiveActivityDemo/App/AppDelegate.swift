import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        application.registerForRemoteNotifications()

        ContentView.listenForTokenToStartActivityViaPush()
        ContentView.listenForTokenToUpdateActivityViaPush()
        UNUserNotificationCenter.current().delegate = self
        requestNotificationAuthorization()
        return true
    }
    func requestNotificationAuthorization() {
           UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
               if granted {
                   DispatchQueue.main.async {
                       UIApplication.shared.registerForRemoteNotifications()
                   }
               }
           }
       }
    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("======== DEVICE TOKEN: \(deviceToken.hexEncodedString())")
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.alert, .badge, .sound])
        }

        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            handleNotification(response.notification.request.content.userInfo)
            completionHandler()
        }

        func handleNotification(_ userInfo: [AnyHashable: Any]) {
            // Handle notification data
            if let message = userInfo["message"] as? String {
                print("======== nhận noti:", message)
            }
        }
}
