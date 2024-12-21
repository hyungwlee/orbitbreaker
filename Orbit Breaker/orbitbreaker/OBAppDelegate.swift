//
//  AppDelegate.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

import UIKit
import SwiftUI

@main
class OBAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Create the SwiftUI view that provides the app's main interface
        let contentView = OBContentView()

        // Use a UIHostingController as the window's root view controller
        let hostingController = UIHostingController(rootView: contentView)

        // Set up the window
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = hostingController
        window?.makeKeyAndVisible()

        return true
    }
}

