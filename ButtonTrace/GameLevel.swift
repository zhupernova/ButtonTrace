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
    static let levelDisplayWidth: CGFloat = 100
    static let levelContactWidth: CGFloat = 200
    static let defaultColor: UIColor = UIColor.init(red:225.0/255.0, green:222.0/255.0, blue:217.0/255.0, alpha:1.0)
    static let levelCategory: UInt32 = 0x1 << 1
    static let railInset: CGFloat = 50
    static let screenWidth: CGFloat = 520
}

struct CGLineSegment {
    let a: CGPoint
    let b: CGPoint
}

extension ClosedRange {
    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}

class GameLevel:SKShapeNode{

}
class Level:GameLevel{
    //main class for GameLevel objects
    
    var corners: [[CGPoint]]
    var shapes: [SKShapeNode]
    var rails: [CGLineSegment]
    var displayWidth: CGFloat
    var displayHeight: CGFloat
    var contactWidth: CGFloat
    var contactHeight: CGFloat
    //array of points to draw the level. joints should be ordered
    override init() {
        self.corners = []
        self.shapes = []
        self.rails = []
        self.displayWidth = 0
        self.displayHeight = 0
        self.contactWidth = 0
        self.contactHeight = 0
        super.init()
        self.strokeColor = GameLevelConstants.defaultColor
        self.fillColor = GameLevelConstants.defaultColor
        
        
        setSize()
        self.corners = self.getCorners()
        self.rails = self.getRails()
        render()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.corners = []
        self.rails = []
        self.shapes = []
        self.displayWidth = 0
        self.displayHeight = 0
        self.contactWidth = 0
        self.contactHeight = 0
        super.init(coder:aDecoder)
    }

    func setSize(){
        // sets size of the object. override in subclasses
    }
    


    public func getInitialPosition()->CGPoint{
        if rails.count > 0{
            return rails.first!.a
        }
        return CGPoint.zero
    }

    
    public func getFinalHitbox()->CGRect{
        return CGRect.zero
    }
    
    public func getContactInfo(point: CGPoint)->(isTouching: Bool, railPoint: CGPoint){
        var shapeIndex:Int = 0
        var matchingShapes:[(point: CGPoint, distance: CGFloat)] = []
        for shape in shapes{
            if shape.contains(point){
                //contact is touching a sub-shape. test matching rail
                let rail = rails[shapeIndex]
                matchingShapes.append(getProjectionPoint(point: point, line: rail))
                
            }
            shapeIndex += 1
        }
        if matchingShapes.count == 0 {
            return (false, CGPoint.zero)
        } else if matchingShapes.count == 1 {
            return (true, matchingShapes[0].point)
        } else {
            var winningTuple = matchingShapes[0]
            matchingShapes.remove(at: 0)
            for tuple in matchingShapes{
                winningTuple = winningTuple.distance > tuple.distance ? tuple : winningTuple
            }
            return (true, winningTuple.point)
        }
        
    }
    
    func getProjectionPoint(point:CGPoint, line:CGLineSegment)->(point: CGPoint, distance: CGFloat){
        let x1=line.a.x, y1=line.a.y, x2=line.b.x, y2=line.b.y, x3=point.x, y3=point.y
        let px = x2-x1, py = y2-y1, dAB = px*px + py*py
        let u = ((x3 - x1) * px + (y3 - y1) * py) / dAB
        var x = x1 + u * px, y = y1 + u * py
        let minMaxX = x1 > x2 ? (min: x2, max: x1) : (min: x1, max: x2) //make a min-max X pair
        let minMaxY = y1 > y2 ? (min: y2, max: y1) : (min: y1, max: y2) //make a min-max Y pair
        x = (minMaxX.min ... minMaxX.max).clamp(x)
        y = (minMaxY.min ... minMaxY.max).clamp(y)
        let dx = x3-x, dy = y3-y, d = dx*dx + dy*dy
        return (CGPoint(x:x, y:y), d)
    }
    
    func getCorners()->[[CGPoint]]{
        return []
    }
    
    func getRails()->[CGLineSegment]{
        return []
    }
    
    func render() {

        //clean up old shapes
        for shape in shapes{
            shape.removeFromParent()
        }
        shapes.removeAll()
        
        //create form piece by piece
        let path = CGMutablePath.init()
        for points in corners{
            //points is an array indicating the shape we want
            let initialJoint = points[0]
            path.move(to: initialJoint)
            for i in 1...points.count-1 {
                let joint = points[i]
                path.addLine(to: joint)
            }
            
            //create shape from the path and add to self
            let shape = SKShapeNode.init(path: path)
            shape.fillColor = self.fillColor
            shape.strokeColor = self.strokeColor
            self.addChild(shape)
            shapes.append(shape)
        }
    }
}





class HLineLevel:GameLevel{
    override func setSize(){
        // sets size of the object
        self.contactWidth = GameLevelConstants.screenWidth
        self.contactHeight = GameLevelConstants.levelContactWidth
    }
    override public func getFinalHitbox()->CGRect{
        return CGRect(
            x: self.contactWidth/2-GameLevelConstants.railInset,
            y: -self.contactHeight/2,
            width: GameLevelConstants.levelContactWidth + GameLevelConstants.railInset,
            height: GameLevelConstants.levelContactWidth)
        
    }
    
    override func getCorners()->[[CGPoint]]{
        //reminder: game coordinates are bottom-up
        return [
            [
                CGPoint(x: -self.contactWidth/2, y: self.contactHeight/2),
                CGPoint(x: self.contactWidth/2+GameLevelConstants.levelContactWidth, y: self.contactHeight/2),
                CGPoint(x: self.contactWidth/2+GameLevelConstants.levelContactWidth, y: -self.contactHeight/2),
                CGPoint(x: -self.contactWidth/2, y: -self.contactHeight/2),
            ]
        ]
    }
    override func getRails() -> [CGLineSegment] {
        return [
            CGLineSegment(
                a: CGPoint(x: -self.contactWidth/2+GameLevelConstants.railInset, y: 0),
                b: CGPoint(x: self.contactWidth/2-GameLevelConstants.railInset, y: 0) )
        ]
    }
}

class VLineLevel:HLineLevel{
    override func setSize(){
        // sets size of the object
        self.contactWidth = GameLevelConstants.levelContactWidth
        self.contactHeight = 720
    }
    
    override public func getFinalHitbox()->CGRect{
        return CGRect(
            x: -self.contactWidth/2,
            y: self.contactHeight/2-GameLevelConstants.railInset,
            width: GameLevelConstants.levelContactWidth,
            height: GameLevelConstants.levelContactWidth + GameLevelConstants.railInset)
    }
    
    //not needed
    override func getCorners()->[[CGPoint]]{
        //reminder: game coordinates are bottom-up
        return [
            [
                CGPoint(x: -self.contactWidth/2, y: self.contactHeight/2),
                CGPoint(x: self.contactWidth/2, y: self.contactHeight/2),
                CGPoint(x: self.contactWidth/2, y: -self.contactHeight/2-GameLevelConstants.levelContactWidth),
                CGPoint(x: -self.contactWidth/2, y: -self.contactHeight/2-GameLevelConstants.levelContactWidth),
                ]
        ]
    }
    override func getRails() -> [CGLineSegment] {
        return [
            CGLineSegment(
                a: CGPoint(x: 0, y: self.contactHeight/2-GameLevelConstants.railInset),
                b: CGPoint(x: 0, y: -self.contactHeight/2+GameLevelConstants.railInset) )
        ]
    }
}

class LReversedLevel: GameLevel {
    override func setSize(){
        // sets size of the object
        self.contactWidth = 400
        self.contactHeight = 720
    }
    
    override public func getFinalHitbox()->CGRect{
        return CGRect(
            x: self.contactWidth/2-GameLevelConstants.levelContactWidth,
            y: -(-self.contactHeight/2 + GameLevelConstants.railInset),
            width: GameLevelConstants.levelContactWidth,
            height: GameLevelConstants.levelContactWidth)
    }
    
    override func getCorners()->[[CGPoint]]{
        return [
            //upper piece
            [
                CGPoint(x: -self.contactWidth/2, y: self.contactHeight/2),
                CGPoint(x: self.contactWidth/2, y: self.contactHeight/2),
                CGPoint(x: self.contactWidth/2, y: self.contactHeight/2-GameLevelConstants.levelContactWidth),
                CGPoint(x: -self.contactWidth/2, y: self.contactHeight/2-GameLevelConstants.levelContactWidth)
            ],
            //long piece
            [
                CGPoint(
                    x: self.contactWidth/2-GameLevelConstants.levelContactWidth,
                    y: self.contactHeight/2),
                CGPoint(
                    x: self.contactWidth/2-GameLevelConstants.levelContactWidth,
                    y: -self.contactHeight/2-GameLevelConstants.levelContactWidth),
                CGPoint(
                    x: self.contactWidth/2,
                        y: -self.contactHeight/2-GameLevelConstants.levelContactWidth),
                CGPoint(
                    x: self.contactWidth/2,
                    y: self.contactHeight/2)
            ]
        ]
    }
    
    override func getRails() -> [CGLineSegment] {
        return [
            //upper piece
            CGLineSegment(
                a: CGPoint(
                    x: -self.contactWidth/2 + GameLevelConstants.railInset,
                    y: (self.contactHeight - GameLevelConstants.levelContactWidth)/2),
                b: CGPoint(
                    x: self.contactWidth/2 - GameLevelConstants.levelContactWidth/2,
                    y: (self.contactHeight - GameLevelConstants.levelContactWidth)/2)),
            //long piece
            CGLineSegment(
                a: CGPoint(
                    x: self.contactWidth/2 - GameLevelConstants.levelContactWidth/2,
                    y: (self.contactHeight - GameLevelConstants.levelContactWidth)/2),
                b: CGPoint(
                    x: self.contactWidth/2 - GameLevelConstants.levelContactWidth/2,
                    y: -self.contactHeight/2 + GameLevelConstants.railInset))
        ]
    }
}

class LetterZLevel: GameLevel{
    override func setSize(){
        // sets size of the object
        self.contactWidth = GameLevelConstants.screenWidth
        self.contactHeight = GameLevelConstants.screenWidth
    }
    
    override public func getFinalHitbox()->CGRect{
        return CGRect(
            x: self.contactWidth/2-GameLevelConstants.railInset,
            y: -(-self.contactHeight/2 + GameLevelConstants.levelContactWidth),
            width: GameLevelConstants.levelContactWidth + GameLevelConstants.railInset,
            height: GameLevelConstants.levelContactWidth)
    }
    
    override func getCorners()->[[CGPoint]]{
        let cornerWidth = sqrt((GameLevelConstants.levelContactWidth*GameLevelConstants.levelContactWidth)*2)
        return [
            [//top piece
                CGPoint(x: -self.contactWidth/2, y: self.contactHeight/2), //top left
                CGPoint(x: self.contactWidth/2, y: self.contactHeight/2), //top right
                CGPoint(
                    x: self.contactWidth/2-cornerWidth,
                    y: self.contactHeight/2 - GameLevelConstants.levelContactWidth), //bottom right
                CGPoint(
                    x: -self.contactWidth/2,
                    y: self.contactHeight/2  - GameLevelConstants.levelContactWidth) //bottom left
            ],
            [//slanted piece
                CGPoint( //top left
                    x: self.contactWidth/2-cornerWidth,
                    y: self.contactHeight/2),
                
                CGPoint(//bottom left
                    x: -self.contactWidth/2,
                    y: -self.contactHeight/2),
                    
                CGPoint(//bottom right
                    x: -self.contactWidth/2+cornerWidth,
                    y: -self.contactHeight/2),
                
                CGPoint(//top right
                    x: self.contactWidth/2,
                    y: self.contactHeight/2)
                ],
            [//bottom piece
                CGPoint(x: -self.contactWidth/2, y: -self.contactHeight/2), //bottom left
                CGPoint(x: self.contactWidth/2+GameLevelConstants.levelContactWidth, y: -self.contactHeight/2), //bottom right
                CGPoint(
                    x: self.contactWidth/2 + GameLevelConstants.levelContactWidth,
                    y: -self.contactHeight/2 + GameLevelConstants.levelContactWidth), //top right
                CGPoint(
                    x: -self.contactWidth/2 + GameLevelConstants.levelContactWidth,
                    y: -self.contactHeight/2  + GameLevelConstants.levelContactWidth) //top left
            ]
        ]
    }
    
    override func getRails() -> [CGLineSegment] {
        return [
            //top piece
            CGLineSegment(
                a: CGPoint(
                    x: -self.contactWidth/2+GameLevelConstants.railInset,
                    y: (self.contactHeight-GameLevelConstants.levelContactWidth)/2),
                b: CGPoint(
                    x: self.contactWidth/2-GameLevelConstants.levelContactWidth,
                    y: (self.contactHeight-GameLevelConstants.levelContactWidth)/2)),
            //slanted piece
            CGLineSegment(
                a: CGPoint(
                    x: self.contactWidth/2-GameLevelConstants.levelContactWidth,
                    y: (self.contactHeight-GameLevelConstants.levelContactWidth)/2),
                b: CGPoint(
                    x: -self.contactWidth/2+GameLevelConstants.levelContactWidth,
                    y: (-self.contactHeight+GameLevelConstants.levelContactWidth)/2)),
            //bottom piece
            CGLineSegment(
                a: CGPoint(
                    x: -self.contactWidth/2+GameLevelConstants.levelContactWidth,
                    y: (-self.contactHeight+GameLevelConstants.levelContactWidth)/2),
                b: CGPoint(
                    x: self.contactWidth/2-GameLevelConstants.railInset,
                    y: (-self.contactHeight+GameLevelConstants.levelContactWidth)/2))
        ]
    }
}

class CounterCircleLevel: GameLevel{
    override func setSize(){
        // sets size of the object
        self.contactWidth = GameLevelConstants.screenWidth
        self.contactHeight = GameLevelConstants.screenWidth
    }
    override public func getFinalHitbox()->CGRect{
        return CGRect(
            x: self.contactWidth/2-GameLevelConstants.levelContactWidth/2,
            y: -GameLevelConstants.levelContactWidth,
            width: GameLevelConstants.levelContactWidth,
            height: GameLevelConstants.levelContactWidth + GameLevelConstants.railInset
        )
    }
    override func render() {
        for shape in shapes{
            shape.removeFromParent()
        }
        shapes.removeAll()
        
        //add circle shape
        let path = CGMutablePath.init()
        path.addArc(center: CGPoint.zero, radius: self.contactWidth/2, startAngle: 0, endAngle: CGFloat.pi/2, clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: self.contactWidth/2-GameLevelConstants.levelContactWidth))
        path.addArc(center: CGPoint.zero, radius: self.contactWidth/2-GameLevelConstants.levelContactWidth, startAngle: CGFloat.pi/2, endAngle: 0, clockwise: false)
        //draw padding
        path.addLine(to: CGPoint(x: self.contactWidth/2-GameLevelConstants.levelContactWidth, y: GameLevelConstants.levelContactWidth))
        path.addLine(to: CGPoint(x: self.contactWidth/2, y: GameLevelConstants.levelContactWidth))
        
        let shape = SKShapeNode.init(path: path)
        shape.fillColor = self.fillColor
        shape.strokeColor = self.strokeColor
        self.addChild(shape)
        shapes.append(shape)
    }
    override public func getInitialPosition() -> CGPoint {
        return CGPoint(
            x: -GameLevelConstants.railInset,
            y: self.contactWidth/2-GameLevelConstants.levelContactWidth/2)
    }

    func getCircularProjection(point: CGPoint)->CGPoint{
        
        //woohoo trig
        let angle = atan2f(Float(point.y), Float(point.x))
        return CGPoint(x: CGFloat(cos(angle)) * (self.contactWidth-GameLevelConstants.levelContactWidth)/2, y: CGFloat(sin(angle)) * (self.contactWidth-GameLevelConstants.levelContactWidth)/2)
    }
    
    override public func getContactInfo(point: CGPoint)->(isTouching: Bool, railPoint: CGPoint){
        for shape in shapes{
            if shape.contains(point){
                return (true, getCircularProjection(point: point))
            }
        }
        return (false, CGPoint.zero)
    }

}




