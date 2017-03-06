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

    static let ballRadius: CGFloat = 80
}
extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}
class GameScene: SKScene, SKPhysicsContactDelegate{
    
    var didRenderGame: Bool? //needed in case of app backgrounding, which may cause didMoveToView to execute again
    

    private var ballNode: SKShapeNode
    private var playButton: SKSpriteNode
    private var levels: [GameLevel]
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
        shouldRefreshTimeInterval = true
        animatingLoss = false
        ballNode = SKShapeNode.init(circleOfRadius: GameConstants.ballRadius)
        timerLabel = SKLabelNode(fontNamed: "TrebuchetMS")
        playButton = SKSpriteNode(imageNamed: "playbutton")
        timeSinceCurrentLevel = 0
        levelIndex = 0
        levels = []
        super.init()

    }
    
    required init?(coder aDecoder: NSCoder) {
        isTrackingBall = false
        shouldRefreshTimeInterval = true
        animatingLoss = false
        ballNode = SKShapeNode.init(circleOfRadius: GameConstants.ballRadius)
        timerLabel = SKLabelNode(fontNamed: "TrebuchetMS")
        playButton = SKSpriteNode(imageNamed: "playbutton")
        timeSinceCurrentLevel = 0
        levelIndex = 0
        levels = []
        super.init(coder: aDecoder)
    }
    
    
    
    override func didMove(to view: SKView) {
        if didRenderGame == nil {
            didRenderGame? = true
            renderGame()
        }
    }
    
    func createGameLevels() {
        //start new course
        playButton.position = CGPoint(x:-1000, y:-1000)
        shouldRefreshTimeInterval = false
        levels = []
        //vertical, horizontal, circle, z, reverse L
        let formsCount = arc4random_uniform(3) + 1
        for _ in 1...formsCount{
            switch arc4random_uniform(5)
            {
            case 0:
                levels.append(VLineLevel())
                break
            case 1:
                levels.append(HLineLevel())
                break
            case 2:
                levels.append(LetterZLevel())
                break
            case 3:
                levels.append(LReversedLevel())
                break
            case 4:
                levels.append(CounterCircleLevel())
                break
            default:
            break
            }
        }
        for _ in 0...10{
            levels.append(BallLevel())
        }
        levels.shuffle()
        
        
        reloadLevel()
    }
    
    func renderGame(){
        //the ball we're trying to track
        isTrackingBall = false
        ballNode.fillColor = UIColor.red
        ballNode.zPosition = 1
        ballNode.position = CGPoint(x: -1000, y: -1000)
        self.addChild(ballNode)
        
        
        timerLabel.fontColor  = UIColor.black
        timerLabel.verticalAlignmentMode = .bottom
        timerLabel.position = CGPoint(x: 0, y: self.size.height/2 - 50) //50px below top
        self.addChild(timerLabel)
        
        
        playButton.size = CGSize(width:200, height:200)
        addChild(playButton)
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
            shouldRefreshTimeInterval = true
            //createGameLevels()
            currentLevel?.removeFromParent()
            playButton.position = CGPoint(x:0, y:0)
        }else {
            beginLevel(level: levels[levelIndex])
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
        
    }
    
    func testPoint(pos:CGPoint){
    
        let touchInfo = currentLevel!.getInfoForTouchPosition(position: pos)
        if touchInfo.shouldWin {
            //you won!
            isTrackingBall = false
            animateWin()
            beginNextLevel()
        }
        else if touchInfo.shouldLose {
            //you lost the ball
            isTrackingBall = false
            animateLoss()
        }
        else {
            ballNode.position = touchInfo.ballPosition
        }
    }
    
    //touch functions
    func touchDown(atPoint pos : CGPoint) {
        //the beginning of touch must start on the red ball
        if playButton.contains(pos) {
            createGameLevels()
            return
        }
        
        
        if currentLevel is BallLevel {
            testPoint(pos:pos)
        }
        if !animatingLoss && ballNode.contains(pos) {
            //we picked up the ball. we can begin

            isTrackingBall = true
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if isTrackingBall {
            testPoint(pos:pos)

        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        isTrackingBall = false
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
        }
        else {
            timerLabel.text = String(format: "%f seconds on this tour", currentTime - timeSinceCurrentLevel)
        }
    }
}
