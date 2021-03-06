/*
 * DynamicButton
 *
 * Copyright 2015-present Yannick Loriot.
 * http://yannickloriot.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

import UIKit

/**
Flat design button compounded by several lines to create several symbols like
*arrows*, *checkmark*, *hamburger button*, etc. with animated transitions
between each style changes.
*/
@IBDesignable final public class DynamicButton: UIButton {
  let line1Layer = CAShapeLayer()
  let line2Layer = CAShapeLayer()
  let line3Layer = CAShapeLayer()
  let line4Layer = CAShapeLayer()

  var buttonStyle: DynamicButtonStyle.Type = DynamicButtonStyleHamburger.self

  lazy var allLayers: [CAShapeLayer] = {
    return [self.line1Layer, self.line2Layer, self.line3Layer, self.line4Layer]
    }()

  /**
   Boolean indicates whether the button can bounce when is touched.
   
   By default the value is set to true.
  */
  public var bounceButtonOnTouch: Bool = true

  /**
  Initializes and returns a dynamic button with the specified style.

  You have to think to define its frame because the default one is set to {0, 0, 50, 50}.

  - parameter style: The style of the button.
  - returns: An initialized view object or nil if the object couldn't be created.
  */
  required public init(style: DynamicButtonStyle.Type) {
    super.init(frame: CGRectMake(0, 0, 50, 50))

    buttonStyle = style

    setup()
  }

  /**
  Initializes and returns a newly allocated view object with the specified frame rectangle and with the Hamburger style by default.

  - parameter frame: The frame rectangle for the view, measured in points. The origin of the frame is relative to the superview in which you plan to add it. This method uses the frame rectangle to set the center and bounds properties accordingly.
  - returns: An initialized view object or nil if the object couldn't be created.
  */
  override public init(frame: CGRect) {
    super.init(frame: frame)

    setup()
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

    setup()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()

    let width  = CGRectGetWidth(bounds) - (contentEdgeInsets.left + contentEdgeInsets.right)
    let height = CGRectGetHeight(bounds) - (contentEdgeInsets.top + contentEdgeInsets.bottom)

    intrinsicSize   = min(width, height)
    intrinsicOffset = CGPointMake((CGRectGetWidth(bounds) - intrinsicSize) / 2, (CGRectGetHeight(bounds) - intrinsicSize) / 2)

    setStyle(buttonStyle, animated: false)
  }

  public override func setTitle(title: String?, forState state: UIControlState) {
    super.setTitle("", forState: state)
  }

  // MARK: - Managing the Button Setup

  /// Intrinsic square size
  var intrinsicSize   = CGFloat(0)
  /// Intrinsic square offset
  var intrinsicOffset = CGPointZero

  func setup() {
    setTitle("", forState: .Normal)

    clipsToBounds = true

    addTarget(self, action: #selector(highlightAction), forControlEvents: .TouchDown)
    addTarget(self, action: #selector(highlightAction), forControlEvents: .TouchDragEnter)
    addTarget(self, action: #selector(unhighlightAction), forControlEvents: .TouchDragExit)
    addTarget(self, action: #selector(unhighlightAction), forControlEvents: .TouchUpInside)
    addTarget(self, action: #selector(unhighlightAction), forControlEvents: .TouchCancel)

    for sublayer in allLayers {
      layer.addSublayer(sublayer)
    }

    setupLayerPaths()
  }

  func setupLayerPaths() {
    for sublayer in allLayers {
      sublayer.fillColor     = UIColor.clearColor().CGColor
      sublayer.anchorPoint   = CGPointMake(0, 0)
      sublayer.lineJoin      = kCALineJoinRound
      sublayer.lineCap       = kCALineCapRound
      sublayer.contentsScale = layer.contentsScale
      sublayer.path          = UIBezierPath().CGPath
      sublayer.lineWidth     = lineWidth
      sublayer.strokeColor   = strokeColor.CGColor
    }

    setStyle(buttonStyle, animated: false)
  }

  // MARK: - Configuring Buttons

  /// The button style. The setter is equivalent to the setStyle(, animated:) method with animated value to false. Defaults to Hamburger.
  @IBInspectable public var style: DynamicButtonStyle.Type {
    get {
      return buttonStyle
    }
    set (newValue) {
      setStyle(newValue, animated: false)
    }
  }

  /**
  Set the style of the button and animate the change if needed.

  - parameter style: The style of the button.
  - parameter animated: If true the transition between the old style and the new one is animated.
  */
  public func setStyle(style: DynamicButtonStyle.Type, animated: Bool) {
    buttonStyle = style

    let center = CGPoint(x: intrinsicOffset.x + intrinsicSize / 2, y: intrinsicOffset.y + intrinsicSize / 2)
    let style  = style.init(center: center, size: intrinsicSize, offset: intrinsicOffset, lineWidth: lineWidth)

    applyButtonStyle(style, animated: animated)
  }

  func applyButtonStyle(buttonStyle: DynamicButtonStyle, animated: Bool) {
    accessibilityValue = buttonStyle.description
    
    for config in buttonStyle.animationConfigurations(line1Layer, layer2: line2Layer, layer3: line3Layer, layer4: line4Layer) {
      if animated {
        let anim       = animationWithKeyPath(config.keyPath, damping: 10)
        anim.fromValue = config.layer.path
        anim.toValue   = config.newValue

        config.layer.addAnimation(anim, forKey: config.key)
      }
      else {
        config.layer.removeAllAnimations()
      }

      config.layer.path = config.newValue
    }
  }

  /// Specifies the line width used when stroking the button paths. Defaults to two.
  @IBInspectable public var lineWidth: CGFloat = 2 {
    didSet {
      setupLayerPaths()
    }
  }

  /// Specifies the color to fill the path's stroked outlines, or nil for no stroking. Defaults to black.
  @IBInspectable public var strokeColor: UIColor = UIColor.blackColor() {
    didSet {
      setupLayerPaths()
    }
  }

  /// Specifies the color to fill the path's stroked outlines when the button is highlighted, or nil to use the strokeColor. Defaults to nil.
  @IBInspectable public var highlightStokeColor: UIColor? = nil

  /// Specifies the color to fill the background when the button is highlighted, or nil to use the backgroundColor. Defaults to nil.
  @IBInspectable public var highlightBackgroundColor: UIColor? = nil

  // MARK: - Animating Buttons

  func animationWithKeyPath(keyPath: String, damping: CGFloat = 10, initialVelocity: CGFloat = 0, stiffness: CGFloat = 100) -> CABasicAnimation {
    guard #available(iOS 9, *) else {
      let basic            = CABasicAnimation(keyPath: keyPath)
      basic.duration       = 0.16
      basic.fillMode       = kCAFillModeForwards
      basic.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)

      return basic
    }

    let spring             = CASpringAnimation(keyPath: keyPath)
    spring.duration        = spring.settlingDuration
    spring.damping         = damping
    spring.initialVelocity = initialVelocity
    spring.stiffness       = stiffness
    spring.fillMode        = kCAFillModeForwards
    spring.timingFunction  = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)

    return spring
  }

  // MARK: - Action Methods

  // Store the background color color variable
  var defaultBackgroundColor: UIColor = .clearColor()

  func highlightAction() {
    defaultBackgroundColor = backgroundColor ?? UIColor.clearColor()
    backgroundColor        = highlightBackgroundColor ?? defaultBackgroundColor

    for sublayer in allLayers {
      sublayer.strokeColor = (highlightStokeColor ?? strokeColor).CGColor
    }

    if bounceButtonOnTouch {
      let anim                 = animationWithKeyPath("transform.scale", damping: 20, stiffness: 1000)
      anim.removedOnCompletion = false
      anim.toValue             = 1.2

      layer.addAnimation(anim, forKey: "scaleup")
    }
  }

  func unhighlightAction() {
    backgroundColor = defaultBackgroundColor

    for sublayer in allLayers {
      sublayer.strokeColor = strokeColor.CGColor
    }

    let anim                 = animationWithKeyPath("transform.scale", damping: 100, initialVelocity: 20)
    anim.removedOnCompletion = false
    anim.toValue             = 1
    
    layer.addAnimation(anim, forKey: "scaledown")
  }
}