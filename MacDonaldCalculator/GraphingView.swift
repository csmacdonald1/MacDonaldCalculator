//
//  GraphingView.swift
//  MacDonaldCalculator
//
//  Created by Chris MacDonald on 3/5/16.
//  Copyright © 2016 Chris MacDonald. All rights reserved.
//

import UIKit


//By specifying class here, we ensure this protocol can only be used by a class.
//This protocol allows GraphingView to get data needed to graph points from an outside source
protocol GraphFunctionDataSource: class {
    func xForY(xValue: Double) -> CGPoint?
}
@IBDesignable

class GraphingView: UIView {
    

    //controller will be a GraphFunctionDataSource, weak specification allows controller to go 
    //out of memory
    weak var dataSource: GraphFunctionDataSource?
    
    @IBInspectable var scale: CGFloat = 0.90 { didSet { setNeedsDisplay() }}
    @IBInspectable var newOrigin: CGPoint?
    
    //keep track of the origin of the graph as it moves (it is not always in the center of the view)
    var origin: CGPoint {
        get {
            return newOrigin ?? convertPoint(center, fromView: superview)
        }
        set {
            newOrigin = newValue
            setNeedsDisplay()
        }
    }
    
    var axes = AxesDrawer()
    
    //draw the view
    override func drawRect(rect: CGRect) {
        axes.drawAxesInRect(self.bounds, origin: origin, pointsPerUnit: scale)
        axes.contentScaleFactor = contentScaleFactor
        graphFunction()
    }
    
   
    //loop through all x values across width of bounds, find their corresponding y value (if one exists),
    //then draw a line from point to point to graph the function
    func graphFunction() {
    
        var xVal = bounds.minX
        var lastPointInvalid: Bool = false
        
        let bezierPath = UIBezierPath ()
        
        //iterate across all x values within bounds of view
        while xVal <= bounds.maxX {
            let adjustedXVal = (xVal - origin.x) / scale
            //check to make sure this x value has a corresponding y value (so check if it is a point on the graph)
            if let point = dataSource?.xForY(Double(adjustedXVal)) {
                
                let adjustedPoint = CGPoint(x: point.x * scale + origin.x, y: origin.y - point.y * scale)
                
                //if the last point was not the first point in the path and it wasn't invalid (i.e. if y value wasn't nil),
                //draw a line to it
                if  !bezierPath.empty && !lastPointInvalid {
                    bezierPath.addLineToPoint(adjustedPoint)
                }
                bezierPath.moveToPoint(adjustedPoint)
    
            } else {
                lastPointInvalid = true
            }
            xVal += 1 / scale
        }
        UIColor.redColor().setStroke()
        bezierPath.stroke()
    }
    
    
    //MARK - Gestures
    
    //temporaty UIView used when performing gestures
    var snapshot: UIView?
    
    //function allows for user to zoom in or out on the graph by pinching with two fingers
    func scale(gesture: UIPinchGestureRecognizer) {
        
        switch gesture.state {
        case .Began:
            snapshot = self.snapshotViewAfterScreenUpdates(false)
            self.addSubview(snapshot!)
        case .Changed:
            let touch = gesture.locationInView(self)
            snapshot!.frame.size.height *= gesture.scale
            snapshot!.frame.size.width *= gesture.scale
            snapshot!.frame.origin.x = snapshot!.frame.origin.x * gesture.scale + (1 - gesture.scale) * touch.x
            snapshot!.frame.origin.y = snapshot!.frame.origin.y * gesture.scale + (1 - gesture.scale) * touch.y
            gesture.scale = 1.0
        case .Ended:
            let changedScale = snapshot!.frame.size.height / self.frame.size.height
            scale *= changedScale
            snapshot?.removeFromSuperview()
            snapshot = nil
        default: break
        }
    }
    
    //allows user to move the origin of the graph to a new point by double tapping that point
    func moveOrigin(gesture: UITapGestureRecognizer) {
        if gesture.state == .Ended {
            origin = gesture.locationInView(superview)
        }
    }
    
    //allows the user to pan across the graph using touch gesture
    func pan(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translationInView(self)
        
        origin.x += translation.x
        origin.y += translation.y

        gesture.setTranslation(CGPointZero, inView: self)
    }
    
    //MARK - Description
    /*func addDescription () {
        let description = UITextView(frame: CGRectMake(20.0, 30.0, 300.0, 30.0))
        description.textAlignment = NSTextAlignment.Center
        description.text = "Hello"
        self.addSubview(description)
        
    }*/
    
    

}
