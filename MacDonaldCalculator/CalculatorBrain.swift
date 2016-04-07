//
//  CalculatorBrain.swift
//  MacDonaldCalculator
//
//  Created by Chris MacDonald on 2/7/16.
//  Copyright © 2016 Chris MacDonald. All rights reserved.
//

import Foundation

class CalculatorBrain
{
    //stack to hold operands and operators in the order they are inputted by the user
    private var opStack = [Op]()
    
    //holds Op types that have been converted from strings
    private var knownOps = [String:Op]()
    
    //holds variables (keys) with their assigned values    
    private var variableValues = [String: Double]()
    
  
    var program: AnyObject { //guaranteed to be a PropertyList
        get {
            return opStack.map { $0.description }
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = NSNumberFormatter().numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    } else {
                        newOpStack.append(.Variable(opSymbol))
                    }
                }
                opStack = newOpStack
            }
        }
    }
    
    //elements are operands and different types of operations, which are all entered by user 
    //and added to the stack
    private enum Op : CustomStringConvertible { // I implement the CustomDebug protocol
        case Operand(Double)
        case UnaryOperation(String, Double -> Double)
        case BinaryOperation(String, Int, (Double, Double) -> Double)
        case Constant(String, Double)
        case Variable(String)
        
        var description: String {
            get {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .UnaryOperation(let symbol, _):
                    return symbol
                case .BinaryOperation(let symbol, _, _):
                    return symbol
                case .Constant(let symbol, _):
                    return symbol
                case .Variable(let symbol):
                    return symbol
                }
            }
        }
        //used to determine when to insert parentheses into the description
        var precedence: Int {
            get {
                switch self {
                case .BinaryOperation(_, let precedence, _):
                    return precedence
                default:
                    return 10
                }
            }
        }
    }
    
    //initialize the CalculatorBrain
    init() {
        //define this function inside init because it's only ever called here
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        learnOp(Op.BinaryOperation("×", 2, *))
        learnOp(Op.BinaryOperation("÷", 2) { $1 / $0 })
        learnOp(Op.BinaryOperation("+", 1, +))
        learnOp(Op.BinaryOperation("−", 1) { $1 - $0 })
        learnOp(Op.UnaryOperation("√", sqrt))
        learnOp(Op.UnaryOperation("sin", sin))
        learnOp(Op.UnaryOperation("cos", cos))
        learnOp(Op.Constant("π", M_PI))
    }
    
    
    //recursive helper function that takes a stack of Ops and performs the operation at the top of the stack.
    //--for binary operations, the operation is performed on the top two numbers beneath the operator
    //--for unary operations, the operation is performed on one number (the top number beneath the operator)
    //--for operands the operand is added to the stack
    //returns a tuple with the output value from the operation (Double?) and the rest of the stack (Op[])
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) { //tuple
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return (operand, remainingOps)
            case .UnaryOperation(_, let operation):
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    return (operation(operand), operandEvaluation.remainingOps)
                }
            case .BinaryOperation(_, _, let operation):
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    let operandEvaluation2 = evaluate(operandEvaluation.remainingOps)
                    if let operand2 = operandEvaluation2.result {
                        return (operation(operand, operand2), operandEvaluation2.remainingOps)
                    }
                }
            case .Constant(_, let constant):
                return (constant, remainingOps)
            case .Variable(let symbol):
                if variableValues[symbol] != nil {
                    return (variableValues[symbol], remainingOps)
                } else {
                    return (nil, ops)
                }
            }
        }
        return (nil, ops)
    }
    
    //calls a helper function to evaluate the operation that is first on the stack
    //returns the resulting value from the operation
    func evaluate() -> Double? {
        let (result, _) = evaluate(opStack)
        return result
        //return evaluate(opStack).result
    }
    
    var currentFunction: String?
    
    //variable that holds a summary of the stack, with operations in infix notation
    var description: String {
        get {
            var (newDescription, remainingOps) = ("", opStack)
            //count of remainingOps will decrease with each recursive call
            while remainingOps.count > 0 {
                var currDescription: String?
                (currDescription, remainingOps, _) = description(remainingOps)
                
                //set the current function in the calculator description
                currentFunction = currDescription

                //if there is no new description returned from the function, don't include it in return value
                newDescription = newDescription == "" ? currDescription! : "\(currDescription!), \(newDescription)"
            }
            return newDescription
        }
    }
    
    //to print the description with function and infix notation, we must have this function return a resulting string,
    //a remaining stack of Ops, and an int indicating the precedence of the op (think of PEMDAS, the order of 
    //operations) 
    //Note: https://github.com/m2mtech/calculator-2015 was a very helpful source here as I struggled with this 
    //recursion
    private func description(ops: [Op]) -> (result: String?, remainingOps: [Op], precedence: Int?) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return ("\(operand)", remainingOps, op.precedence)
            //when dealing with a unary operation, we must recursively call this function to find the operation's
            //argument
            case .UnaryOperation(let symbol, _):
                let argument = description(remainingOps)
                if let arg = argument.result {
                    /*if op.precedence > argument.precedence {
                        arg = "(\(arg))"
                    }*/
                    return (symbol + "(\(arg))", argument.remainingOps, op.precedence)
                }
            //need to do two recursive calls to get the two function arguments
            case .BinaryOperation(let symbol, _,  _):
                let argument2 = description(remainingOps)
                if var op2 = argument2.result {
                    if op.precedence > argument2.precedence {
                        op2 = "(\(op2))"
                    }
                    let argument1 = description(argument2.remainingOps)
                    if var op1 = argument1.result {
                        if op.precedence > argument1.precedence {
                            op1 = "(\(op1))"
                        }
                        return (op1 + symbol + op2, argument1.remainingOps, op.precedence)
                    }
                }
            case .Constant(let symbol, _):
                return (symbol, remainingOps, op.precedence)
            case .Variable(let symbol):
                return (symbol, remainingOps, op.precedence)
            }
        }
        return ("?", ops, 0)
    }

    
    //adds an operand to the top of the Op stack, returns the value returned by evaluate()
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        print("\(opStack)")
        return evaluate()
    }
    
    //adds a variable operand to the top of the Op stack, returns the value returned by evaluate()
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Variable(symbol))
        print("\(opStack)")
        return evaluate()
    }

    //sets the value of a variable by adding the variable (key) to the variableValues dictionary with the value
    func setVariable(symbol: String, value: Double) {
        variableValues[symbol] = value
    }
    
    //removes a variable's value from the dictionary
    func clearVariable(symbol: String) {
        variableValues.removeValueForKey(symbol)
    }
    
    
    //adds an operation to the top of the Op stack, returns the value returned by evaluate()
    func performOperation(symbol: String) -> Double? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
            print("\(opStack)")
            return evaluate()
        }
        return nil
    }
    
    //clears the opstack by resetting it to an empty stack
    func clear() {
        opStack.removeAll()
        variableValues.removeAll()
    }
}
