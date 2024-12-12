//
//  VisualEffects.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 11/29/24.
//

import SpriteKit

class VisualEffects {
    static func addExplosion(at position: CGPoint, in scene: SKScene) {
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
            
            particle.run(SKAction.sequence([
                group,
                SKAction.removeFromParent()
            ]))
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
        // Add explosion and screen shake
        addExplosion(at: position, in: scene)
        addScreenShake(to: scene, intensity: 15)
        
        // Time dilation effect
        scene.physicsWorld.speed = 0.5
        
        // Call completion after effects are done
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            scene.physicsWorld.speed = 1.0
            completion()
        }
    }
}
