//
//  GameScene.swift
//  Jumper
//
//  Created by Developer on 5/24/17.
//  Copyright © 2017 JwitApps. All rights reserved.
//

import GameController
import GameplayKit
import SpriteKit

struct Pad {
    let location: CGPoint
    let node: SKNode
}

class GameScene: SKScene {
    
    var controller: GCController?
    
    // relative to pad layer
    var playerRestingPosition: CGPoint?

    func controllerDidConnect(notification : NSNotification) {
        controller = GCController.controllers().first
        controller?.motion?.valueChangedHandler = { motion in
            
            self.player.physicsBody?.applyImpulse(CGVector(dx: -10*motion.gravity.y, dy: 0))
        }
    }
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        
        let camera = SKCameraNode()
        scene.camera = camera
        camera.zPosition = 1000
        scene.addChild(camera)
        
        scene.physicsWorld.contactDelegate = scene
        
        return scene
    }
    
    lazy var player: SKShapeNode = {
        let node = SKShapeNode(circleOfRadius: 30)
        node.fillColor = .red
        node.strokeColor = .clear
        
        let body = SKPhysicsBody(circleOfRadius: 30)
        body.categoryBitMask = 1
        body.collisionBitMask = 0
        body.contactTestBitMask = 2
        body.mass = 1
        node.physicsBody = body
        
        return node
    }()
    
    lazy var padLayer: SKNode = {
        let node = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
        node.fillColor = .green
        return node
    }()
    
    var pads = [Pad]()
    
    var readyToJump = true
    
    func setUpScene() {

        player.position = CGPoint(x: 0, y: 280)
        addChild(player)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: 1))
        body.velocity = CGVector(dx: 0, dy: -40)

        body.collisionBitMask = 0
        body.friction = 0
        body.linearDamping = 0
        body.affectedByGravity = false
        padLayer.physicsBody = body
        
        generate(8, padsIn: padLayer)
        
        addChild(padLayer)
    }
    
    func generate(_ quantity: Int, padsIn parent: SKNode) {
        var lastPadLocation: CGPoint? { return pads.last?.location }
        
        for _ in 0..<quantity {
            let spreadRadius: CGFloat = 150
            
            var x = lastPadLocation?.x ?? 0 - spreadRadius
            x = x < 0 ? 0 : x
            x = x > self.scene!.size.width/2 ? self.scene!.size.width/2 : x
            
            let randomizer = GKRandomDistribution(
                lowestValue: Int(x - spreadRadius),
                highestValue: Int(x + spreadRadius))
            
            let pad = createPad()
            pad.position = CGPoint(x: randomizer.nextInt(), y: Int(lastPadLocation?.y ?? 0) + 150)
            
            pads.append(Pad(location: pad.position, node: pad))
            
            parent.addChild(pad)
        }
    }
   
    override func didMove(to view: SKView) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(GameScene.controllerDidConnect(notification:)),
            name: NSNotification.Name.GCControllerDidConnect,
            object: nil)
        
        setUpScene()
    }
    
    override func update(_ currentTime: TimeInterval) {
        checkExpiredPads()
        
        checkGameOver()
    }
    
    override func didSimulatePhysics() {
        pads.forEach { $0.node.position = $0.location }
        
        if let playerRestingPosition = playerRestingPosition {
            
            player.position = player.parent!.convert(playerRestingPosition, from: padLayer)
            
        }
    }
    
    private func checkExpiredPads() {
        if let pad = pads.first {
            if self.scene!.convert(pad.node.position, from: pad.node.parent!).y < -self.scene!.size.height/2 {
                
                pad.node.removeFromParent()
                pads.removeFirst()
                print("removed")
                
                generate(1, padsIn: padLayer)
            }
        }
    }
    
    private func checkGameOver() {
        guard let scene = self.scene else { return }
        guard let playerParent = player.parent else { return }
        
        if scene.convert(player.position, from: playerParent).y < -scene.size.height/2 {
            
            let gameOver = SKShapeNode(rectOf: CGSize(width: 300, height: 200))
            gameOver.fillColor = .lightGray
            self.camera?.addChild(gameOver)
        }
    }
    
    private func createPad() -> SKSpriteNode {
        print("pad created")
        
        let node = SKSpriteNode(color: .blue, size: CGSize(width: 200, height: 20))
        
        let body = SKPhysicsBody(rectangleOf: node.size)
        body.categoryBitMask = 2
        body.collisionBitMask = 0
        body.contactTestBitMask = 1
        body.affectedByGravity = false
        body.mass = 100000000
        node.physicsBody = body
        
        return node
    }
}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        if (bodyA.categoryBitMask == 1 && bodyB.categoryBitMask == 2) ||
            bodyA.categoryBitMask == 2 && bodyB.categoryBitMask == 1 {
            
            if contact.contactNormal.dy > 0 {
                
                player.physicsBody?.velocity = .zero
                
                playerRestingPosition = padLayer.convert(player.position, from: player.parent!)
            }
        }
    }
    
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            if readyToJump || true {
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 600))
                readyToJump = false
                playerRestingPosition = nil
            }
        }
    }
}
#endif
