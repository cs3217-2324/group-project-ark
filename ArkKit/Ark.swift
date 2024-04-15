import Foundation

/**
 * `Ark` describes the game as is **loaded**.
 *
 * It loads the various contexts from the  `ArkBlueprint` provided and the `GameLoop`.
 * `Ark` requires a `rootView: AbstractRootView` to render the game.
 *
 * `Ark.start()` starts a loaded version of the game by injecting the game context dependencies.
 *
 * User of the `Ark` instance should ensure that the `arkInstance` is **binded** (strongly referenced), otherwise events
 * relying on the `arkInstance` will not emit.
 */
class Ark<View, ExternalResources: ArkExternalResources>: ArkProtocol {
    let rootView: any AbstractRootView<View>
    var arkState: ArkState
    var gameLoop: GameLoop?

    let blueprint: ArkBlueprint<ExternalResources>
    let audioContext: any AudioContext<ExternalResources.AudioEnum>
    var displayContext: DisplayContext

    var actionContext: ArkActionContext<ExternalResources> {
        ArkActionContext(ecs: arkState.arkECS,
                         events: arkState.eventManager,
                         display: displayContext,
                         audio: audioContext)
    }

    var multiplayerManager: ArkMultiplayerManager?

    var canvasRenderableBuilder: (any RenderableBuilder<View>)?

    init(rootView: any AbstractRootView<View>,
         blueprint: ArkBlueprint<ExternalResources>,
         canvasRenderableBuilder: (any RenderableBuilder<View>)? = nil) {
        self.rootView = rootView
        self.blueprint = blueprint

        self.audioContext = ArkAudioContext()
        self.canvasRenderableBuilder = canvasRenderableBuilder
        self.displayContext = ArkDisplayContext(
            canvasSize: CGSize(
                width: blueprint.frameWidth,
                height: blueprint.frameHeight
            ),
            screenSize: rootView.size
        )

        // inject state management dependencies
        guard let networkPlayableInfo = blueprint.networkPlayableInfo else {
            let eventManager = ArkEventManager()
            let ecsManager = ArkECS()
            self.arkState = ArkState(eventManager: eventManager, arkECS: ecsManager)
            return
        }
        let eventManager = ArkMultiplayerEventManager()
        let ecsManager = ArkECS()
        self.arkState = ArkState(eventManager: eventManager, arkECS: ecsManager)
        self.multiplayerManager = ArkMultiplayerManager(
            serviceName: networkPlayableInfo.roomName,
            role: networkPlayableInfo.role ?? .host, // default to host so if unspecified, plays as local
            ecs: ecsManager
        )
        multiplayerManager?.multiplayerEventManager = eventManager
        eventManager.delegate = multiplayerManager
    }

    func start() {
        // TODO: refactor to use strategy design pattern here
        // use SetUpStrategy.execute() to set up based on status
        setUpIfNotParticipant()
        setUpIfParticipant()
        setUpIfHost()

        alignCamera()

        guard let gameLoop = self.gameLoop else {
            return
        }

        let gameCoordinator = ArkGameCoordinator<View>(rootView: rootView,
                                                       arkState: arkState,
                                                       displayContext: displayContext,
                                                       gameLoop: gameLoop,
                                                       canvasRenderer: canvasRenderableBuilder)
        gameCoordinator.start()
    }

    private func setUpIfNotParticipant() {
        guard multiplayerManager?.role != .participant else {
            return
        }
        setupDefaultEntities()
        setupDefaultListeners()
        setupDefaultSystems(blueprint)
        setup(blueprint.setupFunctions)
        setup(blueprint.rules)
        setup(blueprint.soundMapping)
    }

    private func setUpIfParticipant() {
        guard let multiplayerManager = multiplayerManager,
              multiplayerManager.role == .participant else {
            return
        }
        setupDefaultListeners()
        setupMultiplayerGameLoop()
        setup(blueprint.soundMapping)
    }

    private func setUpIfHost() {
        guard let multiplayerManager = multiplayerManager,
              multiplayerManager.role == .host else {
            return
        }
        multiplayerManager.ecs = arkState.arkECS
        self.arkState
            .arkECS
            .addSystem(ArkMultiplayerSystem(multiplayerManager: multiplayerManager))
    }

    private func setupDefaultListeners() {
        arkState.eventManager.subscribe(to: ScreenResizeEvent.self) { [weak self] event in
            guard let resizeEvent = event as? ScreenResizeEvent,
                  let self = self else {
                return
            }
            self.displayContext.updateScreenSize(resizeEvent.eventData.newSize)
        }

        arkState.eventManager.subscribe(to: PauseGameLoopEvent.self) { [weak self] event in
            guard let pauseGameLoopEvent = event as? PauseGameLoopEvent,
                  let self = self else {
                return
            }
            self.gameLoop?.pauseLoop()
        }

        arkState.eventManager.subscribe(to: ResumeGameLoopEvent.self) { [weak self] event in
            guard let resumeGameLoopEvent = event as? ResumeGameLoopEvent,
                  let self = self else {
                return
            }
            self.gameLoop?.resumeLoop()

        }

        arkState.eventManager.subscribe(to: TerminateGameLoopEvent.self) { [weak self] event in
            guard let terminateGameEvent = event as? TerminateGameLoopEvent,
                  let self = self else {
                return
            }
            self.gameLoop?.shutDown()
        }
    }

    private func setup(_ rules: [any Rule]) {
        // filter for event-based rules only
        let eventRules: [any Rule<RuleEventType>] = rules.filter { rule in
            rule.trigger is RuleEventType
        }.map { rule in
            guard let eventRule = rule as? any Rule<RuleEventType> else {
                fatalError("[Ark.setup(rules)] map failed: Unexpected type in array")
            }
            return eventRule
        }
        // sort the rules by priority before adding to eventContext
        let sortedRules = eventRules.sorted(by: { x, y in
            if x.trigger == y.trigger {
                return x.action.priority < y.action.priority
            }
            return true
        })
        // subscribe all rules to the eventManager
        for rule in sortedRules {
            arkState.eventManager.subscribe(to: rule.trigger.eventType) { event in
                let areConditionsSatisfied = rule.conditions
                    .allSatisfy { $0(self.actionContext.ecs) }
                if areConditionsSatisfied {
                    event.executeAction(rule.action, context: self.actionContext)
                }
            }
        }

        // filter for time-based rules only
        let timeRules: [any Rule<RuleTrigger>] = rules.filter { rule in
            guard let trigger = rule.trigger as? RuleTrigger else {
                return false
            }
            return trigger == RuleTrigger.updateSystem
        }.map { rule in
            guard let timeRule = rule as? any Rule<RuleTrigger> else {
                fatalError("[Ark.setup(rules)] map failed: Unexpected type in array")
            }
            return timeRule
        }

        for rule in timeRules {
            guard let action = rule.action as? any Action<ArkTimeFacade, ExternalResources> else {
                continue
            }
            let system = ArkUpdateSystem(action: action, context: self.actionContext)
            arkState.arkECS.addSystem(system, schedule: .update, isUnique: false)
        }
    }

    private func setup(_ stateSetupFunctions: [ArkStateSetupDelegate]) {
        for stateSetupFunction in stateSetupFunctions {
            arkState.setup(stateSetupFunction, displayContext: displayContext)
        }
    }

    private func setup(_ soundMapping: [ExternalResources.AudioEnum: any Sound]?) {
        guard let soundMapping = soundMapping else {
            return
        }

        audioContext.load(soundMapping)
    }

    private func setupDefaultEntities() {
        arkState.arkECS.createEntity(with: [StopWatchComponent(name: ArkTimeSystem.ARK_WORLD_TIME)])
    }

    private func setupDefaultSystems(_ blueprint: ArkBlueprint<ExternalResources>) {
        let (worldWidth, worldHeight) = getWorldSize(blueprint)

        let simulator = SKSimulator(size: CGSize(width: worldWidth, height: worldHeight))
        self.gameLoop = simulator
        let physicsSystem = ArkPhysicsSystem(simulator: simulator,
                                             eventManager: arkState.eventManager,
                                             arkECS: arkState.arkECS)
        let animationSystem = ArkAnimationSystem()
        let canvasSystem = ArkCanvasSystem()
        let timeSystem = ArkTimeSystem()
        let cameraSystem = ArkCameraSystem()
        arkState.arkECS.addSystem(timeSystem)
        arkState.arkECS.addSystem(physicsSystem)
        arkState.arkECS.addSystem(animationSystem)
        arkState.arkECS.addSystem(canvasSystem)
        arkState.arkECS.addSystem(cameraSystem)

        // inject dependency into game loop
        simulator.physicsScene?.sceneContactUpdateDelegate = physicsSystem
        simulator.physicsScene?.sceneUpdateLoopDelegate = physicsSystem
        self.gameLoop?.updatePhysicsSceneDelegate = physicsSystem
    }

    func setupMultiplayerGameLoop() {
        guard let multiplayerManager = multiplayerManager else {
            return
        }
        let gameLoop = ArkMultiplayerGameLoop()
        self.gameLoop = gameLoop
        self.multiplayerManager?.arkMultiplayerECSDelegate = gameLoop
    }

    private func getWorldSize(_ blueprint: ArkBlueprint<ExternalResources>) -> (width: Double, height: Double) {
        guard let worldEntity = arkState.arkECS.getEntities(with: [WorldComponent.self]).first,
              let worldComponent = arkState.arkECS
              .getComponent(ofType: WorldComponent.self, for: worldEntity)
        else {
            return (blueprint.frameWidth, blueprint.frameHeight)
        }
        return (worldComponent.width, worldComponent.height)
    }

    private func alignCamera() {
        let cameraEntities = arkState.arkECS.getEntities(with: [PlacedCameraComponent.self])
        if !cameraEntities.isEmpty {
            return
        }
        arkState.arkECS.createEntity(with: [PlacedCameraComponent(
            camera: Camera(
                canvasPosition: CGPoint(
                    x: displayContext.canvasSize.width / 2,
                    y: displayContext.canvasSize.height / 2
                ),
                zoom: 1.0
            ),
            screenPosition: CGPoint(
                x: displayContext.screenSize.width / 2,
                y: displayContext.screenSize.height / 2
            ),
            size: displayContext.screenSize)
        ])
    }
}

extension ArkEvent {
    /// A workaround to prevent weird behavior when trying to execute
    /// `action.execute(event, context: context)`
    func executeAction<ExternalResources: ArkExternalResources>(_ action: some Action,
                                                                context: ArkActionContext<ExternalResources>) {
        guard let castedAction = action as? any Action<Self, ExternalResources> else {
            return
        }

        castedAction.execute(self, context: context)
    }
}
