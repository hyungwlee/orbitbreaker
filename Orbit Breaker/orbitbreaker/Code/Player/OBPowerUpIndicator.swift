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
    private let originalIconSize: CGSize
    var layoutInfo: OBLayoutInfo
    
    init(size: CGFloat, layoutInfo: OBLayoutInfo) {
        self.layoutInfo = layoutInfo
        // Store original icon size for reset
        self.originalIconSize = CGSize(width: size * 0.3, height: size * 0.4)
        
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
        
        // Create icon node with original size
        iconNode = SKSpriteNode(color: .clear, size: originalIconSize)
        
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
    
    private func resetState() {
        // Stop any running animations
        iconNode.removeAllActions()
        textNode.removeAllActions()
        
        // Reset icon size to original
        iconNode.size = originalIconSize
        
        // Clear any existing glow effects
        glowNode?.removeAllChildren()
    }
    
    func showPowerUp(_ type: OBPowerUps) {
        // Reset state before showing new power-up
        resetState()
        
        self.powerUpType = type
        self.startTime = 0
        
        switch type {
        case .shield:
            self.duration = 10.0
            iconNode.texture = SKTexture(imageNamed: "OBshield")
            textNode.text = ""
            // Apply consistent scaling for shield icon
            iconNode.size = CGSize(
                width: originalIconSize.width * layoutInfo.screenScaleFactor,
                height: originalIconSize.height * layoutInfo.screenScaleFactor
            )
            progressRing.strokeColor = SKColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0)
            if let shieldGlow = iconNode.copy() as? SKSpriteNode {
                shieldGlow.alpha = 0.6
                glowNode?.addChild(shieldGlow)
            }
            
        case .doubleDamage:
            self.duration = 8.0
            iconNode.texture = SKTexture(imageNamed: "OBdoubleDamage")
            textNode.text = ""
            // Scale the icon for double damage with respect to original size
            iconNode.size = CGSize(
                width: originalIconSize.width * 1.7 * layoutInfo.screenScaleFactor,
                height: originalIconSize.height * 1.3 * layoutInfo.screenScaleFactor
            )
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
            resetState()
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
    private var activePowerUps: [(type: OBPowerUps, indicator: OBPowerUpIndicator)] = []
    
    init(scene: SKScene, layoutInfo: OBLayoutInfo) {
        self.scene = scene
        self.layoutInfo = layoutInfo
        setupIndicators()
    }
    
    private func setupIndicators() {
        guard let scene = scene else { return }
        
        let size: CGFloat = 80 * layoutInfo.screenScaleFactor
        let leftMargin: CGFloat = 15 * layoutInfo.screenScaleFactor
        let bottomMargin: CGFloat = 20 * layoutInfo.screenScaleFactor
        
        // Create one indicator for each power-up type
        for type in OBPowerUps.allCases {
            let indicator = OBPowerUpIndicator(size: size, layoutInfo: layoutInfo)
            indicator.position = CGPoint(
                x: leftMargin + (size / 2),
                y: size/2 + bottomMargin
            )
            indicator.isHidden = true
            scene.addChild(indicator)
            indicators.append(indicator)
        }
    }
    
    private func updateIndicatorPositions() {
        let size: CGFloat = 80 * layoutInfo.screenScaleFactor
        let spacing: CGFloat = 10 * layoutInfo.screenScaleFactor
        let leftMargin: CGFloat = 15 * layoutInfo.screenScaleFactor
        let bottomMargin: CGFloat = 20 * layoutInfo.screenScaleFactor
        
        // Animate each active indicator to its new position
        for (index, powerUp) in activePowerUps.enumerated() {
            let xPosition = leftMargin + (size / 2) + (CGFloat(index) * (size + spacing))
            let newPosition = CGPoint(
                x: xPosition,
                y: size/2 + bottomMargin
            )
            
            // Create smooth animation for position change
            let moveAction = SKAction.move(to: newPosition, duration: 0.2)
            moveAction.timingMode = .easeInEaseOut
            powerUp.indicator.run(moveAction)
        }
    }
    func showPowerUp(_ type: OBPowerUps) {
        // Find an unused indicator for this type
        if let indicator = indicators.first(where: { $0.isHidden }) {
            // Remove any existing active power-up of the same type
            activePowerUps.removeAll(where: { $0.type == type })
            
            // Add the new power-up to the front of the array
            activePowerUps.insert((type: type, indicator: indicator), at: 0)
            
            // Show the power-up
            indicator.showPowerUp(type)
            
            // Update positions of all indicators
            updateIndicatorPositions()
        }
    }
    
    func trackDroppedPowerUp(_ powerUp: OBPowerUp) {
        droppedPowerUps.append(powerUp)
    }
    
    func cleanup() {
        // Remove all indicators
        indicators.forEach { $0.removeFromParent() }
        indicators.removeAll()
        
        activePowerUps.removeAll()
        
        // Remove all dropped power-ups
        droppedPowerUps.forEach { $0.removeFromParent() }
        droppedPowerUps.removeAll()
    }
    
    
    func hideShieldIndicator() {
        if let index = activePowerUps.firstIndex(where: { $0.type == .shield }) {
            let powerUp = activePowerUps.remove(at: index)
            powerUp.indicator.hideIfShield()
            updateIndicatorPositions()
        }
    }
    
    func update(currentTime: TimeInterval) {
        // Update all indicators
        indicators.forEach { $0.update(currentTime: currentTime) }
        
        // Remove any hidden indicators from active power-ups
        let previousCount = activePowerUps.count
        activePowerUps.removeAll(where: { $0.indicator.isHidden })
        
        // If we removed any power-ups, update positions
        if previousCount != activePowerUps.count {
            updateIndicatorPositions()
        }
    }
}
