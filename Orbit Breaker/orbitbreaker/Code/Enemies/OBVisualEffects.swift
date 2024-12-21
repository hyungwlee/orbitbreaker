//
//  OBVisualEffects.swift
//  Orbit Breaker
//
//  Created by Michelle Bai on 12/20/24.
//

import SpriteKit

class OBVisualEffects {
    static func addExplosion(at position: CGPoint, in scene: SKScene) {
        // Basic enemy explosion
        let particleCount = 20
        let duration: TimeInterval = 0.5
        
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: 2)
            particle.fillColor = .yellow
            particle.strokeColor = .orange
            particle.glowWidth = 2
            particle.position = position
            particle.zPosition = 3
            scene.addChild(particle)
            
            let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
            let speed = CGFloat.random(in: 50...150)
            
            let distance = speed * CGFloat(duration)
            let endPosition = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            let moveAction = SKAction.move(to: endPosition, duration: duration)
            let fadeAction = SKAction.fadeOut(withDuration: duration)
            let scaleAction = SKAction.scale(by: 0.1, duration: duration)
            let group = SKAction.group([moveAction, fadeAction, scaleAction])
            
            particle.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }
    }
    
    static func addScreenShake(to scene: SKScene, intensity: CGFloat = 10) {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: intensity, y: intensity, duration: 0.05),
            SKAction.moveBy(x: -intensity * 2, y: -intensity * 2, duration: 0.05),
            SKAction.moveBy(x: intensity * 2, y: intensity * 2, duration: 0.05),
            SKAction.moveBy(x: -intensity, y: -intensity, duration: 0.05)
        ])
        scene.run(shake)
    }
    
    static func addPlayerDeathEffect(at position: CGPoint, in scene: SKScene, completion: @escaping () -> Void) {
        // Add enhanced explosion for player death
        let particleCount = 30
        let duration: TimeInterval = 0.8
        
        // Create expanding ring
        let ring = SKShapeNode(circleOfRadius: 1)
        ring.strokeColor = .white
        ring.glowWidth = 4
        ring.lineWidth = 2
        ring.position = position
        ring.zPosition = 3
        scene.addChild(ring)
        
        let expandRing = SKAction.group([
            SKAction.scale(to: 40, duration: duration * 0.5),
            SKAction.fadeOut(withDuration: duration * 0.5)
        ])
        ring.run(SKAction.sequence([expandRing, SKAction.removeFromParent()]))
        
        // Core particles
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: 3)
            particle.fillColor = .white
            particle.strokeColor = .yellow
            particle.glowWidth = 3
            particle.position = position
            particle.zPosition = 4
            scene.addChild(particle)
            
            let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
            let speed = CGFloat.random(in: 100...250)
            let distance = speed * CGFloat(duration)
            
            // Add curved path for more dynamic movement
            let controlPoint = CGPoint(
                x: position.x + cos(angle + .pi/4) * distance * 0.5,
                y: position.y + sin(angle + .pi/4) * distance * 0.5
            )
            
            let path = CGMutablePath()
            path.move(to: position)
            path.addQuadCurve(to: CGPoint(x: position.x + cos(angle) * distance,
                                          y: position.y + sin(angle) * distance),
                              control: controlPoint)
            
            let followPath = SKAction.follow(path, asOffset: false, orientToPath: true, duration: duration)
            let fadeAction = SKAction.sequence([
                SKAction.wait(forDuration: duration * 0.3),
                SKAction.fadeOut(withDuration: duration * 0.7)
            ])
            let scaleAction = SKAction.sequence([
                SKAction.scale(to: 2, duration: duration * 0.2),
                SKAction.scale(to: 0, duration: duration * 0.8)
            ])
            
            particle.run(SKAction.sequence([
                SKAction.group([followPath, fadeAction, scaleAction]),
                SKAction.removeFromParent()
            ]))
        }
        
        // Add screen shake and time dilation
        addScreenShake(to: scene, intensity: 15)
        scene.physicsWorld.speed = 0.5
        
        // Call completion after effects are done
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            scene.physicsWorld.speed = 1.0
            completion()
        }
    }
}
