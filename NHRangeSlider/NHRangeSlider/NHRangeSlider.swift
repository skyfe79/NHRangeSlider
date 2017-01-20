//
//  NHRangeSlider.swift
//  NHRangeSlider
//
//  Created by Hung on 17/12/16.
//  Copyright © 2016 Hung. All rights reserved.
//

import UIKit
import QuartzCore

/// Range slider track layer. Responsible for drawing the horizontal track
public class RangeSliderTrackLayer: CALayer {
    
    /// owner slider
    weak var rangeSlider: NHRangeSlider?
    
    /// draw the track between 2 thumbs
    ///
    /// - Parameter ctx: current graphics context
    override open func draw(in ctx: CGContext) {
        guard let slider = rangeSlider else {
            return
        }

        
        // Clip
        let cr = bounds.height * slider.curvaceousness / 2.0
        self.cornerRadius = cr
        self.masksToBounds = true
        
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        ctx.addPath(path.cgPath)
        
        // Fill the track
        ctx.addPath(path.cgPath)
        drawLinearGradient(in: ctx, rect: bounds, startColor: slider.trackStartColor.cgColor, endColor: slider.trackEndColor.cgColor)
        
        // Fill the highlighted range
        let lowerValuePosition = CGFloat(slider.positionForValue(slider.lowerValue))
        let upperValuePosition = CGFloat(slider.positionForValue(slider.upperValue))
        let rect = CGRect(x: lowerValuePosition, y: 0.0, width: upperValuePosition - lowerValuePosition, height: bounds.height)
        drawLinearGradient(in: ctx, rect: rect, startColor: slider.trackHighlightStartColor.cgColor, endColor: slider.trackHighlightEndColor.cgColor)
        
        
    }
    
    fileprivate func drawLinearGradient(in ctx: CGContext, rect: CGRect, startColor: CGColor, endColor: CGColor) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations : [CGFloat] = [ 0.0, 1.0 ]
        let colors : [CGColor] = [ startColor, endColor ]
        
        guard let gradient = CGGradient.init(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else { return }
        
        let startPoint = CGPoint(x: rect.minX, y: rect.midY)
        let endPoint = CGPoint(x: rect.maxX, y: rect.midY)
        
        ctx.saveGState()
        ctx.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        ctx.restoreGState()

    }
}

/// the thumb for upper , lower bounds
public class RangeSliderThumbLayer: CALayer {
    
    /// owner slider
    weak var rangeSlider: NHRangeSlider?
    
    /// whether this thumb is currently highlighted i.e. touched by user
    public var highlighted: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// stroke color
    public var strokeColor: UIColor = UIColor.gray {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// line width
    public var lineWidth: CGFloat = 0.5 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var image : UIImage? = nil {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// draw the thumb
    ///
    /// - Parameter ctx: current graphics context
    override open func draw(in ctx: CGContext) {
        guard let slider = rangeSlider else {
            return
        }
        
        
        if let image = image?.cgImage {
            
            ctx.draw(image, in: bounds)
            
        } else {
            let thumbFrame = bounds.insetBy(dx: 2.0, dy: 2.0)
            let cornerRadius = thumbFrame.height * slider.curvaceousness / 2.0
            let thumbPath = UIBezierPath(roundedRect: thumbFrame, cornerRadius: cornerRadius)
            
            
            // Fill
            ctx.setFillColor(slider.thumbTintColor.cgColor)
            ctx.addPath(thumbPath.cgPath)
            ctx.fillPath()
            
            // Outline
            ctx.setStrokeColor(strokeColor.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.addPath(thumbPath.cgPath)
            ctx.strokePath()
            
            if highlighted {
                ctx.setFillColor(UIColor(white: 0.0, alpha: 0.1).cgColor)
                ctx.addPath(thumbPath.cgPath)
                ctx.fillPath()
            }
        }
    }
}


/// Range slider view with upper, lower bounds
@IBDesignable
open class NHRangeSlider: UIControl {
    
    //MARK: properties
    
    /// minimum value
    @IBInspectable open var minimumValue: Double = 0.0 {
        willSet(newValue) {
            assert(newValue < maximumValue, "NHRangeSlider: minimumValue should be lower than maximumValue")
        }
        didSet {
            updateLayerFrames()
        }
    }
    
    /// max value
    @IBInspectable open var maximumValue: Double = 100.0 {
        willSet(newValue) {
            assert(newValue > minimumValue, "NHRangeSlider: maximumValue should be greater than minimumValue")
        }
        didSet {
            updateLayerFrames()
        }
    }
    
    /// value for lower thumb
    @IBInspectable open var lowerValue: Double = 0.0 {
        didSet {
            if lowerValue < minimumValue {
                lowerValue = minimumValue
            }
            updateLayerFrames()
        }
    }
    
    /// value for upper thumb
    @IBInspectable open var upperValue: Double = 100.0 {
        didSet {
            if upperValue > maximumValue {
                upperValue = maximumValue
            }
            updateLayerFrames()
        }
    }
    
    
    /// stepValue. If set, will snap to discrete step points along the slider . Default to nil
    @IBInspectable open var stepValue: Double? = nil {
        willSet(newValue) {
            if newValue != nil {
                assert(newValue! > 0, "NHRangeSlider: stepValue must be positive")
            }
        }
        didSet {
            if let val = stepValue {
                if val <= 0 {
                    stepValue = nil
                }
            }
            
            updateLayerFrames()
        }
    }

    
    
    /// minimum distance between the upper and lower thumbs.
    @IBInspectable open var gapBetweenThumbs: Double = 2.0
    
    /// track highlight tint color
    @IBInspectable open var trackHighlightStartColor: UIColor = UIColor.red {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable open var trackHighlightEndColor: UIColor = UIColor.blue {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    /// 트랙색상을 그래디언트로 그릴 수 있게 한다.
    /// 그래디언트 시작 색상
    @IBInspectable open var trackStartColor: UIColor = UIColor.gray {
        didSet {
            trackLayer.setNeedsLayout()
        }
    }
    
    /// 트랙색상을 그래디언트로 그릴 수 있게 한다.
    /// 그래디언트 끝 색상
    @IBInspectable open var trackEndColor: UIColor = UIColor.gray {
        didSet {
            trackLayer.setNeedsLayout()
        }
    }
    
    
    /// thumb tint color
    @IBInspectable open var thumbTintColor: UIColor = UIColor.white {
        didSet {
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
        }
    }
    
    /// thumb border color
    @IBInspectable open var thumbBorderColor: UIColor = UIColor.gray {
        didSet {
            lowerThumbLayer.strokeColor = thumbBorderColor
            upperThumbLayer.strokeColor = thumbBorderColor
        }
    }
    
    
    /// thumb border width
    @IBInspectable open var thumbBorderWidth: CGFloat = 0.5 {
        didSet {
            lowerThumbLayer.lineWidth = thumbBorderWidth
            upperThumbLayer.lineWidth = thumbBorderWidth
        }
    }
    
    /// set 0.0 for square thumbs to 1.0 for circle thumbs
    @IBInspectable open var curvaceousness: CGFloat = 1.0 {
        didSet {
            if curvaceousness < 0.0 {
                curvaceousness = 0.0
            }
            
            if curvaceousness > 1.0 {
                curvaceousness = 1.0
            }
            
            trackLayer.setNeedsDisplay()
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable open var thumbImage : UIImage? = nil {
        didSet {
            lowerThumbLayer.image = thumbImage
            upperThumbLayer.image = thumbImage
        }
    }
    
    @IBInspectable open var trackHeight : CGFloat = 10 {
        didSet {
            trackLayer.setNeedsLayout()
        }
    }
    
    /// previous touch location
    fileprivate var previouslocation = CGPoint()
    
    /// track layer
    fileprivate let trackLayer = RangeSliderTrackLayer()
    
    /// lower thumb layer
    public let lowerThumbLayer = RangeSliderThumbLayer()
    
    /// upper thumb layer
    public let upperThumbLayer = RangeSliderThumbLayer()
    
    /// thumb width
    fileprivate var thumbWidth: CGFloat {
        return CGFloat(bounds.height)
    }
    
    /// frame
    override open var frame: CGRect {
        didSet {
            updateLayerFrames()
        }
    }
    
    //MARK: init methods
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initializeLayers()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeLayers()
    }
    
    //MARK: layers
    
    /// layout sub layers
    ///
    /// - Parameter of: layer
    override open func layoutSublayers(of: CALayer) {
        super.layoutSublayers(of:layer)
        updateLayerFrames()
    }
    
    /// init layers
    fileprivate func initializeLayers() {
        layer.backgroundColor = UIColor.clear.cgColor
        
        trackLayer.rangeSlider = self
        trackLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(trackLayer)
        
        lowerThumbLayer.rangeSlider = self
        lowerThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(lowerThumbLayer)
        
        upperThumbLayer.rangeSlider = self
        upperThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(upperThumbLayer)
    }
    
    /// update layer frames
    open func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        //trackLayer.frame = bounds.insetBy(dx: 0.0, dy: bounds.height/3)
        trackLayer.frame = CGRect(x: bounds.origin.x, y: bounds.midY - (trackHeight/2), width: bounds.size.width, height: trackHeight)
        trackLayer.setNeedsDisplay()
        
        let lowerThumbCenter = CGFloat(positionForValue(lowerValue))
        lowerThumbLayer.frame = CGRect(x: lowerThumbCenter - thumbWidth/2.0, y: 0.0, width: thumbWidth, height: thumbWidth)
        lowerThumbLayer.setNeedsDisplay()
        
        let upperThumbCenter = CGFloat(positionForValue(upperValue))
        upperThumbLayer.frame = CGRect(x: upperThumbCenter - thumbWidth/2.0, y: 0.0, width: thumbWidth, height: thumbWidth)
        upperThumbLayer.setNeedsDisplay()
        
        CATransaction.commit()
    }
    
    /// thumb x position for new value
    open func positionForValue(_ value: Double) -> Double {
        if (maximumValue == minimumValue) {
            return 0
        }
        
        return Double(bounds.width - thumbWidth) * (value - minimumValue) / (maximumValue - minimumValue)
            + Double(thumbWidth/2.0)
    }
    
    
    /// bound new value within lower and upper value
    ///
    /// - Parameters:
    ///   - value: value to set
    ///   - lowerValue: lower value
    ///   - upperValue: upper value
    /// - Returns: current value
    open func boundValue(_ value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double {
        return min(max(value, lowerValue), upperValue)
    }
    
    
    // MARK: - Touches
    
    /// begin tracking
    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previouslocation = touch.location(in: self)
        
        // set highlighted positions for lower and upper thumbs
        if lowerThumbLayer.frame.contains(previouslocation) {
            lowerThumbLayer.highlighted = true
        }
        
        if upperThumbLayer.frame.contains(previouslocation) {
            upperThumbLayer.highlighted = true
        }
        
        return lowerThumbLayer.highlighted || upperThumbLayer.highlighted
    }
    
    /// update positions for lower and upper thumbs
    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        
        // Determine by how much the user has dragged
        let deltaLocation = Double(location.x - previouslocation.x)
        var deltaValue : Double = 0
        
        if (bounds.width != bounds.height) {
            deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - bounds.height)
        }
        
        
        previouslocation = location
        
        // if both are highlighted. we need to decide which direction to drag
        if lowerThumbLayer.highlighted && upperThumbLayer.highlighted {
            
            if deltaLocation > 0 {
                // left to right
                upperValue = boundValue(upperValue + deltaValue, toLowerValue: lowerValue + gapBetweenThumbs, upperValue: maximumValue)
            }
            else {
                // right to left
                lowerValue = boundValue(lowerValue + deltaValue, toLowerValue: minimumValue, upperValue: upperValue - gapBetweenThumbs)
            }
        }
        else {
            
            // Update the values
            if lowerThumbLayer.highlighted {
                lowerValue = boundValue(lowerValue + deltaValue, toLowerValue: minimumValue, upperValue: upperValue - gapBetweenThumbs)
            } else if upperThumbLayer.highlighted {
                upperValue = boundValue(upperValue + deltaValue, toLowerValue: lowerValue + gapBetweenThumbs, upperValue: maximumValue)
            }
        }
        
        // only send changed value if stepValue is not set. We will trigger this later in endTracking
        if stepValue == nil {
            sendActions(for: .valueChanged)
        }
        
        return true
    }
    
    /// end touch tracking. Unhighlight the two thumbs
    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        lowerThumbLayer.highlighted = false
        upperThumbLayer.highlighted = false
        
        // let slider snap after user stop dragging
        if let stepValue = stepValue {
            lowerValue = round(lowerValue / stepValue) * stepValue
            upperValue = round(upperValue / stepValue) * stepValue
            sendActions(for: .valueChanged)
        }
        
        
    }
    
}
