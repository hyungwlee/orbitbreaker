//
//  AppDelegate.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        

        window = UIWindow(frame: UIScreen.main.bounds)

        let gameViewController = GameViewController()
        window?.rootViewController = gameViewController
        

        window?.makeKeyAndVisible()
        
        return true
    }
}

