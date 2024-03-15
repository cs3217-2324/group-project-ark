import UIKit

protocol AbstractShapeUi: UiRenderable {
    func fill(color: UIColor) -> Self
    func stroke(lineWidth: Double, color: UIColor) -> Self
}

/**
 * Provides default implementation for `fill` and `stroke` methods across different shapes
 */
extension AbstractShapeUi {
    func fill(color: UIColor) -> Self {
        uiView.layer.sublayers?.forEach { subLayer in
            guard let shapeLayer = subLayer as? CAShapeLayer else {
                return
            }
            shapeLayer.fillColor = color.cgColor
        }
        return self
    }
    func stroke(lineWidth: Double, color: UIColor) -> Self {
        uiView.layer.sublayers?.forEach { subLayer in
            guard let shapeLayer = subLayer as? CAShapeLayer else {
                return
            }
            shapeLayer.strokeColor = color.cgColor
            shapeLayer.lineWidth = lineWidth
        }
        return self
    }
}
