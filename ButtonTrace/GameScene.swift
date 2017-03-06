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
    static let touchRadius: CGFloat = 50
    static let ballRadius: CGFloat = 70
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
    
    //timer display
    private var shouldRefreshTimeInterval: Bool
    private var timerLabel: SKLabelNode
    private var timeSinceCurrentLevel: TimeInterval
    private var animatingLoss: Bool
    
    override init(){
        isTrackingBall = false
        shouldRefreshTimeInterval  = false
        animatingLoss = false
        touchIndicator = SKShapeNode.init(circleOfRadius: GameConstants.touchRadius)
        ballNode = SKShapeNode.init(circleOfRadius: GameConstants.ballRadius)
        timerLabel = SKLabelNode(fontNamed: "TrebuchetMS")
        timeSinceCurrentLevel = 0
        levelIndex = 0
        levels = [LetterZLevel(),  HLineLevel(), VLineLevel(), LReversedLevel(), CounterCircleLevel()]
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        isTrackingBall = false
        shouldRefreshTimeInterval  = false
        animatingLoss = false
        touchIndicator = SKShapeNode.init(circleOfRadius: GameConstants.touchRadius)
        ballNode = SKShapeNode.init(circleOfRadius: GameConstants.ballRadius)
        timerLabel = SKLabelNode(fontNamed: "TrebuchetMS")
        timeSinceCurrentLevel = 0
        levelIndex = 0
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
        touchIndicator.fillColor = UIColor.clear
        touchIndicator.strokeColor = UIColor.clear
        touchIndicator.zPosition = 2
        touchIndicator.position = CGPoint(x: -1000, y: -1000)
        self.addChild(touchIndicator)
        
        //the ball we're trying to track
        isTrackingBall = false
        ballNode.fillColor = UIColor.red
        ballNode.zPosition = 1
        self.addChild(ballNode)
        
        timerLabel.fontColor  = UIColor.black
        timerLabel.verticalAlignmentMode = .bottom
        timerLabel.position = CGPoint(x: 0, y: self.size.height/2 - 50) //50px below top
        self.addChild(timerLabel)
        
        reloadLevel()
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
        animatingLoss = true
        self.run(SKAction.colorize(
            with: GameConstants.backgroundColor,
            colorBlendFactor: 1,
            duration: 0.5))

        ballNode.run(SKAction.sequence(
            [
                SKAction.move(to: currentLevel!.getInitialPosition(), duration: 0.25),
                SKAction.run {
                    self.animatingLoss = false
                }
            ]
        ))
    }
    
    func reloadLevel(){
        beginLevel(level: levels[levelIndex])
    }
    
    func beginNextLevel(){
        levelIndex += 1
        if levelIndex >= levels.count {
            levelIndex = 0
        }
        beginLevel(level: levels[levelIndex])
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
    
    

    
    //touch functions
    func touchDown(atPoint pos : CGPoint) {
        
        
        //the beginning of touch must start on the red ball
        if !animatingLoss && ballNode.frame.contains(pos) {
            //we picked up the ball. we can begin
            isTrackingBall = true
            if touchIndicator.intersects(currentLevel!) {
                ballNode.position = pos
            }
        }
        touchIndicator.position = pos
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        touchIndicator.position = pos
        if isTrackingBall {
            let contactInfo = currentLevel!.getContactInfo(point: pos)
            if contactInfo.isTouching {
                ballNode.position = contactInfo.railPoint
                //check if we've moved the ball into the final position
                let rect = currentLevel!.getFinalHitbox()
                if rect.contains(CGPoint(x:pos.x, y:-pos.y)){
                //if ballNode.frame.intersects(currentLevel!.getFinalHitbox()) {
                //if ballNode.frame.contains(currentLevel!.getFinalPosition()) {
                    //you won!
                    isTrackingBall = false
                    animateWin()
                    beginNextLevel()
                }
            } else {
                //you lost the ball
                isTrackingBall = false
                animateLoss()
            }
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        isTrackingBall = false
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
        }
    }
}
