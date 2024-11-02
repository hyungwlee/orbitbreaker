//
//  EnemyWaveManager.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/28/24.
//

import Foundation
import SpriteKit
import CoreGraphics

struct EnemyWaveConfig {
    static let leftEntryPoint = CGPoint(x: -30, y: 550)
    static let rightEntryPoint = CGPoint(x: 450, y: 550)
    
    static let enemySpawnInterval: TimeInterval = 0.12
    static let pathDuration: TimeInterval = 1.0
    
    // Add bottom points for the new swooping pattern
    static let leftBottomPoint = CGPoint(x: 100, y: 100)  // Near bottom left
    static let rightBottomPoint = CGPoint(x: 320, y: 100) // Near bottom right
    
    enum EntryPattern {
        case swoopLeft
        case swoopRight
        case advancedSwoopLeft
        case advancedSwoopRight
        
        func generatePath(from startPoint: CGPoint, to endPoint: CGPoint, waveNumber: Int) -> UIBezierPath {
            let path = UIBezierPath()
            path.move(to: startPoint)
            
            if waveNumber <= 3 {
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
            } else {
                // Advanced swooping pattern for later waves
                switch self {
                case .swoopLeft, .advancedSwoopLeft:
                    // First curve down to bottom point
                    let downControlPoint1 = CGPoint(x: startPoint.x + 100, y: startPoint.y)
                    let downControlPoint2 = CGPoint(x: leftBottomPoint.x - 50, y: leftBottomPoint.y + 100)
                    path.addCurve(to: leftBottomPoint, controlPoint1: downControlPoint1, controlPoint2: downControlPoint2)
                    
                    // Second curve up to final position
                    let upControlPoint1 = CGPoint(x: leftBottomPoint.x + 50, y: leftBottomPoint.y)
                    let upControlPoint2 = CGPoint(x: endPoint.x - 50, y: endPoint.y - 100)
                    path.addCurve(to: endPoint, controlPoint1: upControlPoint1, controlPoint2: upControlPoint2)
                    
                case .swoopRight, .advancedSwoopRight:
                    // First curve down to bottom point
                    let downControlPoint1 = CGPoint(x: startPoint.x - 100, y: startPoint.y)
                    let downControlPoint2 = CGPoint(x: rightBottomPoint.x + 50, y: rightBottomPoint.y + 100)
                    path.addCurve(to: rightBottomPoint, controlPoint1: downControlPoint1, controlPoint2: downControlPoint2)
                    
                    // Second curve up to final position
                    let upControlPoint1 = CGPoint(x: rightBottomPoint.x - 50, y: rightBottomPoint.y)
                    let upControlPoint2 = CGPoint(x: endPoint.x + 50, y: endPoint.y - 100)
                    path.addCurve(to: endPoint, controlPoint1: upControlPoint1, controlPoint2: upControlPoint2)
                }
            }
            
            return path
        }
    }
}

class WaveManager {
    private weak var scene: SKScene?
    private var currentWave = 0
    private var enemySpawnQueue: [(Enemy, CGPoint)] = []
    private var isSpawning = false
    private var lastSpawnTime: TimeInterval = 0
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    func startNextWave(enemies: [(Enemy, CGPoint)]) {
        currentWave += 1
        enemySpawnQueue = enemies
        isSpawning = true
        lastSpawnTime = 0
    }
    
    func update(currentTime: TimeInterval) {
        guard isSpawning,
              !enemySpawnQueue.isEmpty,
              currentTime - lastSpawnTime >= EnemyWaveConfig.enemySpawnInterval,
              let scene = scene else { return }
        
        let (enemy, finalPosition) = enemySpawnQueue.removeFirst()
        let useLeftEntry = enemySpawnQueue.count % 2 == 0
        
        let startPoint = useLeftEntry ? EnemyWaveConfig.leftEntryPoint : EnemyWaveConfig.rightEntryPoint
        let pattern: EnemyWaveConfig.EntryPattern = useLeftEntry ? .advancedSwoopLeft : .advancedSwoopRight
        
        enemy.position = startPoint
        scene.addChild(enemy)
        
        let path = pattern.generatePath(from: startPoint, to: finalPosition, waveNumber: currentWave)
        
        // Adjust duration based on wave number for more dramatic effect
        let pathDuration = currentWave <= 3 ?
            EnemyWaveConfig.pathDuration :
            EnemyWaveConfig.pathDuration * 1.5 // Slightly slower for more dramatic effect
        
        let followPath = SKAction.follow(path.cgPath,
                                       asOffset: false,
                                       orientToPath: true,
                                       duration: pathDuration)
        let rotateToFaceDown = SKAction.rotate(toAngle: CGFloat.pi/2, duration: 0.2)
        
        enemy.run(SKAction.sequence([followPath, rotateToFaceDown]))
        
        lastSpawnTime = currentTime
        
        if enemySpawnQueue.isEmpty {
            isSpawning = false
        }
    }
}
