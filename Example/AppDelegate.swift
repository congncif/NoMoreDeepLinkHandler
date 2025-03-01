//
//  AppDelegate.swift
//  Example
//
//  Created by NGUYEN CHI CONG on 18/7/24.
//

import NoMoreDeepLinkHandler
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        DeepLinkHandler.configure()
            .withNotFoundHandler { url in
                print("The deep link \(url) is not handled")
            }
            .set(blacklistHosts: ["localhost"])
            .set(whitelistHosts: ["deep-link-handler.no-more"])
            .withForbiddenHandler { url in
                print("The deep link \(url) is not forbidden")
            }
            .initialize()
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        DeepLinkHandler.shared.handle(deepLink: url)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
