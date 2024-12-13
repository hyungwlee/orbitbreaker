//
//  WaveRoadmap.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 11/30/24.
//
import SpriteKit

class WaveRoadmap {
    private weak var scene: SKScene?
    private var roadmapNodes: [SKNode] = []
    private var waveDots: [SKShapeNode] = []
    private var currentWaveIndicator: SKShapeNode?
    private var waveLabels: [SKLabelNode] = []  // To track wave labels
    private let waveCount = 5
    
    init(scene: SKScene) {
        self.scene = scene
        setupRoadmap()
    }
    
    private func setupRoadmap() {
        guard let scene = scene else { return }
        
        cleanup()
        
        let spacing: CGFloat = 60  // Increased spacing
        let dotRadius: CGFloat = 10  // Slightly larger dots
        let topMargin: CGFloat = 30
        let centerX: CGFloat = 45
        
        let startY = scene.size.height - topMargin - (CGFloat(waveCount - 1) * spacing)
        
        // Create dots with glow effects
        for i in 0..<waveCount {
            let y = startY + CGFloat(i) * spacing
            let dotContainer = SKNode()
            dotContainer.position = CGPoint(x: centerX, y: y)
            
            // Glow effect
            let glow = SKEffectNode()
            glow.shouldRasterize = true
            glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 2.0])
            
            let glowShape = SKShapeNode(circleOfRadius: dotRadius + 2)
            glowShape.fillColor = .white
            glowShape.strokeColor = .clear
            glowShape.alpha = 0.3
            glow.addChild(glowShape)
            dotContainer.addChild(glow)
            
            // Main dot
            let dot = SKShapeNode(circleOfRadius: dotRadius)
            dot.fillColor = .white
            dot.strokeColor = SKColor(white: 0.8, alpha: 1.0)
            dot.lineWidth = 2
            dot.alpha = 0.9
            dot.zPosition = 4
            dotContainer.addChild(dot)
            
            scene.addChild(dotContainer)
            roadmapNodes.append(dotContainer)
            waveDots.append(dot)
            
            // Wave labels with new font and style
            let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            if i == waveCount - 1 {
                label.text = "BOSS"
                label.fontSize = 16
                label.fontColor = getBossColor(for: i)
            } 
            label.horizontalAlignmentMode = .left
            label.position = CGPoint(x: centerX + 25, y: y - 6)
            label.alpha = 0.8
            scene.addChild(label)
            roadmapNodes.append(label)
            waveLabels.append(label)
        }
        
        // Create styled connecting lines
        // Replace the line creation code in setupRoadmap() with this:
                
        // Create styled connecting lines
        for i in 1..<waveCount {
            let y = startY + CGFloat(i) * spacing
            let dashLength: CGFloat = 4
            let gapLength: CGFloat = 4
            let startY = y - spacing + dotRadius
            let endY = y - dotRadius
            let totalLength = endY - startY
            let dashCount = Int(totalLength / (dashLength + gapLength))
            
            for j in 0..<dashCount {
                let dashY = startY + CGFloat(j) * (dashLength + gapLength)
                let dash = SKShapeNode()
                let path = CGMutablePath()
                path.move(to: CGPoint(x: centerX, y: dashY))
                path.addLine(to: CGPoint(x: centerX, y: min(dashY + dashLength, endY)))
                dash.path = path
                dash.strokeColor = SKColor(white: 0.6, alpha: 1.0)
                dash.lineWidth = 2
                dash.lineCap = .round
                dash.zPosition = 3
                dash.alpha = 0.4
                
                scene.addChild(dash)
                roadmapNodes.append(dash)
            }
        }
        
        // Create stylized indicator
        if currentWaveIndicator == nil {
                    let indicatorContainer = SKNode()
                    
                    // Outer ring with glow
                    let glowEffect = SKEffectNode()
                    glowEffect.shouldRasterize = true
                    glowEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 3.0])
                    glowEffect.zPosition = 10 // Ensure it's above the dots
                    
                    let outerGlow = SKShapeNode(circleOfRadius: dotRadius + 6)
                    outerGlow.strokeColor = .yellow
                    outerGlow.lineWidth = 2
                    outerGlow.zPosition = 10
                    outerGlow.fillColor = .clear
                    glowEffect.addChild(outerGlow)
                    indicatorContainer.addChild(glowEffect)
                    
                    currentWaveIndicator = SKShapeNode(circleOfRadius: dotRadius + 4)
                    currentWaveIndicator?.strokeColor = .yellow
                    currentWaveIndicator?.lineWidth = 2
                    currentWaveIndicator?.fillColor = .clear
                    currentWaveIndicator?.zPosition = 10 // Ensure it's above the dots
                    
                    if let indicator = currentWaveIndicator {
                        indicator.position = CGPoint(x: centerX, y: startY)
                        scene.addChild(indicator)
                        
                        let pulseAction = SKAction.sequence([
                            SKAction.scale(to: 1.2, duration: 0.8),
                            SKAction.scale(to: 1.0, duration: 0.8)
                        ])
                        indicator.run(SKAction.repeatForever(pulseAction))
                    }
                }
            }
    
    private func getBossColor(for wave: Int) -> SKColor {
        // Match boss colors to their respective waves
        switch wave {
        case 4:  // First boss (Anger)
            return SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        case 9:  // Second boss (Sadness)
            return SKColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0)
        case 14: // Third boss (Disgust)
            return SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
        case 19: // Fourth boss (Love)
            return SKColor(red: 0.9, green: 0.2, blue: 0.5, alpha: 1.0)
        default:
            return .yellow
        }
    }
    
    func updateCurrentWave(_ wave: Int) {
        guard let scene = scene else { return }
        
        let adjustedWave = (wave - 1) % waveCount
        let spacing: CGFloat = 60  // Match the new spacing
        let topMargin: CGFloat = 30
        let startY = scene.size.height - topMargin - (CGFloat(waveCount - 1) * spacing)
        let y = startY + CGFloat(adjustedWave) * spacing
        
        // Update completed waves with animation
        for i in 0..<waveDots.count {
            if i < adjustedWave {
                let colorizeAction = SKAction.run {
                    self.waveDots[i].fillColor = SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)
                    self.waveDots[i].strokeColor = SKColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1.0)
                    self.waveDots[i].alpha = 1.0
                    self.waveLabels[i].fontColor = SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)
                }
                waveDots[i].run(colorizeAction)
            } else if i > adjustedWave {
                let resetAction = SKAction.run {
                    self.waveDots[i].fillColor = .white
                    self.waveDots[i].strokeColor = SKColor(white: 0.8, alpha: 1.0)
                    self.waveDots[i].alpha = 0.9
                    if i == self.waveCount - 1 {
                        self.waveLabels[i].fontColor = self.getBossColor(for: i)
                    } else {
                        self.waveLabels[i].fontColor = SKColor(white: 0.8, alpha: 1.0)
                    }
                }
                waveDots[i].run(resetAction)
            }
        }
        
        // Smooth indicator movement
        currentWaveIndicator?.removeAllActions()
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8)
        ])
        
        let moveAction = SKAction.move(to: CGPoint(x: 45, y: y), duration: 0.5)
        moveAction.timingMode = .easeInEaseOut
        
        currentWaveIndicator?.run(SKAction.group([
            SKAction.repeatForever(pulseAction),
            moveAction
        ]))
        currentWaveIndicator?.zPosition = 10
    }
    
    
    func cleanup() {
        // Immediately remove the indicator from the scene if it exists
        currentWaveIndicator?.removeFromParent()
        currentWaveIndicator = nil
        
        roadmapNodes.forEach {
            $0.removeAllActions()
            $0.removeFromParent()
        }
        roadmapNodes.removeAll()
        waveDots.removeAll()
    }
    
    func hideRoadmap() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        roadmapNodes.forEach { $0.run(fadeOut) }
        currentWaveIndicator?.run(fadeOut)
    }
    
    func showRoadmap() {
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        roadmapNodes.forEach { $0.run(fadeIn) }
        currentWaveIndicator?.run(fadeIn)
    }
}
