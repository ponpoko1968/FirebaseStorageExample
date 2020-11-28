//
//  AppDelegate.swift
//  FirebaseStorageExample
//
//  Created by 越智修司 on 2020/11/28.
//  Copyright © 2020 shuji ochi. All rights reserved.
//

import UIKit

import Firebase
import XCGLogger

let log = XCGLogger.default

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

