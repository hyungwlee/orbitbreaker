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
    private var currentWaveIndicator: SKShapeNode?
    private let waveCount = 5 // Waves until boss
    
    init(scene: SKScene) {
        self.scene = scene
        setupRoadmap()
    }
    
    
    private func setupRoadmap() {
        guard let scene = scene else { return }
        
        roadmapNodes.forEach { $0.removeFromParent() }
        roadmapNodes.removeAll()
        
        let spacing: CGFloat = 50
        let dotRadius: CGFloat = 8
        let startY = scene.size.height - 50
        let centerX: CGFloat = 40  // Moved to left side
        
        for i in 0..<waveCount {
            let y = startY - CGFloat(i) * spacing
            
            if i > 0 {
                let line = SKShapeNode(rectOf: CGSize(width: 2, height: spacing - 10))
                line.fillColor = .gray
                line.strokeColor = .clear
                line.position = CGPoint(x: centerX, y: y + spacing/2)
                line.alpha = 0.5
                scene.addChild(line)
                roadmapNodes.append(line)
            }
            
            let dot = SKShapeNode(circleOfRadius: dotRadius)
            dot.fillColor = .white
            dot.strokeColor = .gray
            dot.position = CGPoint(x: centerX, y: y)
            dot.alpha = 0.7
            scene.addChild(dot)
            roadmapNodes.append(dot)
            
            // Only add "BOSS" text for the last dot
            if i == waveCount - 1 {
                let label = SKLabelNode(fontNamed: "Arial")
                label.text = "BOSS"
                label.fontSize = 12
                label.fontColor = .white
                label.position = CGPoint(x: centerX + 20, y: y - 6)
                label.horizontalAlignmentMode = .left
                scene.addChild(label)
                roadmapNodes.append(label)
            }
        }
        
        currentWaveIndicator = SKShapeNode(circleOfRadius: dotRadius + 4)
        currentWaveIndicator?.strokeColor = .yellow
        currentWaveIndicator?.lineWidth = 2
        currentWaveIndicator?.position = CGPoint(x: centerX, y: startY)
        if let indicator = currentWaveIndicator {
            scene.addChild(indicator)
            roadmapNodes.append(indicator)
        }
        
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        currentWaveIndicator?.run(SKAction.repeatForever(pulseAction))
    }
    
    func updateCurrentWave(_ wave: Int) {
        guard let scene = scene else { return }
        
        let adjustedWave = (wave - 1) % waveCount
        let spacing: CGFloat = 50
        let startY = scene.size.height - 50
        let y = startY - CGFloat(adjustedWave) * spacing
        
        let moveAction = SKAction.move(to: CGPoint(x: 40, y: y), duration: 0.5)
        moveAction.timingMode = .easeInEaseOut
        currentWaveIndicator?.run(moveAction)
    }
    
    func hideRoadmap() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        roadmapNodes.forEach { $0.run(fadeOut) }
    }
    
    func showRoadmap() {
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        roadmapNodes.forEach { $0.run(fadeIn) }
    }
}
