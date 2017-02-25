//
//  GameScene.swift
//  ButtonTrace
//
//  Created by Zhuping Hu on 2/24/17.
//  Copyright © 2017 Zhuping Hu. All rights reserved.
//

import SpriteKit
import GameplayKit

struct GameConstants {
    static let winColor: UIColor = UIColor.init(red: 121.0/255.0, green: 195.0/255.0, blue: 81.0/255.0, alpha: 1.0)
    static let loseColor: UIColor = UIColor.init(red: 227.0/255.0, green: 86.0/255.0, blue: 45.0/255.0, alpha:1.0)
    static let backgroundColor: UIColor = UIColor.init(red: 242.0/255.0, green: 241.0/255.0, blue: 246.0/255.0, alpha: 1.0)
    static let touchCategory: UInt32 = 0x1 << 0
    static let touchRadius: CGFloat = 20
    static let ballRadius: CGFloat = 50
    static let maxVelocity: CGFloat = 85
}

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    var didRenderGame: Bool? //needed in case of app backgrounding, which may cause didMoveToView to execute again
    
    
    private var touchIndicator: SKShapeNode
    private var ballNode: SKShapeNode
    private let levels: [GameLevel]
    private var levelIndex: Int
    private var currentLevel: GameLevel?
    
    //ball tracking parameters
    private var isTrackingBall: Bool
    private var contactsBegan: Int
    private var lastTrackedPoint: CGPoint
    
    //timer display
    private var shouldRefreshTimeInterval: Bool
    private var timerLabel: SKLabelNode
    private var timeSinceCurrentLevel: TimeInterval
    
    override init(){
        isTrackingBall = false
        shouldRefreshTimeInterval  = false
        touchIndicator = SKShapeNode.init(circleOfRadius: GameConstants.touchRadius)
        ballNode = SKShapeNode.init(circleOfRadius: GameConstants.ballRadius)
        timerLabel = SKLabelNode(fontNamed: "TrebuchetMS")
        timeSinceCurrentLevel = 0
        levelIndex = 0
        contactsBegan = 0
        lastTrackedPoint = CGPoint.zero
        levels = [LetterZLevel(),  HLineLevel(), VLineLevel(), LReversedLevel(), CounterCircleLevel()]
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        isTrackingBall = false
        shouldRefreshTimeInterval  = false
        touchIndicator = SKShapeNode.init(circleOfRadius: GameConstants.touchRadius)
        ballNode = SKShapeNode.init(circleOfRadius: GameConstants.ballRadius)
        timerLabel = SKLabelNode(fontNamed: "TrebuchetMS")
        timeSinceCurrentLevel = 0
        levelIndex = 0
        contactsBegan = 0
        lastTrackedPoint = CGPoint.zero
        levels = [LetterZLevel(),  HLineLevel(), VLineLevel(), LReversedLevel(), CounterCircleLevel()]
        super.init(coder: aDecoder)
    }
    
    
    
    override func didMove(to view: SKView) {
        if didRenderGame == nil {
            didRenderGame? = true
            renderGame()
        }
    }
    
    func renderGame(){
        
        //initialize physics
        self.physicsWorld.contactDelegate = self
        //invisible indicator representing touch area
        touchIndicator.fillColor = UIColor.blue
        touchIndicator.zPosition = 2
        touchIndicator.position = CGPoint(x: -1000, y: -1000)
        touchIndicator.name = "touch"
        let ballPhysics = SKPhysicsBody.init(circleOfRadius: touchIndicator.frame.size.width/2)
        touchIndicator.physicsBody = ballPhysics
        ballPhysics.usesPreciseCollisionDetection = true
        ballPhysics.categoryBitMask = GameConstants.touchCategory
        ballPhysics.collisionBitMask = 0
        ballPhysics.contactTestBitMask = GameLevelConstants.levelCategory
        ballPhysics.affectedByGravity  = false
        self.addChild(touchIndicator)
        
        //the ball we're trying to track
        isTrackingBall = false
        ballNode.fillColor = UIColor.red
        ballNode.zPosition = 1
        self.addChild(ballNode)
        
        timerLabel.fontColor  = UIColor.black
        timerLabel.verticalAlignmentMode = .bottom
        timerLabel.position = CGPoint(x: 0, y: self.size.height/2 - 50) //10px above bottom
        self.addChild(timerLabel)
        
        beginNextLevel()
    }
    
    func animateWin(){
        self.backgroundColor = GameConstants.winColor
        self.run(SKAction.colorize(
            with: GameConstants.backgroundColor,
            colorBlendFactor: 1,
            duration: 0.5))
    }
    
    func animateLoss(){
        self.backgroundColor = GameConstants.loseColor
        self.run(SKAction.colorize(
            with: GameConstants.backgroundColor,
            colorBlendFactor: 1,
            duration: 0.5))
    }
    
    
    func beginNextLevel(){
        
        contactsBegan = 0
        beginLevel(level: levels[levelIndex])
        levelIndex += 1
        if levelIndex >= levels.count {
            levelIndex = 0
        }
    }
    
    func beginLevel(level:GameLevel){
        
        if currentLevel?.parent != nil{
            currentLevel?.removeFromParent()
        }
        currentLevel = level
        self.addChild(currentLevel!)
        currentLevel!.zPosition = 0
        ballNode.position = currentLevel!.getInitialPosition()
        shouldRefreshTimeInterval = true
        
    }
    
    
    //contact functions
    func didBegin(_ contact: SKPhysicsContact) {
        
        if contact.bodyB.categoryBitMask == GameConstants.touchCategory &&
            contact.bodyA.categoryBitMask == GameLevelConstants.levelCategory {
            contactsBegan += 1
        }
        else if contact.bodyA.categoryBitMask == GameConstants.touchCategory &&
            contact.bodyB.categoryBitMask == GameLevelConstants.levelCategory {
            contactsBegan += 1
        }
    }
    func didEnd(_ contact: SKPhysicsContact) {
        if contact.bodyB.categoryBitMask == GameConstants.touchCategory &&
            contact.bodyA.categoryBitMask == GameLevelConstants.levelCategory {
            contactsBegan -= 1
        }
        else if contact.bodyA.categoryBitMask == GameConstants.touchCategory &&
            contact.bodyB.categoryBitMask == GameLevelConstants.levelCategory {
            contactsBegan -= 1
        }
    }
    
    //touch functions
    func touchDown(atPoint pos : CGPoint) {
        //the beginning of touch must start on the red ball
        if ballNode.frame.contains(pos) {
            //we picked up the ball. we can begin
            isTrackingBall = true
            lastTrackedPoint = pos
            if touchIndicator.intersects(currentLevel!) {
                ballNode.position = pos
            }
        }
        touchIndicator.position = pos
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        touchIndicator.position = pos
       
        let xDist = lastTrackedPoint.x - pos.x
        let yDist = lastTrackedPoint.y - pos.y
        let velocity = CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
        lastTrackedPoint = pos
        //&& velocity < GameConstants.maxVelocity
        if isTrackingBall {
            if contactsBegan > 0 {
                ballNode.position = pos
                //check if we've moved the ball into the final position
                if touchIndicator.frame.contains(currentLevel!.getFinalPosition()) {
                    //you won!
                    isTrackingBall = false
                    animateWin()
                    beginNextLevel()
                }
            } else {
                //you lost the ball
                contactsBegan = 0
                isTrackingBall = false
                animateLoss()
                ballNode.position = currentLevel!.getInitialPosition()
            }
        }

    }
    
    func touchUp(atPoint pos : CGPoint) {
        isTrackingBall = false
        contactsBegan = 0
        touchIndicator.position = CGPoint(x:-1000, y:-1000)//move touch offscreen to avoid physicsbody errors
        ballNode.position = currentLevel!.getInitialPosition()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if shouldRefreshTimeInterval {
            timeSinceCurrentLevel = currentTime
            shouldRefreshTimeInterval = false
        } else {
            timerLabel.text = String(format: "%.02f seconds on this level", currentTime - timeSinceCurrentLevel)
        }
    }
}
