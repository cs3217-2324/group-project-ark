/**
 * The `CanvasRenderer` implements the rendering logic of each `Renderable`.
 *
 * It should be implemented by the `ArkUiAdapter` or other `UiAdapters` to render various renderables.
 *
 * Devs can also **extend** the `CanvasRenderer` if they have custom canvas elements to render.
 */
protocol CanvasRenderer {
    associatedtype ConcreteColor
    var colorMapping: [AbstractColor: ConcreteColor] { get }
    var defaultColor: ConcreteColor { get }

    func render(_ circle: CircleCanvasComponent)
    func render(_ rect: RectCanvasComponent)
    func render(_ polygon: PolygonCanvasComponent)
    func render(_ image: BitmapImageCanvasComponent)
    func render(_ button: ButtonCanvasComponent)
    func render(_ joystick: JoystickCanvasComponent)
}

extension CanvasRenderer {
    func getColor(_ abstractColor: AbstractColor?) -> ConcreteColor {
        colorMapping[abstractColor ?? .default] ?? defaultColor
    }
}
