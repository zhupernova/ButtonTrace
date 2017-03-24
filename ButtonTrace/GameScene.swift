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

    static var ballRadius: CGFloat = 80
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
    
    private var world: SKShapeNode
    private var ballNode: SKShapeNode
    private var playButton: SKSpriteNode
    private var levels: [GameLevel]
    private var levelIndex: Int
    private var currentLevel: GameLevel?
    private var countdown: Int
    private var dustFrames: [SKTexture]
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
        world = SKShapeNode.init()
        timeSinceCurrentLevel = 0
        levelIndex = 0
        levels = []
        countdown = 3
        dustFrames = []
        super.init()

    }
    
    required init?(coder aDecoder: NSCoder) {
        isTrackingBall = false
        shouldRefreshTimeInterval = true
        animatingLoss = false
        ballNode = SKShapeNode.init(circleOfRadius: GameConstants.ballRadius)
        timerLabel = SKLabelNode(fontNamed: "TrebuchetMS")
        playButton = SKSpriteNode(imageNamed: "playbutton")
        world = SKShapeNode.init()
        timeSinceCurrentLevel = 0
        levelIndex = 0
        levels = []
        countdown = 3
        dustFrames = []
        super.init(coder: aDecoder)
    }
    
    override func didMove(to view: SKView) {
        if didRenderGame == nil {
            self.view?.isMultipleTouchEnabled = false
            let bg = SKSpriteNode.init(imageNamed: "background-jungle-light")
            bg.size = CGSize(width: self.size.width, height: self.size.height)
            bg.zPosition = -1
            self.addChild(bg)
            
            
            let targetWidth =  view.frame.size.width > 320 ?
                (self.size.width * 0.84).rounded() : 672
            let targetHeight = (targetWidth/9*16)
            GameLevelConstants.screenWidth = targetWidth
            GameLevelConstants.screenHeight = targetHeight
            GameConstants.ballRadius = targetHeight/14
            ballNode.fillColor = UIColor.clear
            ballNode.strokeColor = UIColor.clear
            let banana = SKSpriteNode.init(imageNamed: "banana")
            banana.size = CGSize(width: GameConstants.ballRadius*2, height: GameConstants.ballRadius*2)
            ballNode.addChild(banana)
            GameLevelConstants.levelDisplayWidth = GameConstants.ballRadius / 4 * 5
            GameLevelConstants.levelContactWidth = GameLevelConstants.levelDisplayWidth * 2
            didRenderGame? = true
            renderGame()
        }
    }
    
    func playSound(name: String){
        
        let floatDuration = name == "countdown.wav" ? 5 : 1
        let audioNode = SKAudioNode(fileNamed: name)
        audioNode.autoplayLooped = false
        self.addChild(audioNode)
        let playAction = SKAction.play()
        let waitAction = SKAction.wait(forDuration: TimeInterval(floatDuration))
        let removeAction = SKAction.removeFromParent()
        audioNode.run(SKAction.sequence(
            [SKAction.group([playAction, waitAction]),
             removeAction]))
    }
    
    func createGameLevels() {
        ballNode.position = CGPoint(x: -10000, y: -10000)
        addChild(ballNode)
        //start new course
        shouldRefreshTimeInterval = false
        levels = []
        //vertical, horizontal, circle, z, reverse L
        
        for _ in 0...4{
            levels.append(BallLevel())
        }
        levels.append(VLineLevel())
        for _ in 0...4{
            levels.append(BallLevel())
        }
        levels.append(HLineLevel())
        for _ in 0...4{
            levels.append(BallLevel())
        }
        levels.append(LetterZLevel())
        for _ in 0...4{
            levels.append(BallLevel())
        }
        levels.append(LReversedLevel())
        for _ in 0...4{
            levels.append(BallLevel())
        }
        levels.append(CounterCircleLevel())
        for _ in 0...4{
            levels.append(BallLevel())
        }
        
        reloadLevel()
    }
    
    func renderGame(){
        //the ball we're trying to track
        
        addChild(world)
        isTrackingBall = false
        ballNode.zPosition = 1
        
        let atlas = SKTextureAtlas(named: "dust")
        
        for i in 1...6{
            dustFrames.append(
                atlas.textureNamed(String(format: "dust%d", i))
            )
        }
        let bg = SKShapeNode(rect: CGRect(x: -self.size.width/6, y: self.size.height/2 - 80, width: self.size.width/3, height: 80), cornerRadius: 10)
        bg.fillColor = UIColor.init(white: 0.0, alpha: 0.8)
        let clock = SKSpriteNode(texture: SKTexture(imageNamed: "Time"))
        bg.addChild(clock)
        clock.position =  CGPoint(x: -self.size.width/6 + 40, y: self.size.height/2 - 60 + clock.size.height/2)
        addChild(bg)
        
        timerLabel.fontColor  = UIColor.white
        timerLabel.horizontalAlignmentMode = .left
        timerLabel.verticalAlignmentMode = .bottom
        timerLabel.position = CGPoint(x: -50, y: self.size.height/2 - 50) //50px below top
        
        addChild(timerLabel)
        
        playButton.size = CGSize(width:200, height:200)
        addChild(playButton)
    }
    
    func countdownGame(timer: Timer){
        
        
        let count  = SKLabelNode(fontNamed: "True Crimes")
        count.fontSize = 200
        count.fontColor = UIColor(red: 0.965, green: 0.388, blue: 0.188, alpha: 1)
        count.text = countdown > 0 ? String(format:"%d", countdown) : "GO!"

        count.position = CGPoint(x: -10.0, y: -10.0)
        count.zPosition = 100
        let shadow = count.copy() as! SKLabelNode
        shadow.fontColor = UIColor.black
        shadow.addChild(count)

        shadow.run(SKAction .group([
            SKAction.scale(by: 1.5, duration: 1),
            SKAction.fadeOut(withDuration: 1)
            ])){
            shadow.removeFromParent()
        }

        addChild(shadow)
        
        if countdown == 0 {
            self.createGameLevels()
            timer.invalidate()
            playSound(name: "countdown.wav")
        } else {
            playSound(name: "go.wav")
        }
        countdown -= 1
    }
    
    
    func animateWin(point: CGPoint){
        let dust = SKSpriteNode(texture: dustFrames[0])
        dust.position = point
        dust.size = CGSize(width: 80, height: 80)
        addChild(dust)
        dust.run(
            SKAction.sequence(
                [
                    SKAction.animate(with: dustFrames, timePerFrame: 0.1),
                    SKAction.removeFromParent()
                ]
            )
        )
    }
    
    func animateLoss(){
        self.backgroundColor = GameConstants.loseColor
        animatingLoss = true
        self.run(SKAction.colorize(
            with: GameConstants.backgroundColor,
            colorBlendFactor: 1,
            duration: 0.5))

        if currentLevel is ShapeLevel {
            ballNode.run(SKAction.sequence(
                [
                    SKAction.move(to: currentLevel!.getInitialPosition(), duration: 0.25),
                    SKAction.run {
                        self.animatingLoss = false
                    }
                ]
            ))
        } else {
            animatingLoss = false
        }
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
            isTrackingBall = false
            currentLevel?.removeFromParent()
            let count  = SKLabelNode(fontNamed:  "True Crimes")
            count.fontSize = 200
            count.fontColor = UIColor(red: 0.965, green: 0.388, blue: 0.188, alpha: 1)
            count.text =  "FINISH!"
            
            count.position = CGPoint(x: -10.0, y: -10.0)
            count.zPosition = 100
            let shadow = count.copy() as! SKLabelNode
            shadow.fontColor = UIColor.black
            shadow.addChild(count)
            
            ballNode.removeFromParent()
            addChild(shadow)
            playSound(name: "finish.wav")
            shadow.run(
                SKAction.fadeOut(withDuration: 2)
            ){
                self.playButton.position = CGPoint(x:0, y:0)
                shadow.removeFromParent()
            }
            
        }else {
            beginLevel(level: levels[levelIndex])
        }
    }
    
    func beginLevel(level:GameLevel){
        
        if currentLevel?.parent != nil{
            currentLevel?.removeFromParent()
        }
        currentLevel = level
        ballNode.position = currentLevel!.getInitialPosition()
        self.addChild(currentLevel!)
        currentLevel!.zPosition = 0
        
    }
    
    func testPoint(pos:CGPoint){
    
        let touchInfo = currentLevel!.getInfoForTouchPosition(position: pos)
        if touchInfo.shouldWin {
            //you won!
            
            if currentLevel is BallLevel {
                playSound(name: "button.wav")
            } else {
                playSound(name: "form.wav")
            }
            animateWin(point: pos)
            
            isTrackingBall = false
            beginNextLevel()
        }
        else if touchInfo.shouldLose {
            //you lost the ball
            playSound(name: "fail.wav")
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
            playButton.position = CGPoint(x:-10000, y:-10000)
            countdown = 3
            _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(GameScene.countdownGame), userInfo: nil, repeats: true)
            return
        }
        
        if shouldRefreshTimeInterval {
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
        if isTrackingBall {
            if currentLevel != nil {
                ballNode.position = currentLevel!.getInitialPosition()
            }
        }
        isTrackingBall = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches .count > 1 {
            return
        }
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches .count > 1 {
            return
        }
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches .count > 1 {
            return
        }
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches .count > 1 {
            return
        }
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if shouldRefreshTimeInterval {
            timeSinceCurrentLevel = currentTime
        }
        else {
            timerLabel.text = String(format: "%f", currentTime - timeSinceCurrentLevel)
        }
    }
}
