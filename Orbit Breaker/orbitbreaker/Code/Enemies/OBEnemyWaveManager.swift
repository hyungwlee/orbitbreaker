//
//  OBEnemyWaveManager.swift
//  Orbit Breaker
//
//  Created by Michelle Bai on 12/20/24.
//


import Foundation
import SpriteKit
import CoreGraphics

struct OBEnemyWaveConfig {
    static let leftEntryPoint = CGPoint(x: -30, y: 550)
    static let rightEntryPoint = CGPoint(x: 450, y: 550)
    
    static let enemySpawnInterval: TimeInterval = 0.12
    static let pathDuration: TimeInterval = 1.0
    
    // Add bottom points for the new swooping pattern
    static let leftBottomPoint = CGPoint(x: 100, y: 100)  // Near bottom left
    static let rightBottomPoint = CGPoint(x: 320, y: 100) // Near bottom right
    
    enum OBEntryPattern {
        case swoopLeft
        case swoopRight
        case advancedSwoopLeft
        case advancedSwoopRight
        
        func generatePath(from startPoint: CGPoint, to endPoint: CGPoint, waveNumber: Int) -> UIBezierPath {
            let path = UIBezierPath()
            path.move(to: startPoint)
            // Original basic swooping pattern for early waves
            switch self {
            case .swoopLeft, .advancedSwoopLeft:
                let controlPoint1 = CGPoint(x: startPoint.x + 100, y: startPoint.y + 40)
                let controlPoint2 = CGPoint(x: endPoint.x + 60, y: endPoint.y + 60)
                path.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
                
            case .swoopRight, .advancedSwoopRight:
                let controlPoint1 = CGPoint(x: startPoint.x - 100, y: startPoint.y + 40)
                let controlPoint2 = CGPoint(x: endPoint.x - 60, y: endPoint.y + 60)
                path.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
            }
            
            
            return path
        }
    }
}

class OBWaveManager {
    private weak var scene: SKScene?
    private var currentWave = 0
    private var enemySpawnQueue: [(OBEnemy, CGPoint)] = []
    private var isSpawning = false
    private var lastSpawnTime: TimeInterval = 0
    
    init(scene: SKScene) {
        self.scene = scene
    }
    func reset() {
        isSpawning = false
        enemySpawnQueue.removeAll()
        lastSpawnTime = 0
    }
    
    func startNextWave(enemies: [(OBEnemy, CGPoint)]) {
        currentWave += 1
        enemySpawnQueue = enemies
        isSpawning = true
        lastSpawnTime = 0
    }
    
    func update(currentTime: TimeInterval) {
        guard isSpawning,
              !enemySpawnQueue.isEmpty,
              currentTime - lastSpawnTime >= OBEnemyWaveConfig.enemySpawnInterval,
              let scene = scene else { return }
        
        let (enemy, finalPosition) = enemySpawnQueue.removeFirst()
        let useLeftEntry = enemySpawnQueue.count % 2 == 0
        
        let startPoint = useLeftEntry ? OBEnemyWaveConfig.leftEntryPoint : OBEnemyWaveConfig.rightEntryPoint
        let pattern: OBEnemyWaveConfig.OBEntryPattern = useLeftEntry ? .advancedSwoopLeft : .advancedSwoopRight
        
        enemy.position = startPoint
        // Set rotation to 0 (facing right)
        enemy.zRotation = 0
        scene.addChild(enemy)
        
        let path = pattern.generatePath(from: startPoint, to: finalPosition, waveNumber: currentWave)
        
        let pathDuration = currentWave <= 3 ?
        OBEnemyWaveConfig.pathDuration :
        OBEnemyWaveConfig.pathDuration * 1.5
        
        let followPath = SKAction.follow(path.cgPath,
                                         asOffset: false,
                                         orientToPath: false,  // Keep orientation fixed
                                         duration: pathDuration)
        
        enemy.run(followPath)
        
        lastSpawnTime = currentTime
        
        if enemySpawnQueue.isEmpty {
            isSpawning = false
        }
    }
}
