//
//  SceneDelegate.swift
//  Real time tracker
//
//  Created by khawar on 5/9/21.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        LocationSocketManager.sharedInstance.establishConnection()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        LocationSocketManager.sharedInstance.closeConnection()
    }


}

