import Foundation

/**
 * `GameStateRenderer` is implemented by the `ArkUiAdapter` to host its own
 * `UIKitViewController`.
 *
 * The GameStateRenderer delegate is its own protocol so that adapters can be created for other UI implementations
 * like `SwiftUI`.
 */
protocol GameStateRenderer: AnyObject {
    typealias ScreenResizeDelegate = (CGSize) -> Void
    
    func render(canvas: Canvas, with canvasContext: CanvasContext)
    func onScreenResize(_ delegate: @escaping ScreenResizeDelegate)
}
