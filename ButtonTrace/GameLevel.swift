//
//  GameLevel.swift
//  ButtonTrace
//
//  Created by Zhuping Hu on 2/24/17.
//  Copyright © 2017 Zhuping Hu. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit

struct GameLevelConstants {
    static let levelLineWidth: CGFloat = 23
    static let defaultColor: UIColor = UIColor.init(red:225.0/255.0, green:222.0/255.0, blue:217.0/255.0, alpha:1.0)
    static let levelCategory: UInt32 = 0x1 << 1
}



class GameLevel:SKShapeNode{
    //main class for GameLevel objects
    
    var joints:[CGPoint]
    var levelWidth:CGFloat
    var levelHeight:CGFloat
    //array of points to draw the level. joints should be ordered
    override init() {
        self.joints = []
        self.levelWidth = 0
        self.levelHeight = 0
        super.init()
        setSize()
        self.joints = self.getJoints()
        self.lineWidth = GameLevelConstants.levelLineWidth
        self.strokeColor = GameLevelConstants.defaultColor
        self.fillColor = GameLevelConstants.defaultColor
        self.lineCap = .round
        
        render()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.joints = []
        self.levelWidth = 0
        self.levelHeight = 0
        super.init(coder:aDecoder)
        setSize()
        self.joints = self.getJoints()
        render()
    }
    
    func getShapeName()->String{
        return "shape"
    }
    func setSize(){
        // sets size of the object. override in subclasses
    }
    
    public func getInitialPosition()->CGPoint{
        if joints.count > 0 {
            return joints.first!
        }
        return CGPoint.zero
    }
    
    public func getFinalPosition()->CGPoint{
        if joints.count > 0 {
            return joints.last!
        }
        return CGPoint.zero
    }
    
    func getJoints()->[CGPoint]{
        return []
    }
    
    func render() {
        self.name = getShapeName()
        if joints.count <= 1 {
            //does nothing if there's no or only 1 joint
            return
        }
        
        let path = CGMutablePath.init()
        
        let initialJoint = joints[0]
        path.move(to: initialJoint)
        
        for i in 1...joints.count-1 {
            let joint = joints[i]
            path.addLine(to: joint)
        }
        
        //retrace path to close it properly
        for j in (0...joints.count-1).reversed() {
            let joint = joints[j]
            path.addLine(to: joint)
        }
        
        self.path = path
        
        let physicsBody = SKPhysicsBody(edgeLoopFrom: path)
        physicsBody.categoryBitMask =  GameLevelConstants.levelCategory
        physicsBody.collisionBitMask = 0
        physicsBody.contactTestBitMask = GameConstants.touchCategory
        physicsBody.affectedByGravity  = false
        self.physicsBody = physicsBody
        
    }
}




class VLineLevel:GameLevel{
    override func setSize(){
        // sets size of the object
        self.levelWidth = GameLevelConstants.levelLineWidth
        self.levelHeight = 550
    }
    
    override func getJoints()->[CGPoint]{
        //reminder: game coordinates are bottom-up
        return [
            CGPoint(x:0, y:self.levelHeight/2),
            CGPoint(x:0, y:-self.levelHeight/2)
        ]
    }
}

class HLineLevel:GameLevel{
    override func setSize(){
        // sets size of the object
        self.levelWidth = 300
        self.levelHeight = GameLevelConstants.levelLineWidth
    }
    
    override func getJoints()->[CGPoint]{
        //reminder: game coordinates are bottom-up
        return [
            CGPoint(x: -self.levelWidth/2, y: 0),
            CGPoint(x: self.levelWidth/2, y: 0)
        ]
    }
}

class LReversedLevel: GameLevel {
    override func setSize(){
        // sets size of the object
        self.levelWidth = 230
        self.levelHeight = 420
    }
    override func getJoints()->[CGPoint]{
        return [
            CGPoint(x: -self.levelWidth/2, y: self.levelHeight/2),
            CGPoint(x: self.levelWidth/2, y: self.levelHeight/2),
            CGPoint(x: self.levelWidth/2, y: -self.levelHeight/2)
        ]
    }
}

class LetterZLevel: GameLevel{
    override func setSize(){
        // sets size of the object
        self.levelWidth = 300
        self.levelHeight = 300
    }
    
    override func getShapeName()->String{
        return "z"
    }
    
    override func getJoints()->[CGPoint]{
        return [
            CGPoint(x: -self.levelWidth/2, y: self.levelHeight/2),
            CGPoint(x: self.levelWidth/2, y: self.levelHeight/2),
            CGPoint(x: -self.levelWidth/2, y: -self.levelHeight/2),
            CGPoint(x: self.levelWidth/2, y: -self.levelHeight/2),
        ]
    }
}

class CounterCircleLevel: GameLevel{
    override func setSize(){
        // sets size of the object
        self.levelWidth = 300
        self.levelHeight = 300
    }
    
    override func render() {
        NSLog("rendering")
        if joints.count <= 1 {
            //does nothing if there's no or only 1 joint
            return
        }
        
        //let path = UIBezierPath.init(arcCenter: CGPoint.zero, radius: self.levelWidth/2, startAngle: 0, endAngle: CGFloat.pi/2, clockwise: false)
        
        let path = CGMutablePath.init()
        //let initialJoint = joints[0]
        //path.move(to: initialJoint)
        path.addArc(center: CGPoint.zero, radius: self.levelWidth/2, startAngle: 0, endAngle: CGFloat.pi/2, clockwise: true)
        path.addArc(center: CGPoint.zero, radius: self.levelWidth/2, startAngle: CGFloat.pi/2, endAngle: 0, clockwise: false)
        let physicsBody = SKPhysicsBody(edgeLoopFrom: path)
        physicsBody.categoryBitMask =  GameLevelConstants.levelCategory
        physicsBody.collisionBitMask = 0
        physicsBody.contactTestBitMask = GameConstants.touchCategory
        physicsBody.affectedByGravity  = false
        physicsBody.usesPreciseCollisionDetection = true
        self.physicsBody = physicsBody
        self.path = path
    }
    override func getJoints()->[CGPoint]{
        return [
            CGPoint(x: 0, y: self.levelHeight/2),
            CGPoint(x: self.levelWidth/2, y: 0)
        ]
    }

}




