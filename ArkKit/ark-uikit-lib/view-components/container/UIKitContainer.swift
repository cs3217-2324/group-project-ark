import UIKit

final class UIKitContainer: UIView, UIKitRenderable {
    var renderableComponents: [any RenderableComponent] = []

    func addToContainer(_ renderables: [any Renderable<UIView>]) -> Self {
        for renderable in renderables {
            guard let viewComp = renderable as? any UIKitRenderable else {
                continue
            }
            self.addSubview(viewComp)
        }
        return self
    }

    func scaleFromOrigin(byWidth widthScaleFactor: CGFloat, byHeight heightScaleFactor: CGFloat) -> Self {
        self.transform = self.transform.scaledBy(x: widthScaleFactor, y: heightScaleFactor)
        self.frame.origin = CGPoint.zero
        return self
    }

    func setMask(_ maskFrame: CGRect?) -> Self {
        guard let mask = maskFrame else {
            return self
        }
        let maskView = UIView(frame: mask)
        let convertedMaskFrame = maskView.convert(maskView.bounds, to: self)
        maskView.frame = convertedMaskFrame
        // any opaque color
        // reference: https://developer.apple.com/documentation/uikit/uiview/1622557-mask
        maskView.backgroundColor = .blue
        self.mask = maskView
        return self
    }

    func scaleFromCenter(byWidth widthScaleFactor: CGFloat, byHeight heightScaleFactor: CGFloat) -> Self {
        let center = self.center
        self.transform = self.transform.scaledBy(x: widthScaleFactor, y: heightScaleFactor)
        self.center = center
        return self
    }
}
