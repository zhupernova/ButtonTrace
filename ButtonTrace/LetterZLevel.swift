//
//  LetterZLevel.swift
//  ButtonTrace
//
//  Created by Zhuping Hu on 3/6/17.
//  Copyright © 2017 Zhuping Hu. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit

class LetterZLevel: ShapeLevel{
    override func setSize(){
        // sets size of the object
        contactWidth = GameLevelConstants.screenWidth
        contactHeight = GameLevelConstants.screenWidth
        displayWidth = contactWidth - GameLevelConstants.levelContactWidth/2
        displayHeight = contactHeight - GameLevelConstants.levelContactWidth/2
    }
    
    override func getFinalHitbox()->CGRect{
        
        return CGRect(
            x: self.contactWidth/2-GameLevelConstants.endRailInset - GameLevelConstants.levelContactWidth/2,
            y: -(-self.contactHeight/2+GameLevelConstants.levelContactWidth),
            width: GameLevelConstants.levelContactWidth + GameLevelConstants.endRailInset,
            height: GameLevelConstants.levelContactWidth)
    }
    
    override func getCorners(width:CGFloat, height:CGFloat, bandWidth:CGFloat)->[[CGPoint]]{
        let cornerWidth = sqrt((bandWidth*bandWidth)*2)
        return [
            [//top piece
                CGPoint(x: -width/2, y: height/2), //top left
                CGPoint(x: width/2, y: height/2), //top right
                CGPoint(
                    x: width/2 - cornerWidth,
                    y: height/2 - bandWidth), //bottom right
                CGPoint(
                    x: -width/2,
                    y: height/2  - bandWidth) //bottom left
            ],
            [//slanted piece
                CGPoint( //top left
                    x: width/2 - cornerWidth,
                    y: height/2),
                
                CGPoint(//bottom left
                    x: -width/2,
                    y: -height/2),
                
                CGPoint(//bottom right
                    x: -width/2 + cornerWidth,
                    y: -height/2),
                
                CGPoint(//top right
                    x: width/2,
                    y: height/2)
            ],
            [//bottom piece
                CGPoint(x: -width/2, y: -height/2), //bottom left
                CGPoint(x: width/2, y: -height/2), //bottom right
                CGPoint(
                    x: width/2,
                    y: -height/2 + bandWidth), //top right
                CGPoint(
                    x: -width/2 + cornerWidth,
                    y: -height/2  + bandWidth) //top left
            ]
        ]
    }
    
    override func getRails() -> [CGLineSegment] {
        //let cornerWidth = sqrt((bandWidth/2*bandWidth/2)*2)
        let lineA =
            CGLineSegment(
                a: CGPoint(
                    x: -self.contactWidth/2 + GameLevelConstants.startRailInset,
                    y: (self.contactHeight - GameLevelConstants.levelContactWidth)/2),
                b: CGPoint(
                    x: self.contactWidth/2 - (GameLevelConstants.levelContactWidth/4*3),
                    y: (self.contactHeight - GameLevelConstants.levelContactWidth)/2))
        
        let lineB =
            CGLineSegment(
                a: CGPoint(
                    x: self.contactWidth/2-(GameLevelConstants.levelContactWidth/4*3),
                    y: (self.contactHeight - GameLevelConstants.levelContactWidth)/2),
                b: CGPoint(
                    x: -self.contactWidth/2 + (GameLevelConstants.levelContactWidth/4*3),
                    y: (-self.contactHeight+GameLevelConstants.levelContactWidth)/2))
        
        let lineC =
            
            CGLineSegment(
                a: CGPoint(
                    x: -self.contactWidth/2 + (GameLevelConstants.levelContactWidth/4*3),
                    y: (-self.contactHeight+GameLevelConstants.levelContactWidth)/2),
                b: CGPoint(
                    x: self.contactWidth/2-GameLevelConstants.endRailInset - GameLevelConstants.levelContactWidth/2,
                    y: (-self.contactHeight+GameLevelConstants.levelContactWidth)/2))
        
        
        return [
            //top piece,
            lineA,
            //slanted piece
            lineB,
            //bottom piece
            lineC
        ]
    }
}
