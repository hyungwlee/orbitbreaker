//
//  EnemyManager.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

import SpriteKit


class EnemyManager {
    private weak var scene: SKScene?
    private var enemies: [Enemy] = []
    private var waveManager: WaveManager
    private var currentWave = 0
    
    init(scene: SKScene) {
        self.scene = scene
        self.waveManager = WaveManager(scene: scene)
    }
    
    func setupEnemies() {
        guard let scene = scene else { return }
        
        enemies.forEach { $0.removeFromParent() }
        enemies.removeAll()
        
        currentWave += 1  // Increment wave counter
        
        // Calculate proper spacing for both horizontal and vertical alignment
        let horizontalMargin: CGFloat = 40
        let availableWidth = scene.size.width - (2 * horizontalMargin)
        let horizontalSpacing = availableWidth / CGFloat(EnemyConfig.columnCount - 1)
        
        let topMargin: CGFloat = scene.size.height * 0.8
        let availableHeight = scene.size.height * 0.3  // 30% of screen height for enemies
        let verticalSpacing = availableHeight / CGFloat(EnemyConfig.rowCount - 1)
        
        var enemyQueue: [(Enemy, CGPoint)] = []
        
        // Create enemies row by row, from bottom to top
        for row in 0..<EnemyConfig.rowCount {
            let enemyType: EnemyType = {
                switch row % 3 {
                case 0: return .a
                case 1: return .b
                default: return .c
                }
            }()
            
            let enemyPositionY = topMargin - (CGFloat(row) * verticalSpacing)
            
            // Create enemies in each row from left to right
            for column in 0..<EnemyConfig.columnCount {
                let enemyPositionX = horizontalMargin + (CGFloat(column) * horizontalSpacing)
                let finalPosition = CGPoint(x: enemyPositionX, y: enemyPositionY)
                
                let enemy = EnemySpawner.makeEnemy(ofType: enemyType)
                enemies.append(enemy)
                enemyQueue.append((enemy, finalPosition))
            }
        }
        
        // Order enemies for a satisfying entry pattern
        let orderedQueue = orderEnemiesForEntry(enemyQueue)
        waveManager.startNextWave(enemies: orderedQueue)
        
        // Randomly select exactly 2 enemies to be shooters
        let shooterIndices = Array(0..<enemies.count).shuffled().prefix(2)
        
        // Set all enemies to non-shooting by default
        enemies.forEach { enemy in
            enemy.canShoot = false
        }
        
        // Enable shooting only for the selected enemies
        for index in shooterIndices {
            enemies[index].canShoot = true
        }
    }
    
    private func orderEnemiesForEntry(_ enemies: [(Enemy, CGPoint)]) -> [(Enemy, CGPoint)] {
        // Sort enemies by their final X position to create a wave-like entry
        let sorted = enemies.sorted { first, second in
            first.1.x < second.1.x
        }
        return sorted
    }
    
    func update(currentTime: TimeInterval) {
        waveManager.update(currentTime: currentTime)
        for enemy in enemies {
            enemy.updateShooting(currentTime: currentTime, scene: scene!, waveNumber: currentWave)
        }
    }
    
    func handleBulletCollision(bullet: SKNode, enemy: Enemy) {
        bullet.removeFromParent()
        
        if enemy.takeDamage(1) {
            enemy.removeFromParent()
            if let index = enemies.firstIndex(of: enemy) {
                enemies.remove(at: index)
                
                if enemies.isEmpty {
                    setupEnemies()
                }
            }
        }
    }
    
    func getAllEnemies() -> [Enemy] {
        return enemies
    }
}
