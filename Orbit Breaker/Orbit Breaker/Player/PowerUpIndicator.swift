//
//  PowerUpIndicator.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 11/30/24.
//
import SpriteKit

class PowerUpIndicator: SKNode {
    private let backgroundCircle: SKShapeNode
    private let iconNode: SKLabelNode
    private let progressRing: SKShapeNode
    private var powerUpType: PowerUps?
    private var duration: TimeInterval = 5.0
    private var startTime: TimeInterval = 0
    
    init(size: CGFloat) {
        // Create background circle
        backgroundCircle = SKShapeNode(circleOfRadius: size/2)
        backgroundCircle.fillColor = .darkGray
        backgroundCircle.strokeColor = .white
        backgroundCircle.lineWidth = 2
        backgroundCircle.alpha = 0.7
        
        // Create progress ring
        progressRing = SKShapeNode(circleOfRadius: size/2)
        progressRing.strokeColor = .green
        progressRing.fillColor = .clear
        progressRing.lineWidth = 3
        
        // Create icon/text
        iconNode = SKLabelNode(fontNamed: "Arial-Bold")
        iconNode.fontSize = size * 0.5
        iconNode.verticalAlignmentMode = .center
        iconNode.fontColor = .white
        
        super.init()
        
        addChild(backgroundCircle)
        addChild(progressRing)
        addChild(iconNode)
        
        isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showPowerUp(_ type: PowerUps, duration: TimeInterval = 5.0) {
        self.powerUpType = type
        self.duration = duration
        self.startTime = 0
        
        // Set icon based on power-up type
        switch type {
        case .shield:
            iconNode.text = "🛡️"
            progressRing.strokeColor = .cyan
        case .doubleDamage:
            iconNode.text = "×2"
            progressRing.strokeColor = .red
        }
        
        isHidden = false
    }
    
    func hideIfShield() {
        if powerUpType == .shield {
            isHidden = true
            powerUpType = nil
        }
    }
    
    func update(currentTime: TimeInterval) {
        guard let _ = powerUpType, !isHidden else { return }
        
        if startTime == 0 {
            startTime = currentTime
        }
        
        let elapsed = currentTime - startTime
        let remaining = max(0, duration - elapsed)
        let progress = remaining / duration
        
        let radius = backgroundCircle.frame.width / 2
        let path = UIBezierPath()
        let startAngle: CGFloat = -.pi / 2
        let endAngle = startAngle + (.pi * 2 * progress)
        path.addArc(withCenter: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        progressRing.path = path.cgPath
        
        if remaining <= 0 {
            isHidden = true
            powerUpType = nil
        }
    }
}

class PowerUpManager {
    private var indicators: [PowerUpIndicator] = []
    private weak var scene: SKScene?
    
    init(scene: SKScene) {
        self.scene = scene
        setupIndicators()
    }
    
    func cleanup() {
        indicators.forEach { $0.removeFromParent() }
        indicators.removeAll()
    }
    
    private func setupIndicators() {
        guard let scene = scene else { return }
        
        let size: CGFloat = 50
        let spacing: CGFloat = 10
        let leftMargin: CGFloat = 15
        let bottomMargin: CGFloat = 20
        
        // Create an array of power up types in the order we want them
        let orderedPowerUps = [PowerUps.shield, PowerUps.doubleDamage]
        
        for (index, type) in orderedPowerUps.enumerated() {
            let indicator = PowerUpIndicator(size: size)
            let xPosition = leftMargin + (size / 2) + (CGFloat(index) * (size + spacing))
            
            indicator.position = CGPoint(
                x: xPosition,
                y: size/2 + bottomMargin
            )
            
            scene.addChild(indicator)
            indicators.append(indicator)
        }
    }
    
    func showPowerUp(_ type: PowerUps) {
        if let index = PowerUps.allCases.firstIndex(of: type) {
            indicators[index].showPowerUp(type)
        }
    }
    
    func hideShieldIndicator() {
        // Hide only the shield indicator
        if let shieldIndex = PowerUps.allCases.firstIndex(of: .shield) {
            indicators[shieldIndex].hideIfShield()
        }
    }
    
    func update(currentTime: TimeInterval) {
        indicators.forEach { $0.update(currentTime: currentTime) }
    }
}
