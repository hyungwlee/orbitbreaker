//
//  OBPowerUps.swift
//  Orbit Breaker
//
//  Created by Thomas Rife on 11/4/24.
//

import SpriteKit

enum OBPowerUps: CaseIterable {
    case shield
    case doubleDamage
    
    func size(using layoutInfo: OBLayoutInfo) -> CGSize {
        switch self {
        case .shield:
            let baseSize = CGSize(width: 20, height: 25)
            return CGSize(
                width: baseSize.width * layoutInfo.screenScaleFactor,
                height: baseSize.height * layoutInfo.screenScaleFactor)
        case .doubleDamage:
            let baseSize = CGSize(width: 30, height: 30)
            return CGSize(
                width: baseSize.width * layoutInfo.screenScaleFactor,
                height: baseSize.height * layoutInfo.screenScaleFactor)
        }
    }
}

class OBPowerUp: SKSpriteNode {
    let type: OBPowerUps
    
    init(type: OBPowerUps, color: UIColor, layoutInfo: OBLayoutInfo) {
        self.type = type
        
        // Get the scaled size using layoutInfo
        let scaledSize = type.size(using: layoutInfo)
        
        // For double damage, create a custom node
        if type == .doubleDamage {
            let texture = SKTexture(imageNamed: "OBdoubleDamage")
            super.init(texture: texture, color: .white, size: scaledSize)
        } else {
            // Shield uses the sprite
            let texture = SKTexture(imageNamed: "OBshield")
            super.init(texture: texture, color: .white, size: scaledSize)
        }
        
        // Physics setup
        self.physicsBody = SKPhysicsBody(rectangleOf: scaledSize)
        self.physicsBody?.categoryBitMask = 0x1 << 1
        self.physicsBody?.contactTestBitMask = 0x1 << 2
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.affectedByGravity = false
        self.name = "OBpowerUp"
        
        // Add glow effect
        addGlowEffect()
        
        // Add animations
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        run(SKAction.repeatForever(pulseAction))
    }
    
    func playSoundEffect(named soundName: String) {
        OBSoundManager.shared.playSound(soundName)
    }
    
    private func addGlowEffect() {
        let glow = SKEffectNode()
        glow.shouldRasterize = true
        glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 5.0])
        
        let glowSprite = SKSpriteNode(texture: self.texture)
        glowSprite.color = getGlowColor()
        glowSprite.colorBlendFactor = 0.8
        glowSprite.alpha = 0.6
        glowSprite.size = CGSize(width: self.size.width * 1.5, height: self.size.height * 1.5)
        
        glow.addChild(glowSprite)
        addChild(glow)
    }
    
    private func getGlowColor() -> SKColor {
        switch type {
        case .shield: return .cyan
        case .doubleDamage: return .yellow
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func apply(to player: OBPlayer) {
        // Create pickup effect
        createPickupEffect()
        playSoundEffect(named: "OBpowerUp.mp3")
        switch type {
        case .shield:
            player.addShield()
            if let scene = scene as? OBGameScene {
                scene.powerUpManager.showPowerUp(.shield)
            }
        case .doubleDamage:
            player.setDoubleDamage()
            if let scene = scene as? OBGameScene {
                scene.powerUpManager.showPowerUp(.doubleDamage)
            }
        }
    }
    
    private func createPickupEffect() {
        guard let scene = self.scene else { return }
        
        let particleCount = 8
        let duration: TimeInterval = 0.3
        
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: 2)
            particle.fillColor = getGlowColor()
            particle.strokeColor = .white
            particle.position = position
            particle.zPosition = 3
            scene.addChild(particle)
            
            let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
            let distance: CGFloat = 30
            
            let endPoint = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            let moveAction = SKAction.move(to: endPoint, duration: duration)
            let fadeAction = SKAction.fadeOut(withDuration: duration)
            
            particle.run(SKAction.sequence([
                SKAction.group([moveAction, fadeAction]),
                SKAction.removeFromParent()
            ]))
        }
    }
}

