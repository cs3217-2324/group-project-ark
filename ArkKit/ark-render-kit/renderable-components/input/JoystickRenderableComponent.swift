import CoreGraphics

struct JoystickRenderableComponent: AbstractPannable, RenderableComponent {
    var center: CGPoint = .zero
    var rotation: Double = 0.0
    var zPosition: Double = 0.0
    var opacity: Double = 1.0
    var isUserInteractionEnabled = true
    var renderLayer: RenderLayer = .canvas
    var shouldRerenderDelegate: ShouldRerenderDelegate?

    let radius: Double

    var onPanStartDelegate: PanEventDelegate?
    var onPanChangeDelegate: PanEventDelegate?
    var onPanEndDelegate: PanEventDelegate?

    init(radius: Double) {
        self.radius = radius
    }

    func modify(
        onPanStartDelegate: PanEventDelegate?,
        onPanChangeDelegate: PanEventDelegate?,
        onPanEndDelegate: PanEventDelegate?
    ) -> JoystickRenderableComponent {
        var updated = self
        updated.onPanStartDelegate = onPanStartDelegate
        updated.onPanChangeDelegate = onPanChangeDelegate
        updated.onPanEndDelegate = onPanEndDelegate

        return updated
    }

    func buildRenderable<T>(using builder: any RenderableBuilder<T>) -> any Renderable<T> {
        builder.build(self)
    }
}
