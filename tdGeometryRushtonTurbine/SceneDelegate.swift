//
//  SceneDelegate.swift
//  tdGeometryRushtonTurbine
//
//  Created by  Ivan Ushakov on 24.01.2020.
//  Copyright © 2020 Lunar Key. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import tdLBGeometryRushtonTurbineLib
import tdLBGeometry

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var engineActionSink: AnyCancellable?
    private var pickerContext: PickerContext?
    
    public var RTTurbine: RushtonTurbineMidPointCPP?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        let turbine = RushtonTurbineReference(gridX: 300)
        
        // Create the SwiftUI view that provides the window contents.
        let engine = Engine(state: RushtonTurbineRenderState(
                turbine: turbine,
                canvasWidth: 50,
                canvasHeight: 50,
                kernelAutoRotation: true,
                kernelRotationDir: "clockwise",
                transPanXY: 0,
                transPanYZ: 0,
                transPanXZ: 0,
                transRotateAngle: 0,
                transEnableXY: false,
                transEnableYZ: false,
                transEnableXZ: false,
                transEnableImpeller: false,
                transEnableRotate: false
            )
        )
        
        
        //Make POINTCLOUD with SWIFT
//        var RTTurbine = RushtonTurbineMidPoint(turbine: turbine)
//        RTTurbine.generateFixedGeometry()
//        RTTurbine.generateRotatingGeometry(atθ: 0)
//        RTTurbine.generateRotatingNonUpdatingGeometry()
        
        
        //Make POINTCLOUD with CPP
        let gridX = 300
        let turbineCPP = RushtonTurbineCPP(gridX: gridX)
        let ext = ExtentsCPP(x0: 0, x1: gridX, y0: 0, y1: gridX, z0: 0, z1: gridX)
        
        
        let RTTurbine = RushtonTurbineMidPointCPP(rushtonTurbine: turbineCPP, extents: ext)
        self.RTTurbine = RTTurbine

        RTTurbine.generateFixedGeometry()
        RTTurbine.generateRotatingGeometry(atTheta: 0)
        RTTurbine.generateRotatingNonUpdatingGeometry()

        let fixed = RTTurbine.returnFixedGeometry()
        let rotating = RTTurbine.returnRotatingGeometry()
        let rotatingNonUpdating = RTTurbine.returnRotatingNonUpdatingGeometry()


        NSLog("PointCloud returned \(rotating.count) points")


        let pc = PointCloud(geomFixed: fixed, geomRotating: rotating, geomRotatingNonUpdating: rotatingNonUpdating)
        
        let pointCloudEngine = PointCloudEngine(pointCloud: pc)
        
        engineActionSink = engine.actionSubject.sink { [weak self] action in
            switch action {
            case .pick(let type, let callback):
                let context = PickerContext(callback: callback)
                self?.pickerContext = context

                let controller = UIDocumentPickerViewController(documentTypes: type, in: .open)
                controller.delegate = context
                self?.window?.rootViewController?.present(controller, animated: true, completion: nil)
            }
        }
        
        
        
        let contentView = ContentView(engine: engine, pointCloudEngine: pointCloudEngine, turbine: turbine, rtTurbine: RTTurbine)

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func updateScene(engine: Engine, turbine: RushtonTurbine, rtTurbine: RushtonTurbineMidPointCPP) {
    
        if
            let window = self.window {

            let fixed = rtTurbine.returnFixedGeometry()
            let rotating = rtTurbine.returnRotatingGeometry()
            let rotatingNonUpdating = rtTurbine.returnRotatingNonUpdatingGeometry()

            print("PointCloud returned \(rotating.count) rotating points")

            let pc = PointCloud(geomFixed: fixed, geomRotating: rotating, geomRotatingNonUpdating: rotatingNonUpdating)

            let pointCloudEngine = PointCloudEngine(pointCloud: pc)

            let contentView = ContentView(engine: engine, pointCloudEngine: pointCloudEngine, turbine: turbine, rtTurbine: rtTurbine)

            // Use a UIHostingController as window root view controller.
            if let rootViewController = window.rootViewController as? UIHostingController<ContentView> {
                rootViewController.rootView = contentView
            }
            
        }
        
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

private class PickerContext: NSObject {

    private let callback: (URL) -> Void

    init(callback: @escaping (URL) -> Void) {
        self.callback = callback
        super.init()
    }
}

extension PickerContext: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            callback(url)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // TODO
    }
}
