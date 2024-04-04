import Foundation

protocol CanvasContext<View> {
    associatedtype View
    typealias RenderableComponentType = ObjectIdentifier

    var rootView: any AbstractRootView<View> { get }
    var memo: [EntityID: [RenderableComponentType: (any RenderableComponent, any Renderable)]] { get }

    func getMegaCanvas() -> Canvas
    func render(_ canvas: any Canvas, using renderer: any RenderableBuilder<View>)
}

class ArkCanvasContext<View>: CanvasContext {
    private(set) var memo: [EntityID: [RenderableComponentType: (any RenderableComponent, any Renderable)]] = [:]
    private(set) var rootView: any AbstractRootView<View>
    private let ecs: ArkECS

    init(ecs: ArkECS, rootView: any AbstractRootView<View>) {
        self.ecs = ecs
        self.rootView = rootView
    }

    func render(_ canvas: any Canvas, using builder: any RenderableBuilder<View>) {
        // unmounting outdated components
        for renderableCompType in ArkCanvasSystem.renderableComponentTypes {
            let componentTypeIdentifier = ObjectIdentifier(renderableCompType)
            let validEntityIds: Set<EntityID> = Set(canvas.canvasEntityToRenderableMapping
                .filter { _, compTypeDict in compTypeDict.keys.contains(componentTypeIdentifier) }
                .map { entityId, _ in entityId })
            for entityId in memo.keys where !validEntityIds.contains(entityId) {
                // entity is no longer valid
                if let (_, renderableFromEntity) = memo[entityId]?[componentTypeIdentifier] {
                    renderableFromEntity.unmount()
                    memo[entityId]?.removeValue(forKey: componentTypeIdentifier)
                }
            }
        }

        // rerendering - unmounting old, rendering new
        for (entityId, component) in canvas.canvasEntityToRenderableMapping {
            for (componentType, renderableComponent) in component {
                if let (previousCanvasComp, previousRenderable) = memo[entityId]?[componentType] {
                    if !renderableComponent.hasUpdated(previous: previousCanvasComp) {
                        continue
                    }
                    previousRenderable.unmount()
                }

                let renderable = renderableComponent.buildRenderable(using: builder)
                render(renderable)

                if memo[entityId] != nil {
                    memo[entityId]?[componentType] = (renderableComponent, renderable)
                } else {
                    memo[entityId] = [componentType: (renderableComponent, renderable)]
                }
            }
        }
    }

    /// Outputs a logical canvas with the relevant entities in the canvas and their renderable components only
    func getMegaCanvas() -> any Canvas {
        // MEGA CANVAS IS DUMB
        var arkCanvas = ArkCanvas()
        for renderableCompType in ArkCanvasSystem.renderableComponentTypes {
            let renderableEntities = ecs.getEntities(with: [renderableCompType])
            let componentType = ObjectIdentifier(renderableCompType)

            for entity in renderableEntities {
                guard let renderableComponent = ecs.getComponent(ofType: renderableCompType, for: entity) else {
                    continue
                }
                arkCanvas.addEntityRenderableToCanvas(entityId: entity.id,
                                                      componentType: componentType,
                                                      renderableComponent: renderableComponent)
            }
        }
        return arkCanvas
    }

    private func render(_ renderable: any Renderable<View>) {
        // TODO: add letterbox logic here
        renderable.render(into: rootView.abstractView)
    }
}
