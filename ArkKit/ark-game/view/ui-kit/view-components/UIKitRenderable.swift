import UIKit

protocol UIKitRenderable: UIView, Renderable {
}

extension UIKitRenderable {
    func render(into container: UIView) {
        container.addSubview(self)
    }

    func rotate(by rotationInRadians: Double) -> Self {
        self.transform = self.transform.rotated(by: rotationInRadians)
        return self
    }

    func zPosition(_ zPos: Double) -> Self {
        self.layer.zPosition = zPos
        return self
    }

    func `if`(_ condition: Bool, transform: (Self) -> Self) -> Self {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    func unmount() {
        self.removeFromSuperview()
    }
}
