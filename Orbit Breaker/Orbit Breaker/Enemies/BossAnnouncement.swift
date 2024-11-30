//
//  BossAnnouncement.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 11/29/24.
//
import SpriteKit

class BossAnnouncement {
    private weak var scene: SKScene?
    private var warningLabel: SKLabelNode?
    private var overlay: SKShapeNode?
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    func showAnnouncement(bossType: BossType, completion: @escaping () -> Void) {
        guard let scene = scene else { return }
        
        // Create dark overlay
        let overlay = SKShapeNode(rectOf: scene.size)
        overlay.fillColor = .black
        overlay.strokeColor = .clear
        overlay.alpha = 0
        overlay.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
        overlay.zPosition = 100
        scene.addChild(overlay)
        self.overlay = overlay
        
        // Create warning text
        let warningLabel = SKLabelNode(fontNamed: "Arial-Bold")
        warningLabel.text = "WARNING!"
        warningLabel.fontSize = 48
        warningLabel.fontColor = .red
        warningLabel.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2 + 40)
        warningLabel.alpha = 0
        warningLabel.zPosition = 101
        scene.addChild(warningLabel)
        
        // Create boss name text
        let bossNameLabel = SKLabelNode(fontNamed: "Arial-Bold")
        bossNameLabel.text = "\(String(describing: bossType).capitalized) Approaching"
        bossNameLabel.fontSize = 36
        bossNameLabel.fontColor = .white
        bossNameLabel.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2 - 20)
        bossNameLabel.alpha = 0
        bossNameLabel.zPosition = 101
        scene.addChild(bossNameLabel)
        
        // Flash effect for warning text
        let flashSequence = SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.3),
            SKAction.fadeAlpha(to: 0.3, duration: 0.3)
        ])
        
        // Overlay animation
        overlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.5),
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.run {
                overlay.removeFromParent()
                completion()
            }
        ]))
        
        // Warning label animation
        warningLabel.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.repeat(flashSequence, count: 3),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        // Boss name animation
        bossNameLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        // Add screen shake effect
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 10, y: 10, duration: 0.05),
            SKAction.moveBy(x: -20, y: -20, duration: 0.05),
            SKAction.moveBy(x: 20, y: 20, duration: 0.05),
            SKAction.moveBy(x: -10, y: -10, duration: 0.05)
        ])
        scene.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.repeat(shake, count: 2)
        ]))
    }
}

