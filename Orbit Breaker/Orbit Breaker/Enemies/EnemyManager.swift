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
    private var bossNum: Int = 1
    
    init(scene: SKScene) {
        self.scene = scene
        self.waveManager = WaveManager(scene: scene)
    }
    
    func setupEnemies() {
        print("Setting up enemies...") // Debug print
        guard let scene = scene else {
            print("No scene available")
            return
        }
        
        // Clear existing enemies
        enemies.forEach { $0.removeFromParent() }
        enemies.removeAll()
        
        currentWave += 1
        print("Starting wave \(currentWave)") // Debug print
        
        if currentWave % 5 == 0 {
            print("Setting up boss wave") // Debug print
            setupBossWave()
            return
        } else {
            setupRegularWave()
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
            guard let scene = scene else { return }
            waveManager.update(currentTime: currentTime)
            
            for enemy in enemies {
                if let boss = enemy as? Boss {
                    // Call the boss-specific update method
                    boss.update(currentTime: currentTime, in: scene)
                } else {
                    // Regular enemy update
                    enemy.updateShooting(currentTime: currentTime, scene: scene, waveNumber: currentWave)
                }
            }
        }
    
    func forceCleanup() {
            // Remove all existing enemies
            enemies.forEach { $0.removeFromParent() }
            enemies.removeAll()
            
            // Reset wave manager state if needed
            waveManager.reset()
        }
    private func setupRegularWave() {
        guard let scene = scene else { return }
        
        // Calculate proper spacing
        let horizontalMargin: CGFloat = 40
        let availableWidth = scene.size.width - (2 * horizontalMargin)
        let horizontalSpacing = availableWidth / CGFloat(EnemyConfig.columnCount - 1)
        
        let topMargin: CGFloat = scene.size.height * 0.8
        let availableHeight = scene.size.height * 0.3
        let verticalSpacing = availableHeight / CGFloat(EnemyConfig.rowCount - 1)
        
        var enemyQueue: [(Enemy, CGPoint)] = []
        
        // Create enemies
        for row in 0..<EnemyConfig.rowCount {
            let enemyType: EnemyType = {
                switch row % 3 {
                case 0: return .a
                case 1: return .b
                default: return .c
                }
            }()
            
            let enemyPositionY = topMargin - (CGFloat(row) * verticalSpacing)
            
            for column in 0..<EnemyConfig.columnCount {
                let enemyPositionX = horizontalMargin + (CGFloat(column) * horizontalSpacing)
                let finalPosition = CGPoint(x: enemyPositionX, y: enemyPositionY)
                
                let enemy = EnemySpawner.makeEnemy(ofType: enemyType)
                enemies.append(enemy)
                enemyQueue.append((enemy, finalPosition))
                print("Created enemy at position: \(finalPosition)") // Debug print
            }
        }
        
        // Start the wave
        let orderedQueue = orderEnemiesForEntry(enemyQueue)
        waveManager.startNextWave(enemies: orderedQueue)
        
        // Assign shooters
        assignShooters()
        
        // Assign power-up holders
        assignPowerUpDroppers()
        
        print("Total regular enemies created: \(enemies.count)") // Debug print
    }

    
    func cleanupAllEnemies() {
            // Remove all enemies
            enemies.forEach { $0.removeFromParent() }
            enemies.removeAll()
            
            // Reset wave count
            currentWave = 0
            
            // Reset wave manager
            waveManager.reset()
        }
    
    private func setupBossWave() {
        guard let scene = scene else { return }
        
        print("Creating boss for wave \(currentWave)") // Debug print
        
        let boss: Boss
        
        switch bossNum {
        case 1:
            boss = Boss(type: .anger)
            bossNum += 1
        case 2:
            boss = Boss(type: .fear)
            bossNum += 1
        case 3:
            boss = Boss(type: .sadness)
            bossNum += 1
        default:
            boss = Boss(type: .disgust)
            bossNum = 1
        }
        
        boss.position = CGPoint(x: scene.size.width/2, y: scene.size.height * 0.8)
        scene.addChild(boss)
        enemies.append(boss)
        
        print("Boss created and added to scene") // Debug print
    }
    func handleEnemyDestroyed(_ enemy: Enemy) {
            if let index = enemies.firstIndex(of: enemy) {
                enemies.remove(at: index)
                
                
                // If all enemies are destroyed, start next wave after a delay
                if enemies.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.setupEnemies()
                    }
                }
            }
        }
    func handleBulletCollision(bullet: SKNode, enemy: Enemy) {
            guard let bullet = bullet as? Bullet else { return }
            
            print("Bullet hit enemy with damage: \(bullet.damage)")  // Debug print
            
            if enemy.takeDamage(bullet.damage) {
                print("Enemy died")  // Debug print
                enemy.removeFromParent()
                if let index = enemies.firstIndex(of: enemy) {
                    enemies.remove(at: index)
                    
                    if enemies.isEmpty {
                        // Add a small delay before setting up next wave
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            self?.setupEnemies()
                        }
                    }
                }
            }
            bullet.removeFromParent()
    }
    
    func getAllEnemies() -> [Enemy] {
        return enemies
    }
    
    func assignShooters() {
        // Make sure we have enough enemies
        guard enemies.count >= 4 else { return }
        
        // Reset all enemies to non-shooting
        enemies.forEach { $0.canShoot = false }
        
        // Get 4 random indices
        let shooterIndices = Array(0..<enemies.count).shuffled().prefix(4)
        
        // Assign different delays to each shooter
        for (index, enemyIndex) in shooterIndices.enumerated() {
            let enemy = enemies[enemyIndex]
            enemy.canShoot = true
            
            // Stagger initial shoot times
            if let scene = scene {
                let initialDelay = Double(index) * 0.75 // Stagger by 0.75 seconds
                enemy.updateShooting(currentTime: -initialDelay, scene: scene, waveNumber: currentWave)
            }
        }
    }
    
    func assignPowerUpDroppers(){
        
        // Make sure we have enough enemies
        guard enemies.count >= 4 else { return }
        
        // Reset all enemies to non-holding powerups
        enemies.forEach { $0.holdsPowerUp = false }
        
        // Get 4=3 random indices
        let powerUpHolders = Array(0..<enemies.count).shuffled().prefix(4)
        
        for (indices, holderIndex) in powerUpHolders.enumerated() {
            let enemy = enemies[holderIndex]
            enemy.holdsPowerUp = true
            
        }
        
        
        
    }
}

