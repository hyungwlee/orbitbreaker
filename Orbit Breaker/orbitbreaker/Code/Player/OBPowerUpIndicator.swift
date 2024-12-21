//
//  OBPowerUpIndicator.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 11/30/24.
//
import SpriteKit

class OBPowerUpIndicator: SKNode {
    private let backgroundNode: SKShapeNode
    private let iconNode: SKSpriteNode
    private let textNode: SKLabelNode
    private let progressRing: SKShapeNode
    private var powerUpType: OBPowerUps?
    private var duration: TimeInterval = 5.0
    private var startTime: TimeInterval = 0
    private var glowNode: SKEffectNode?
    private var sizeChanged = false
    var layoutInfo: OBLayoutInfo
    
    init(size: CGFloat, layoutInfo: OBLayoutInfo) {
        self.layoutInfo = layoutInfo
        // Create rounded background using SKShapeNode
        backgroundNode = SKShapeNode(circleOfRadius: size/2 * layoutInfo.screenScaleFactor)
        backgroundNode.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.9)
        backgroundNode.strokeColor = .clear
        
        // Create progress ring with space theme
        progressRing = SKShapeNode(circleOfRadius: size/2 - 2 * layoutInfo.screenScaleFactor)
        progressRing.strokeColor = .clear
        progressRing.fillColor = .clear
        progressRing.lineWidth = 3
        progressRing.lineCap = .round
        
        // Create icon node with thinner width for shield
        iconNode = SKSpriteNode(color: .clear, size: CGSize(width: size * 0.3, height: size * 0.4))
        
        // Create text node for X2
        textNode = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        textNode.fontSize = size * 0.35 * layoutInfo.screenScaleFactor
        textNode.verticalAlignmentMode = .center
        textNode.horizontalAlignmentMode = .center
        textNode.fontColor = .white
        
        super.init()
        
        // Create metallic border effect
        let border = SKShapeNode(circleOfRadius: size/2 * layoutInfo.screenScaleFactor)
        border.strokeColor = .white
        border.lineWidth = 2
        border.glowWidth = 1
        addChild(border)
        
        addChild(backgroundNode)
        addChild(progressRing)
        addChild(iconNode)
        addChild(textNode)
        
        // Add glow effect node
        let glow = SKEffectNode()
        glow.shouldRasterize = true
        glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 3.0])
        glow.alpha = 0.6
        addChild(glow)
        glowNode = glow
        
        isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showPowerUp(_ type: OBPowerUps) {
        self.powerUpType = type
        self.startTime = 0
        
        switch type {
        case .shield:
            self.duration = 10.0
            iconNode.texture = SKTexture(imageNamed: "shield")
            textNode.text = ""
            progressRing.strokeColor = SKColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0)
            if let shieldGlow = iconNode.copy() as? SKSpriteNode {
                shieldGlow.alpha = 0.6
                glowNode?.addChild(shieldGlow)
            }
            
        case .doubleDamage:
            self.duration = 5.0
            iconNode.texture = SKTexture(imageNamed: "doubleDamage")
            textNode.text = ""
            if sizeChanged == false {
                iconNode.size = CGSize(width: iconNode.size.width * 1.7 * layoutInfo.screenScaleFactor, height: iconNode.size.height * 1.3 * layoutInfo.screenScaleFactor)
                sizeChanged = true
            }
        
            progressRing.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
        }
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        
        if type == .shield {
            iconNode.run(SKAction.repeatForever(pulse))
        } else {
            textNode.run(SKAction.repeatForever(pulse))
        }
        
        isHidden = false
    }
    
    func update(currentTime: TimeInterval) {
        guard let _ = powerUpType, !isHidden else { return }
        
        if startTime == 0 {
            startTime = currentTime
        }
        
        let elapsed = currentTime - startTime
        let remaining = max(0, duration - elapsed)
        let progress = remaining / duration
        
        // Create smooth progress arc
        let radius = backgroundNode.frame.width / 2 - 2
        let path = UIBezierPath()
        let startAngle: CGFloat = -.pi / 2
        let endAngle = startAngle + (.pi * 2 * progress)
        path.addArc(withCenter: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        progressRing.path = path.cgPath
        
        // Update glow intensity based on remaining time
        glowNode?.alpha = 0.6 * progress
        
        if remaining <= 0 {
            isHidden = true
            powerUpType = nil
        }
    }
    
    func hideIfShield() {
        if powerUpType == .shield {
            isHidden = true
            powerUpType = nil
        }
    }
}

class OBPowerUpManager {
    private var indicators: [OBPowerUpIndicator] = []
    private var droppedPowerUps: [OBPowerUp] = []
    private weak var scene: SKScene?
    var layoutInfo: OBLayoutInfo
    
    init(scene: SKScene, layoutInfo: OBLayoutInfo) {
        self.scene = scene
        self.layoutInfo = layoutInfo
        setupIndicators()
    }
    
    private func setupIndicators() {
        guard let scene = scene else { return }
        
        let size: CGFloat = 80 * layoutInfo.screenScaleFactor  // Back to original size
        let spacing: CGFloat = 10 * layoutInfo.screenScaleFactor
        let leftMargin: CGFloat = 15 * layoutInfo.screenScaleFactor
        let bottomMargin: CGFloat = 20 * layoutInfo.screenScaleFactor
        
        let orderedPowerUps = [OBPowerUps.shield, OBPowerUps.doubleDamage]
        
        for (index, type) in orderedPowerUps.enumerated() {
            let indicator = OBPowerUpIndicator(size: size, layoutInfo: layoutInfo)
            let xPosition = leftMargin + (size / 2) + (CGFloat(index) * (size + spacing))
            
            indicator.position = CGPoint(
                x: xPosition,
                y: size/2 + bottomMargin
            )
            
            scene.addChild(indicator)
            indicators.append(indicator)
        }
    }
    
    func trackDroppedPowerUp(_ powerUp: OBPowerUp) {
        droppedPowerUps.append(powerUp)
    }
    
    func cleanup() {
        // Remove all indicators
        indicators.forEach { $0.removeFromParent() }
        indicators.removeAll()
        
        // Remove all dropped power-ups
        droppedPowerUps.forEach { $0.removeFromParent() }
        droppedPowerUps.removeAll()
    }
    
    func showPowerUp(_ type: OBPowerUps) {
        if let index = OBPowerUps.allCases.firstIndex(of: type) {
            indicators[index].showPowerUp(type)
        }
    }
    
    func hideShieldIndicator() {
        // Hide only the shield indicator
        if let shieldIndex = OBPowerUps.allCases.firstIndex(of: .shield) {
            indicators[shieldIndex].hideIfShield()
        }
    }
    
    func update(currentTime: TimeInterval) {
        indicators.forEach { $0.update(currentTime: currentTime) }
    }
}
