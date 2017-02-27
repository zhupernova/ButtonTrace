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
    static let levelLineWidth: CGFloat = 50
    static let defaultColor: UIColor = UIColor.init(red:225.0/255.0, green:222.0/255.0, blue:217.0/255.0, alpha:1.0)
    static let levelCategory: UInt32 = 0x1 << 1
    static let levelsInset: CGFloat = 40
    static let screenWidth: CGFloat = 520
}



class GameLevel:SKShapeNode{
    //main class for GameLevel objects
    
    var joints:[CGPoint]
    var levelWidth: CGFloat
    var levelHeight: CGFloat
    var lineWidthModifier: CGFloat
    //array of points to draw the level. joints should be ordered
    override init() {
        self.joints = []
        self.levelWidth = 0
        self.levelHeight = 0
        self.lineWidthModifier = 0
        super.init()
        self.strokeColor = GameLevelConstants.defaultColor
        self.fillColor = GameLevelConstants.defaultColor
        self.lineCap = .round
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.joints = []
        self.levelWidth = 0
        self.levelHeight = 0
        self.lineWidthModifier = 0
        super.init(coder:aDecoder)
    }

    func setSize(){
        // sets size of the object. override in subclasses
    }
    
    func getLineWidth()->CGFloat{
        return GameLevelConstants.levelLineWidth + lineWidthModifier
    }
    public func setLineWidthModifier(modifier:CGFloat){

        lineWidthModifier = modifier
        setSize()
        self.joints = self.getJoints()
        render()
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

        self.path = path
        
        
    }
}





class HLineLevel:GameLevel{
    override func setSize(){
        // sets size of the object
        self.levelWidth = GameLevelConstants.screenWidth
        self.levelHeight = getLineWidth()
    }
    override public func getInitialPosition() -> CGPoint {
        return CGPoint(x: -self.levelWidth/2+GameLevelConstants.levelsInset, y: 0)
    }
    override public func getFinalPosition() -> CGPoint {
        return CGPoint(x: self.levelWidth/2-GameLevelConstants.levelsInset/2, y: 0)
    }
    
    override func getJoints()->[CGPoint]{
        //reminder: game coordinates are bottom-up
        return [
            CGPoint(x: -self.levelWidth/2, y: self.levelHeight/2),
            CGPoint(x: self.levelWidth/2, y: self.levelHeight/2),
            CGPoint(x: self.levelWidth/2, y: -self.levelHeight/2),
            CGPoint(x: -self.levelWidth/2, y: -self.levelHeight/2),
        ]
    }
}

class VLineLevel:HLineLevel{
    override func setSize(){
        // sets size of the object
        self.levelWidth = getLineWidth()
        self.levelHeight = 720
    }
    override public func getInitialPosition() -> CGPoint {
        return CGPoint(x: 0, y: self.levelHeight/2-GameLevelConstants.levelsInset)
    }
    override public func getFinalPosition() -> CGPoint {
        return CGPoint(x: 0, y: -self.levelHeight/2+GameLevelConstants.levelsInset/2)
    }
    
}
class LReversedLevel: GameLevel {
    override func setSize(){
        // sets size of the object
        self.levelWidth = 400
        self.levelHeight = 720
    }
    override public func getInitialPosition() -> CGPoint {
        return CGPoint(
            x: -self.levelWidth/2+GameLevelConstants.levelsInset,
            y: self.levelHeight/2-getLineWidth()/2)
    }
    override public func getFinalPosition() -> CGPoint {
        return CGPoint(
            x: self.levelWidth/2-getLineWidth()/2,
            y: -self.levelHeight/2+GameLevelConstants.levelsInset/2)
    }
    override func getJoints()->[CGPoint]{
        return [
            CGPoint(x: -self.levelWidth/2, y: self.levelHeight/2),
            CGPoint(x: self.levelWidth/2, y: self.levelHeight/2),
            CGPoint(x: self.levelWidth/2, y: -self.levelHeight/2),
            CGPoint(
                x: self.levelWidth/2-getLineWidth(),
                y: -self.levelHeight/2),
            CGPoint(
                x: self.levelWidth/2-getLineWidth(),
                y: self.levelHeight/2-getLineWidth()),
            CGPoint(
                x: -self.levelWidth/2,
                y: self.levelHeight/2-getLineWidth())
        ]
    }
}

class LetterZLevel: GameLevel{
    override func setSize(){
        // sets size of the object
        self.levelWidth = GameLevelConstants.screenWidth
        self.levelHeight = GameLevelConstants.screenWidth
    }

    override public func getInitialPosition() -> CGPoint {
        return CGPoint(x: -self.levelWidth/2+GameLevelConstants.levelsInset, y: self.levelHeight/2-getLineWidth()/2)
    }
    override public func getFinalPosition() -> CGPoint {
        return CGPoint(x: self.levelWidth/2-GameLevelConstants.levelsInset/2, y: -self.levelHeight/2)
    }
    
    override func getJoints()->[CGPoint]{
        let cornerWidth = sqrt((getLineWidth()*getLineWidth())*2)
        return [
            CGPoint(x: -self.levelWidth/2, y: self.levelHeight/2), //top left
            
            CGPoint(x: self.levelWidth/2, y: self.levelHeight/2), //top right
            
            CGPoint(
                x: self.levelWidth/2,
                y: self.levelHeight/2-getLineWidth()), //top right slant right
            
            CGPoint(
                x: -self.levelWidth/2+cornerWidth,
                y: -self.levelHeight/2+getLineWidth()), //lower left on top
            
            CGPoint(
                x: self.levelWidth/2,
                y: -self.levelHeight/2+getLineWidth()), //lower right top
            
            
            CGPoint(
                x: self.levelWidth/2,
                y: -self.levelHeight/2), //lower right bottom
            
            CGPoint(
                x: -self.levelWidth/2,
                y: -self.levelHeight/2),
            
            CGPoint(
                x: -self.levelWidth/2,
                y: -self.levelHeight/2+getLineWidth()),
            
            CGPoint(
                x: self.levelWidth/2-cornerWidth,
                y: self.levelHeight/2-getLineWidth()),
            
            CGPoint(
                x: -self.levelWidth/2,
                y: self.levelHeight/2-getLineWidth())
            
        ]
    }
}

class CounterCircleLevel: GameLevel{
    override func setSize(){
        // sets size of the object
        self.levelWidth = GameLevelConstants.screenWidth
        self.levelHeight = GameLevelConstants.screenWidth
    }
    
    override public func getInitialPosition() -> CGPoint {
        return CGPoint(
            x: -GameLevelConstants.levelsInset,
            y: self.levelWidth/2-getLineWidth()/2)
    }
    
    override public func getFinalPosition() -> CGPoint {
        return CGPoint(
            x: self.levelWidth/2-getLineWidth()/2,
            y: -GameLevelConstants.levelsInset/2)
    }
    
    override func render() {
        NSLog("rendering")
        if joints.count <= 1 {
            //does nothing if there's no or only 1 joint
            return
        }
        
        let path = CGMutablePath.init()
        path.addArc(center: CGPoint.zero, radius: self.levelWidth/2, startAngle: 0, endAngle: CGFloat.pi/2, clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: self.levelWidth/2-getLineWidth()))
        path.addArc(center: CGPoint.zero, radius: self.levelWidth/2-getLineWidth(), startAngle: CGFloat.pi/2, endAngle: 0, clockwise: false)
        self.path = path
    }
    override func getJoints()->[CGPoint]{
        return [
            CGPoint(x: 0, y: self.levelHeight/2),
            CGPoint(x: self.levelWidth/2, y: 0)
        ]
    }

}




