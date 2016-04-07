//
//  CalculatorViewController.swift
//  MacDonaldCalculator
//
//  Created by Chris MacDonald on 2/7/16.
//  Copyright © 2016 Chris MacDonald. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    
    

    //variable for the display label, which is the top label on the calculator interface
    @IBOutlet weak var display: UILabel!
    
    //variable for the history label, which is the bottom label on the calculator interface
    @IBOutlet weak var history: UILabel!
  
    //variables to keep track of whether user is still typing and to create a Caculator brain object
    var typing : Bool = false
    var brain = CalculatorBrain()

    //function that runs whenever a user types a digit and adds the digit to the display
    @IBAction func digitPressed(sender: UIButton) {
        let digit = sender.currentTitle!
        print("The digit was pressed \(digit)")
        if typing {
            display.text = display.text! + digit
        } else {
            display.text = digit
            typing = true
        }
        
    }

    //function that runs when the user presses the "enter" button, adds the number in the display to the 
    //stack in the calculator brain and updates the history label
    @IBAction func enter() {
        typing = false
        if displayValue != nil {
            if let result = brain.pushOperand(displayValue!)  {
                displayValue = result
                history.text = brain.description
            } else {
                displayValue = 0
            }
        } else {
            display.text = "0"
        }
    }
    
    //function that runs when the user presses an operator button, executes the operation by passing it to 
    //the performOperation function in the calculator brain.  Updates the display with the result and also 
    //updates the history label with the operator and an equals sign, if necessary
    @IBAction func operate(sender: UIButton) {
        if typing {
            enter()
        }
        if let operation = sender.currentTitle {
            if displayValue != nil || display.text == "M" {
                if let result = brain.performOperation(operation) {
                    displayValue = result
                } else {
                    display.text = " "
                }
                history.text = brain.description + " ="
            } else {
                print ("Error")
                display.text = "0"
            }
        }
    }
    
    //Allows the user to type floating point numbers.  User is not able to enter more than one
    //decimal point
    @IBAction func decimal(sender: UIButton) {
        let decimal = sender.currentTitle!
        if typing && display.text!.rangeOfString(".") == nil {
            display.text = display.text! + decimal
        } else if !typing {
            display.text = decimal
            typing = true
        }
    }
    
    //clears the calculator display and history, then clears the
    //calculator brain
    @IBAction func clear(sender: UIButton) {
        display.text! = "0"
        history.text! = ""
        typing = false
        brain.clear()
    }
    
    //deletes the last digit that the user typed
    @IBAction func backspace(sender: UIButton) {
        if display.text!.characters.count > 1 {
            display.text = String(display.text!.characters.dropLast())
        } else {
            display.text = "0"
            typing = false
        }
    }
    
    //pushes the variable M onto the Op stack in the calculator's brain
    @IBAction func enterVariable(sender: UIButton) {
        if typing {
            enter()
        }
        brain.pushOperand("M")
        display.text = "M"
        brain.evaluate()
        
        
        
        history.text = brain.description
    }
    
    //allows the user to set the value of the variable M
    @IBAction func setVariable(sender: UIButton) {
        if displayValue != nil {
            brain.setVariable("M", value: displayValue!)
            if let result = brain.evaluate() {
                displayValue = result
            } else {
                display.text = "0"
            }
        } else {
            display.text = "0"
        }
        history.text = brain.description
        typing = false
    }
    
    
    //converts the text in the display label to a double, which can then be added to the stack 
    //in the calculator brain
    var displayValue: Double? {
        get {
            return NSNumberFormatter().numberFromString(display.text!)?.doubleValue
        }
        set {
            if newValue != nil {
                display.text = "\(newValue!)"
            } else {
                display.text = "0"
            }
            typing = false
        }
    }
    
    //sends necessary information to the other MVC (the GraphingViewController)
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination: UIViewController? = segue.destinationViewController
        if let graphViewCon = destination as? GraphingViewController {
                graphViewCon.program = brain.program
            if history.text != "" {
                if let equation = brain.currentFunction {
                    graphViewCon.descriptionText = equation
                } else {
                    graphViewCon.descriptionText = ""
                }
            } else {
                graphViewCon.descriptionText = ""
            }
        }
    }
    
}

