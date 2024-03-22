import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var ark: Ark?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions)
    {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        window = UIWindow(windowScene: windowScene)
        guard let window = window else {
            return
        }

        window.rootViewController = RootViewController()
        window.makeKeyAndVisible()
//        let arkBlueprint = defineArkBlueprint()
        let tankGameManager = TankGameManager(frameWidth: 820, frameHeight: 1_180)
        loadArkBlueprintToScene(tankGameManager.blueprint, window: window)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
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

extension SceneDelegate {
    func defineArkBlueprint() -> ArkBlueprint {
        // Define game with blueprint here.
        let arkBlueprint = ArkBlueprint(frameWidth: 820, frameHeight: 1_180)
            .setup { ecsContext, eventContext in
                ecsContext.createEntity(with: [
                    JoystickCanvasComponent(radius: 50)
                        .shouldRerender { _, _ in false }
                        .center(x: 300, y: 300)
                        .onPanChange { angle, mag in print("change", angle, mag) }
                        .onPanStart { angle, mag in print("start", angle, mag) }
                        .onPanEnd { angle, mag in print("end", angle, mag) }
                ])
                ecsContext.createEntity(with: [
                    ButtonCanvasComponent(width: 50, height: 50)
                        .shouldRerender { _, _ in false }
                        .center(x: 500, y: 500)
                        .onTap {
                            print("emiting event")
                            var demoEvent: any ArkEvent = DemoArkEvent()
                            eventContext.emit(&demoEvent)
                            print("done emit event")
                        }
                ])
                ecsContext.createEntity(with: [
                    BitmapImageCanvasComponent(imageResourcePath: "tank_1",
                                               width: 256, height: 100)
                        .shouldRerender { _, _ in false }
                        .center(CGPoint(x: 410, y: 590))
                        .scaleToFill()
                ])
            }
            .rule(on: DemoArkEvent.self, then: Forever { _, _, _ in
                print("running rule")
            })
        return arkBlueprint
    }

    func loadArkBlueprintToScene(_ blueprint: ArkBlueprint, window: UIWindow) {
        guard let rootView = window.rootViewController as? AbstractParentView else {
            return
        }
        ark = Ark(rootView: rootView)
        ark?.start(blueprint: blueprint)
    }
}
