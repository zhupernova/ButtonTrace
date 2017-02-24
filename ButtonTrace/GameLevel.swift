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

struct Constants {
    static let levelWidth:CGFloat = 300
    static let levelHeight:CGFloat = 550
    static let levelLineWidth:CGFloat = 23
    static let defaultColor:UIColor = UIColor.init(red:225.0, green:222.0, blue:217.0, alpha:1.0)
    static let backgroundColor:UIColor = UIColor.init(red:242.0, green:241.0, blue:246.0, alpha:1.0)
}



class GameLevel:SKShapeNode{
    var joints:[CGPoint]
    //array of points to draw the level. joints should be ordered
    override init() {
        self.joints = []
        super.init()
        self.name = "My Node!"
        self.joints = self.getJoints()
        self.lineWidth = Constants.levelLineWidth
        self.strokeColor = Constants.defaultColor
        self.fillColor = Constants.defaultColor
        self.lineCap = .round
        
        render()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.joints = []
        super.init(coder:aDecoder)
        self.joints = self.getJoints()
    }
    func getJoints()->[CGPoint]{
        return []
    }
    func render() {
        NSLog("rendering")
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

class LineLevel:GameLevel{
    override func getJoints()->[CGPoint]{
        //reminder: game coordinate is bottom-up
        return [CGPoint(x:Constants.levelWidth/2, y:0),
                CGPoint(x:Constants.levelWidth/2, y:Constants.levelHeight)]
    }
}
