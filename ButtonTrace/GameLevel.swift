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
    static let screenWidth: CGFloat = 540
    static let screenHeight: CGFloat = 960
    static let defaultBallRadius: CGFloat = 80
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
    public func getInitialPosition()->CGPoint{
        return CGPoint.zero
    }
    public func getInfoForTouchPosition(position:CGPoint)->
        (shouldWin: Bool, shouldLose: Bool, ballPosition: CGPoint){
            return (false, false, CGPoint.zero)
    }
}

class BallLevel:GameLevel{
    let ball:SKShapeNode
    override init(){
        self.ball = SKShapeNode.init(circleOfRadius: GameLevelConstants.defaultBallRadius)
        ball.fillColor = UIColor.blue
        ball.strokeColor = UIColor.blue
        super.init()
        let intWidth = UInt32(floor(GameLevelConstants.screenWidth/2.0))
        let intHeight = UInt32(floor(GameLevelConstants.screenHeight/2.0))
        let sign1 = CGFloat((arc4random_uniform(2) == 1) ? -1 : 1)
        let sign2 = CGFloat((arc4random_uniform(2) == 1) ? -1 : 1)
        ball.position.x = CGFloat(arc4random_uniform(intWidth)) * sign1
        ball.position.y = CGFloat(arc4random_uniform(intHeight)) * sign2
        self.addChild(ball)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override public func getInitialPosition()->CGPoint{
        //hide the ball
        return CGPoint(x:-1000, y:-1000)
    }
    override public func getInfoForTouchPosition(position:CGPoint)->
        (shouldWin: Bool, shouldLose: Bool, ballPosition: CGPoint){
            let didWin = ball.contains(CGPoint(x:position.x, y:position.y))
            return (didWin, !didWin, CGPoint(x:-1000, y:-1000))
    }
    
}

class ShapeLevel:GameLevel{
    //main class for GameLevel objects
    
    var displayCorners: [[CGPoint]]
    var contactCorners: [[CGPoint]]
    var shapes: [SKShapeNode]
    var rails: [CGLineSegment]
    var finalHitbox: CGRect
    var displayWidth: CGFloat
    var displayHeight: CGFloat
    var displayCornersOffset: CGPoint
    var contactWidth: CGFloat
    var contactHeight: CGFloat
    //array of points to draw the level. joints should be ordered
    override init() {
        self.displayCorners = []
        self.contactCorners = []
        self.shapes = []
        self.rails = []
        self.displayWidth = 0
        self.displayHeight = 0
        self.displayCornersOffset = CGPoint.zero
        self.contactWidth = 0
        self.contactHeight = 0
        self.finalHitbox = CGRect.zero
        super.init()
        setSize()
        self.displayCorners = self.getCorners(
            width:self.displayWidth,
            height: self.displayHeight,
            bandWidth: GameLevelConstants.levelDisplayWidth)
        self.contactCorners = self.getCorners(
            width:self.contactWidth,
            height: self.contactHeight,
            bandWidth: GameLevelConstants.levelContactWidth)
        
        self.rails = self.getRails()
        finalHitbox = getFinalHitbox()
        render()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.displayCorners = []
        self.contactCorners = []
        self.rails = []
        self.shapes = []
        self.displayWidth = 0
        self.displayHeight = 0
        self.displayCornersOffset = CGPoint.zero
        self.contactWidth = 0
        self.contactHeight = 0
        self.finalHitbox = CGRect.zero
        super.init(coder:aDecoder)
    }
    
    func setSize(){
        // sets size of the object. override in subclasses
    }
    
    override public func getInitialPosition()->CGPoint{
        return rails[0].a
    }
    
    
    func getFinalHitbox()->CGRect{
        return CGRect.zero
    }
    
    public override func getInfoForTouchPosition(position: CGPoint) ->
        (shouldWin: Bool, shouldLose: Bool, ballPosition: CGPoint) {
            
            var shapeIndex:Int = 0
            var matchingShapes:[(point: CGPoint, distance: CGFloat)] = []
            for shape in shapes{
                if shape.contains(position){
                    //contact is touching a sub-shape. test matching rail
                    let rail = rails[shapeIndex]
                    matchingShapes.append(getProjectionPoint(point: position, line: rail))
                }
                shapeIndex += 1
            }
            if matchingShapes.count == 0 {
                //no contact made. you lose
                return (false, true, CGPoint.zero)
            } else {
                
                var closestTuple = matchingShapes[0]
                matchingShapes.remove(at: 0)
                for tuple in matchingShapes{
                    closestTuple = closestTuple.distance > tuple.distance ? tuple : closestTuple
                }
                
                if finalHitbox.contains(
                    CGPoint(x:closestTuple.point.x,
                            y:-closestTuple.point.y)){
                    //touchpoint is inside target area. you win
                    return (true, false, closestTuple.point)
                }
                
                return (false, false, closestTuple.point)
            }
            
    }
    
    func getContactInfo(point: CGPoint)->(isTouching: Bool, railPoint: CGPoint){
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
            for tuple in matchingShapes{
                winningTuple = tuple.distance < winningTuple.distance ? tuple : winningTuple
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
    
    func getCorners(width:CGFloat, height:CGFloat, bandWidth:CGFloat)->[[CGPoint]]{
        return []
    }
    
    func getRails()->[CGLineSegment]{
        return []
    }
    
    func addShapeCollectionFromCorners(corners:[[CGPoint]], addToShapes:Bool, offset:CGPoint){
        let path = CGMutablePath.init()
        for points in corners{
            //points is an array indicating the shape we want
            let initialJoint = points[0]
            path.move(to: CGPoint(x:initialJoint.x + offset.x, y:initialJoint.y + offset.y))
            for i in 1...points.count-1 {
                let joint = points[i]
                path.addLine(to: CGPoint(x:joint.x + offset.x, y:joint.y + offset.y))
            }
            
            //create shape from the path and add to self
            let shape = SKShapeNode.init(path: path)
            shape.fillColor = self.fillColor
            shape.strokeColor = self.strokeColor
            self.addChild(shape)
            if addToShapes {
                shapes.append(shape)
            }
        }
    }
    
    func render() {
        
        //clean up old shapes
        for shape in shapes{
            shape.removeFromParent()
        }
        shapes.removeAll()
        
        //create contact form piece by piece
        
        self.strokeColor = UIColor.clear
        self.fillColor = UIColor.clear
        addShapeCollectionFromCorners(corners:contactCorners,
                                      addToShapes:true,
                                      offset:CGPoint.zero)
        
        //added contact end piece
        let skHitbox = CGRect(x: finalHitbox.origin.x,
                              y: finalHitbox.origin.y,
                              width: finalHitbox.size.width,
                              height: -finalHitbox.size.height)
        let shape = SKShapeNode.init(rect: skHitbox)
        shape.fillColor = UIColor.clear
        shape.strokeColor = UIColor.clear
        self.addChild(shape)
        
        
        self.strokeColor = GameLevelConstants.defaultColor
        self.fillColor = GameLevelConstants.defaultColor
        addShapeCollectionFromCorners(corners:displayCorners,
                                      addToShapes:false,
                                      offset:displayCornersOffset)
        
        
        let path = CGMutablePath.init()
        let initialJoint = rails[0].a
        path.move(to: CGPoint(x:initialJoint.x, y:initialJoint.y))
        for segment in rails{
            path.addLine(to: CGPoint(x:segment.b.x, y:segment.b.y))
        }
        for i in (0...rails.count-1).reversed(){
            let segment = rails[i]
            path.addLine(to: CGPoint(x:segment.a.x, y:segment.a.y))
            
        }
        /*let shaperail = SKShapeNode.init(path: path)
        shaperail.fillColor = UIColor.blue
        shaperail.strokeColor = UIColor.blue
        self.addChild(shaperail)*/
    }
}


class HLineLevel:ShapeLevel{
    override func setSize(){
        // sets size of the object
        contactWidth = GameLevelConstants.screenWidth
        contactHeight = GameLevelConstants.levelContactWidth
        displayWidth = contactWidth
        displayHeight = GameLevelConstants.levelDisplayWidth
    }
    override public func getFinalHitbox()->CGRect{
        return CGRect(
            x: contactWidth/2-GameLevelConstants.railInset,
            y: -contactHeight/2,
            width: GameLevelConstants.levelContactWidth + GameLevelConstants.railInset,
            height: GameLevelConstants.levelContactWidth)
        
    }
    
    override func getCorners(width:CGFloat, height:CGFloat, bandWidth:CGFloat)->[[CGPoint]]{
        //reminder: game coordinates are bottom-up
        return [
            [
                CGPoint(x: -width/2, y: height/2),
                CGPoint(x: width/2, y: height/2),
                CGPoint(x: width/2, y: -height/2),
                CGPoint(x: -width/2, y: -height/2),
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
        contactWidth = GameLevelConstants.levelContactWidth
        contactHeight = 720
        displayWidth = GameLevelConstants.levelDisplayWidth
        displayHeight = contactHeight
    }
    
    override public func getFinalHitbox()->CGRect{
        return CGRect(
            x: -self.contactWidth/2,
            y: self.contactHeight/2-GameLevelConstants.railInset,
            width: GameLevelConstants.levelContactWidth,
            height: GameLevelConstants.levelContactWidth + GameLevelConstants.railInset)
    }
    
    //not needed
    override func getCorners(width:CGFloat, height:CGFloat, bandWidth:CGFloat)->[[CGPoint]]{
        //reminder: game coordinates are bottom-up
        return [
            [
                CGPoint(x: -width/2, y: height/2),
                CGPoint(x: width/2, y: height/2),
                CGPoint(x: width/2, y: -height/2),
                CGPoint(x: -width/2, y: -height/2),
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

class LReversedLevel: ShapeLevel {
    override func setSize(){
        // sets size of the object
        let offset = (GameLevelConstants.levelContactWidth - GameLevelConstants.levelDisplayWidth)/2
        contactWidth = 400
        contactHeight = 720
        displayWidth = contactWidth - offset
        displayHeight = contactHeight - offset
        displayCornersOffset = CGPoint(x: -offset/2, y: -offset/2)
    }
    
    override public func getFinalHitbox()->CGRect{
        return CGRect(
            x: self.contactWidth/2-GameLevelConstants.levelContactWidth,
            y: -(-self.contactHeight/2 + GameLevelConstants.railInset),
            width: GameLevelConstants.levelContactWidth,
            height: GameLevelConstants.levelContactWidth)
    }
    
    override func getCorners(width:CGFloat, height:CGFloat, bandWidth:CGFloat)->[[CGPoint]]{
        return [
            //upper piece
            [
                CGPoint(x: -width/2, y: height/2),
                CGPoint(x: width/2, y: height/2),
                CGPoint(x: width/2, y: height/2 - bandWidth),
                CGPoint(x: -width/2, y: height/2 - bandWidth)
            ],
            //long piece
            [
                CGPoint(
                    x: width/2 - bandWidth,
                    y: height/2),
                CGPoint(
                    x: width/2 - bandWidth,
                    y: -height/2),
                CGPoint(
                    x: width/2,
                    y: -height/2),
                CGPoint(
                    x: width/2,
                    y: height/2)
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


class CounterCircleLevel: ShapeLevel{
    override func setSize(){
        // sets size of the object
        contactWidth = GameLevelConstants.screenWidth
        contactHeight = GameLevelConstants.screenWidth
        displayWidth = GameLevelConstants.levelDisplayWidth
        displayHeight = GameLevelConstants.levelDisplayWidth
    }
    override func getFinalHitbox()->CGRect{
        return CGRect(
            x: self.contactWidth/2-GameLevelConstants.levelContactWidth,
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
        let r = contactWidth/2
        let width = GameLevelConstants.levelContactWidth
        let path = CGMutablePath.init()
        path.addArc(center: CGPoint.zero, radius: r, startAngle: 0, endAngle: CGFloat.pi/2, clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: r-width))
        path.addArc(center: CGPoint.zero, radius: r-width, startAngle: CGFloat.pi/2, endAngle: 0, clockwise: false)

        let shape = SKShapeNode.init(path: path)
        shape.fillColor = UIColor.clear
        shape.strokeColor = UIColor.clear
        self.addChild(shape)
        shapes.append(shape)
        
        //add circle display shape
        let innerR = r - (GameLevelConstants.levelContactWidth-GameLevelConstants.levelDisplayWidth)/2
        let innerWidth = GameLevelConstants.levelDisplayWidth
        let innerpath = CGMutablePath.init()
        innerpath.addArc(center: CGPoint.zero, radius: innerR, startAngle: 0, endAngle: CGFloat.pi/2, clockwise: true)
        innerpath.addLine(to: CGPoint(x: 0, y: r-innerWidth))
        innerpath.addArc(center: CGPoint.zero, radius: innerR-innerWidth, startAngle: CGFloat.pi/2, endAngle: 0, clockwise: false)
        
        let innershape = SKShapeNode.init(path: innerpath)
        
        innershape.strokeColor = GameLevelConstants.defaultColor
        innershape.fillColor = GameLevelConstants.defaultColor
        self.addChild(innershape)
    }
    override public func getInitialPosition() -> CGPoint {
        return CGPoint(
            x: -GameLevelConstants.railInset,
            y: self.contactWidth/2-GameLevelConstants.levelContactWidth/2)
    }
    public override func getInfoForTouchPosition(position: CGPoint) ->
        (shouldWin: Bool, shouldLose: Bool, ballPosition: CGPoint){
            //check if point is within band radius
            let r1 = self.contactWidth/2-GameLevelConstants.levelContactWidth, r2 = self.contactWidth/2
            let r = sqrt(position.x*position.x + position.y*position.y)
            
            if r < r1 || r > r2 {
                return (false, true, CGPoint.zero)
            }
            let projection = getCircularProjection(point: position)
            return (finalHitbox.contains(CGPoint(x:projection.x, y: -projection.y)), false, projection)
    }
    
    func getCircularProjection(point: CGPoint)->CGPoint{
        
        //woohoo trig
        let angle = atan2f(Float(point.y), Float(point.x))
        //don't allow going backwards
        //if angle > Float.pi/4 && angle < Float.pi/2 && point.y>0 {
        //disable movement betwee
        //angle = Float.pi/2
        //}
        let angleX = CGFloat(cos(angle))
        let angleY = -CGFloat(sin(-angle))
        return CGPoint(x: angleX * (self.contactWidth-GameLevelConstants.levelContactWidth)/2,
                       y: angleY * (self.contactWidth-GameLevelConstants.levelContactWidth)/2)
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





