//
//  OBBossAnnouncement.swift
//  Orbit Breaker
//
//  Created by Michelle Bai on 12/20/24.
//

import SpriteKit

class OBBossAnnouncement {
    private weak var scene: SKScene?
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    func playSoundEffect(named soundName: String) {
        OBSoundManager.shared.playSound(soundName)
    }
    
    
    func showAnnouncement(bossType: OBBossType, completion: @escaping () -> Void) {
        guard let scene = scene else { return }
        
        playSoundEffect(named: "OBannouncementSound.mp3") // Replace with your sound file name
        
        // Create container node for centering and scaling
        let container = SKNode()
        container.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
        container.zPosition = 100
        scene.addChild(container)
        
        // Create background vignette
        let vignette = SKShapeNode(rectOf: CGSize(width: scene.size.width, height: scene.size.height))
        vignette.fillColor = .black
        vignette.strokeColor = .clear
        vignette.alpha = 0
        vignette.position = .zero
        container.addChild(vignette)
        
        // Create dramatic slash effect nodes with glow
        let slashContainer = SKNode()
        container.addChild(slashContainer)
        
        // Function to create a glowing slash
        func createGlowingSlash(width: CGFloat, position: CGPoint) -> SKNode {
            let slashNode = SKNode()
            
            // Main slash
            let slash = SKShapeNode(rectOf: CGSize(width: width, height: 4))
            slash.fillColor = getBossColor(for: bossType)
            slash.strokeColor = .clear
            
            // Glow effect
            let glowEffect = SKEffectNode()
            glowEffect.shouldRasterize = true
            glowEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 3.0])
            
            let glowSlash = SKShapeNode(rectOf: CGSize(width: width, height: 6))
            glowSlash.fillColor = getBossColor(for: bossType)
            glowSlash.strokeColor = .clear
            glowEffect.addChild(glowSlash)
            
            slashNode.addChild(glowEffect)
            slashNode.addChild(slash)
            slashNode.position = position
            slashNode.alpha = 0
            
            return slashNode
        }
        
        // Create slashes with glow
        let leftSlash = createGlowingSlash(width: scene.size.width * 0.8,
                                           position: CGPoint(x: -scene.size.width/2, y: 30))
        let rightSlash = createGlowingSlash(width: scene.size.width * 0.8,
                                            position: CGPoint(x: scene.size.width/2, y: -30))
        
        slashContainer.addChild(leftSlash)
        slashContainer.addChild(rightSlash)
        
        // Create warning text with background
        let warningBackground = SKShapeNode(rectOf: CGSize(width: 240, height: 60))
        warningBackground.fillColor = SKColor(white: 0.1, alpha: 1.0)
        warningBackground.strokeColor = getBossColor(for: bossType)
        warningBackground.lineWidth = 4
        warningBackground.alpha = 0
        container.addChild(warningBackground)
        
        // Warning label with shadow
        let warningLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        warningLabel.text = "WARNING"
        warningLabel.fontSize = 34
        warningLabel.fontColor = getBossColor(for: bossType)
        warningLabel.position = CGPoint(x: 0, y: -13)
        warningLabel.alpha = 0
        
        let warningShadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        warningShadow.text = warningLabel.text
        warningShadow.fontSize = warningLabel.fontSize
        warningShadow.fontColor = .black
        warningShadow.position = CGPoint(x: 2, y: -2)
        warningShadow.zPosition = -1
        warningLabel.addChild(warningShadow)
        
        warningBackground.addChild(warningLabel)
        
        // Create boss name text with background
        let nameLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        nameLabel.text = "\(String(describing: bossType).uppercased()) APPROACHING"
        nameLabel.fontSize = 32
        nameLabel.fontColor = .white
        
        
        // Resize font based on screen size
        let maxWidth = scene.size.width * 0.8 // Allow some padding
        while nameLabel.frame.width > maxWidth {
            nameLabel.fontSize -= 1 // Reduce font size until it fits
        }
        
        // Calculate background size based on text
        let textWidth = nameLabel.frame.width
        let backgroundWidth = textWidth + 80
        
        let nameBackground = SKShapeNode(rectOf: CGSize(width: backgroundWidth, height: 60))
        nameBackground.fillColor = getBossColor(for: bossType)
        nameBackground.strokeColor = .white
        nameBackground.lineWidth = 3
        nameBackground.position = CGPoint(x: 0, y: -70)
        nameBackground.alpha = 0
        container.addChild(nameBackground)
        
        // Add shadow to name label
        let nameShadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        nameShadow.text = nameLabel.text
        nameShadow.fontSize = nameLabel.fontSize
        nameShadow.fontColor = .black
        nameShadow.position = CGPoint(x: 2, y: -2)
        nameShadow.zPosition = -1
        nameLabel.addChild(nameShadow)
        
        nameLabel.position = CGPoint(x: 0, y: -82)
        nameLabel.alpha = 0
        container.addChild(nameLabel)
        
        // Enhanced animations
        let vignetteAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 0.3)
        ])
        
        let slashAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.2),
                SKAction.moveBy(x: scene.size.width * 1.6, y: 0, duration: 0.4)
            ])
        ])
        
        let warningAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.scale(to: 1.1, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
        ])
        
        let nameAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.scale(to: 1.1, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
        ])
        
        // Enhanced screen shake
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 12, y: 12, duration: 0.05),
            SKAction.moveBy(x: -24, y: -24, duration: 0.05),
            SKAction.moveBy(x: 24, y: 24, duration: 0.05),
            SKAction.moveBy(x: -12, y: -12, duration: 0.05)
        ])
        
        // Run animations
        vignette.run(vignetteAction)
        leftSlash.run(slashAction)
        rightSlash.run(slashAction)
        warningBackground.run(warningAction)
        warningLabel.run(warningAction)
        nameBackground.run(nameAction)
        nameLabel.run(nameAction)
        
        // Add subtle pulsing to the warning text
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        warningLabel.run(SKAction.repeatForever(pulse))
        
        scene.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            shake,
            SKAction.wait(forDuration: 2.0),
            SKAction.run {
                container.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.removeFromParent(),
                    SKAction.run {
                        completion()
                    }
                ]))
            }
        ]))
    }
    
    private func getBossColor(for bossType: OBBossType) -> SKColor {
        switch bossType {
        case .anger:
            return SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        case .sadness:
            return SKColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0)
        case .disgust:
            return SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
        case .love:
            return SKColor(red: 0.9, green: 0.2, blue: 0.5, alpha: 1.0)
        }
    }
}
