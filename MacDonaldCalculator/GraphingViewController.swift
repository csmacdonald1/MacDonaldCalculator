//
//  GraphingViewController.swift
//  MacDonaldCalculator
//
//  Created by Chris MacDonald on 3/31/16.
//  Copyright © 2016 Chris MacDonald. All rights reserved.
//

import UIKit

class GraphingViewController: UIViewController, GraphFunctionDataSource {
   
    //assign the delegate for the GraphingView, add gestures to the view
    @IBOutlet weak var graphingView: GraphingView! {
        didSet {
            graphingView.dataSource = self
            graphingView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphingView, action: "scale:"))
            let doubleTap = UITapGestureRecognizer(target: graphingView, action: "moveOrigin:")
            doubleTap.numberOfTapsRequired = 2
            graphingView.addGestureRecognizer(doubleTap)
            graphingView.addGestureRecognizer(UIPanGestureRecognizer(target: graphingView, action: "pan:"))
        }
    }
    
    //create a new CalculatorBrain to access its program variable
    private var brain = CalculatorBrain()
    var program: AnyObject? {
        get {
            return brain.program
        }
        set {
            brain.program = newValue!
        }
    }
    
    //creates a title for the graph which is the equation being graphed
    var descriptionText: String? {
        didSet {
            title = descriptionText
        }
    }

    
    //given an input xValue, solve the current calculator equation for the y-value and return the
    //corresponding point in the x,y plane if it exists
    func xForY(xValue: Double) -> CGPoint? {
        
        //set M to the x value
        brain.setVariable("M", value: xValue)
        
        if let yValue = brain.evaluate() {
            let point = CGPoint(x: CGFloat(xValue), y: CGFloat(yValue))
            if !point.x.isNormal || !point.y.isNormal {
                return nil
            }
            return point
        }
        return nil
    }
}
