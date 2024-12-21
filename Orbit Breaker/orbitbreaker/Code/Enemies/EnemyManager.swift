//
//  EnemyManager.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

import SpriteKit


class EnemyManager {
    private weak var scene: OBGameScene?
    private var enemies: [Enemy] = []
    private var waveManager: WaveManager
    private var bossAnnouncement: BossAnnouncement?
    private var roadmap: WaveRoadmap?
    private var asteroidFieldAnnouncement: AsteroidFieldAnnouncement?
    private var asteroidChallenge: AsteroidFieldChallenge?

    var currentWave = 0
    var bossNum: Int = 1
    var layoutInfo: OBLayoutInfo
    init(scene: OBGameScene, layoutInfo: OBLayoutInfo) {
            self.scene = scene
            self.waveManager = WaveManager(scene: scene)
            self.bossAnnouncement = BossAnnouncement(scene: scene)
        self.layoutInfo = layoutInfo
            // Look for existing roadmap nodes and remove them
            scene.enumerateChildNodes(withName: "*") { node, _ in
                if let circle = node as? SKShapeNode, circle.strokeColor == .yellow {
                    circle.removeFromParent()
                }
            }
            
            // Create new roadmap for fresh start
        self.roadmap = WaveRoadmap(scene: scene, enemyManager: self, layoutInfo: layoutInfo)
        }
    
    
    func setupEnemies() {
            guard let scene = scene else { return }
            
            // Clear existing enemies
            enemies.forEach { $0.removeFromParent() }
            enemies.removeAll()
            
            currentWave += 1
            
            // Wave sequence: 1,2(enemy) -> 3(asteroid) -> 4,5(enemy) -> boss -> repeat
            let waveType = currentWave % 6
            
            if waveType == 0 {
                // Boss wave
                roadmap?.showRoadmap()
                setupBossWave()
            } else {
                // Regular wave or asteroid field
                roadmap?.showRoadmap()
                roadmap?.updateCurrentWave(currentWave)
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
    
    private func assignKamikazeEnemies() {
        guard currentWave > 3 && currentWave % 6 != 0 else { return }
        
        // Determine number of kamikaze enemies based on wave
        let maxKamikazeCount = min(2, enemies.count - 1) // Never convert all enemies
        
        let kamikazeCount = enemies.count > 0 ? Int.random(in: 1...maxKamikazeCount) : 0
        
        // Select random enemies to become kamikaze
        let selectedEnemies = enemies.shuffled().prefix(kamikazeCount)
        
        // Convert selected enemies to kamikaze
        for enemy in selectedEnemies {
            // Don't convert bosses
            if !(enemy is Boss) {
                enemy.startKamikazeBehavior()
            }
        }
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
    
    
    private func setupAsteroidField() {
        guard let scene = scene else { return }
        
        // Clean up any existing power-ups
        scene.enumerateChildNodes(withName: "powerUp") { node, _ in
            if let powerUp = node as? PowerUp {
                // Remove any ongoing animations first
                powerUp.removeAllActions()
                powerUp.removeFromParent()
            }
        }
        
        // Show announcement first
        asteroidFieldAnnouncement = AsteroidFieldAnnouncement(scene: scene, layoutInfo: layoutInfo)
        asteroidChallenge = AsteroidFieldChallenge(scene: scene)
        
        asteroidFieldAnnouncement?.showAnnouncement { [weak self] in
            self?.asteroidChallenge?.startChallenge { [weak self] in
                // After challenge completes, move to next wave
                self?.setupEnemies()
            }
        }
        
        // Update roadmap but only increment half a position
        roadmap?.updateCurrentWave(currentWave)
    }
        
        private func setupRegularWave() {
            guard let scene = scene else { return }
            
            // Clean up any existing asteroid field
            asteroidChallenge?.cleanup()
            asteroidFieldAnnouncement = nil
            asteroidChallenge = nil
            
            // Rest of your regular wave setup code...
            let nextBossType = getBossType()
            let formationKeys = Array(FormationMatrix.formations.keys)
            let formationKey = formationKeys[currentWave % formationKeys.count]
            let formation = FormationMatrix.formations[formationKey] ?? FormationMatrix.formations["standard"]!
            
            let positions = FormationGenerator.generatePositions(
                from: formation,
                in: scene,
                spacing: CGSize(width: 60, height: 50),
                topMargin: 0.8
            )
            
            var enemyQueue: [(Enemy, CGPoint)] = []
            
            for (index, position) in positions.enumerated() {
                let enemyType: EnemyType = {
                    switch index % 3 {
                    case 0: return .a
                    case 1: return .b
                    default: return .c
                    }
                }()
                
                let enemy = EnemySpawner.makeEnemy(ofType: enemyType, layoutInfo: scene.layoutInfo)
                enemy.updateTexture(forBossType: nextBossType)
                enemies.append(enemy)
                enemyQueue.append((enemy, position))
            }
            
            let orderedQueue = orderEnemiesForEntry(enemyQueue)
            waveManager.startNextWave(enemies: orderedQueue)
            
            assignShooters()
            assignPowerUpDroppers()
            assignEnemyMovements()
            if currentWave > 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.assignKamikazeEnemies()
                }
            }
        }
    
    func assignEnemyMovements() {
            guard let scene = scene else { return }
            
            // Give each enemy a simple side-to-side movement
            for enemy in enemies {
                let moveRight = SKAction.moveBy(x: 30, y: 0, duration: 2.0)
                moveRight.timingMode = .easeInEaseOut
                let moveLeft = moveRight.reversed()
                
                let sequence = SKAction.sequence([moveRight, moveLeft])
                enemy.run(SKAction.repeatForever(sequence))
            }
        }
    
    func performFormationChange() {
        guard let scene = scene,
              !enemies.isEmpty else { return }
        
        let safeMarginX: CGFloat = 40
        let safeMarginY: CGFloat = 100
        
        // Get new formation positions
        let newFormation = FormationMatrix.formations.randomElement()?.value ?? []
        var newPositions = FormationGenerator.generatePositions(
            from: newFormation,
            in: scene,
            spacing: CGSize(width: 50, height: 40),
            topMargin: 0.7
        )
        
        // Ensure positions are within bounds
        newPositions = newPositions.map { pos in
            CGPoint(
                x: min(max(pos.x, safeMarginX), scene.size.width - safeMarginX),
                y: min(max(pos.y, safeMarginY), scene.size.height - safeMarginY)
            )
        }
        
        // Ensure we have enough positions
        guard newPositions.count >= enemies.count else { return }
        
        // Transition to new positions
        for (index, enemy) in enemies.enumerated() {
            let newPos = newPositions[index]
            
            // Update stored home position
            enemy.userData?["homeX"] = newPos.x
            enemy.userData?["homeY"] = newPos.y
            
            let moveAction = SKAction.sequence([
                SKAction.move(to: newPos, duration: 1.5)
            ])
            moveAction.timingMode = .easeInEaseOut
            
            enemy.run(moveAction)
        }
    }
    private func getFormationCenter() -> CGPoint {
        guard !enemies.isEmpty else { return .zero }
        
        // Calculate the center point of all enemies
        let sumX = enemies.reduce(0) { $0 + $1.position.x }
        let sumY = enemies.reduce(0) { $0 + $1.position.y }
        let count = CGFloat(enemies.count)
        
        return CGPoint(x: sumX / count, y: sumY / count)
    }
    
    // Optional: Add this method to create smooth formation changes
    
    private func getMovementPattern(for index: Int) -> Enemy.MovementPattern {
        // Use wave number to influence pattern selection
        let basePattern = index % 4
        
        // As waves progress, increase chance of more complex patterns
        let complexityBonus = min(currentWave / 3, 3) // Max 3 point bonus
        let patternRoll = Int.random(in: 0...(3 + complexityBonus))
        
        switch patternRoll {
        case 0: return .oscillate    // Simple side-to-side
        case 1: return .circle       // Circular motion
        case 2: return .figure8      // Figure-8 pattern
        case 3: return .dive         // Diving attack
        default: return .oscillate   // Default to simple pattern
        }
    }
    
    private func setupFormationChanges() {
        let formationChange = SKAction.run { [weak self] in
            guard let self = self else { return }
            let newFormation = FormationMatrix.formations.randomElement()?.value ?? []
            
            for (index, enemy) in self.enemies.enumerated() {
                if index < newFormation.count {
                    let newPosition = FormationGenerator.generatePositions(
                        from: [newFormation[index]],
                        in: self.scene!,
                        spacing: CGSize(width: 60, height: 50),
                        topMargin: 0.8
                    )[0]
                    
                    enemy.run(SKAction.move(to: newPosition, duration: 1.0))
                }
            }
        }
        
        scene?.run(SKAction.sequence([
            SKAction.wait(forDuration: 5.0),
            formationChange
        ]))
    }
    
        func skipCurrentWave() {
            // Clean up current wave first
            forceCleanup()
            
            // Increment wave count
            currentWave += 1
            
            // Determine if the next wave should be an asteroid field
            // Wave sequence: 1,2(enemy) -> 3(asteroid) -> 4,5(enemy) -> boss -> repeat
            let nextWaveType = currentWave % 6
            
            if nextWaveType == 3 {
                // This should be an asteroid wave
                roadmap?.updateCurrentWave(currentWave)
                setupAsteroidField()
            } else if nextWaveType == 0 {
                // This should be a boss wave
                roadmap?.showRoadmap()
                setupBossWave()
            } else {
                // Regular enemy wave
                roadmap?.showRoadmap()
                roadmap?.updateCurrentWave(currentWave)
                setupRegularWave()
            }
        }

        func forceCleanup() {
            // Clean up all enemies
            enemies.forEach {
                if let boss = $0 as? Boss {
                    boss.cleanup()
                }
                $0.removeFromParent()
            }
            enemies.removeAll()
            
            // Reset wave manager state
            waveManager.reset()
            
            // Clean up asteroid challenge
            if let challenge = asteroidChallenge {
                challenge.cleanup()
            }
            asteroidChallenge = nil
            
            // Clean up asteroid announcement
            asteroidFieldAnnouncement = nil
            
            // Remove any remaining asteroid nodes
            scene?.enumerateChildNodes(withName: "asteroid") { node, _ in
                node.removeFromParent()
            }
            
            // Remove any remaining enemy bullets
            scene?.enumerateChildNodes(withName: "enemyBullet") { node, _ in
                node.removeFromParent()
            }
            
            // Remove any power-ups
            scene?.enumerateChildNodes(withName: "powerUp") { node, _ in
                node.removeFromParent()
            }
        }
    
    func cleanupAllEnemies() {
            // Remove all enemies
            enemies.forEach { $0.removeFromParent() }
            enemies.removeAll()
            
            // Reset wave count
            currentWave = 0
            
            // Reset wave manager
            waveManager.reset()
            
            // Clean up asteroid-related content
            asteroidChallenge?.cleanup()
            asteroidFieldAnnouncement = nil
            asteroidChallenge = nil
            
            // Remove any remaining asteroid nodes
            scene?.enumerateChildNodes(withName: "asteroid") { node, _ in
                node.removeFromParent()
            }
            
            roadmap?.showRoadmap()
            roadmap?.updateCurrentWave(1)
        }
    
    private func setupBossWave() {
        guard let scene = scene else { return }
        
        // Don't hide roadmap anymore
        // roadmap?.hideRoadmap() // Remove or comment out this line
        roadmap?.updateCurrentWave(currentWave)
        
        bossAnnouncement?.showAnnouncement(bossType: getBossType()) { [weak self] in
            self?.spawnBoss()
        }
    }
    
    private func spawnBoss() {
        guard let scene = scene else { return }
        
        let boss: Boss
        
        switch bossNum {
        case 1:
            boss = Boss(type: .anger, layoutInfo: scene.layoutInfo)
            bossNum = 2
        case 2:
            boss = Boss(type: .sadness, layoutInfo: scene.layoutInfo)
            bossNum = 3
        case 3:
            boss = Boss(type: .disgust, layoutInfo: scene.layoutInfo)
            bossNum = 4
        case 4:
            boss = Boss(type: .love, layoutInfo: scene.layoutInfo)
            bossNum = 1
        default:
            boss = Boss(type: .anger, layoutInfo: scene.layoutInfo)
            bossNum = 2
        }
        
        boss.position = CGPoint(x: scene.size.width/2, y: scene.size.height * 0.8)
        scene.addChild(boss)
        enemies.append(boss)
    }
    
    func getBossType() -> BossType {
            switch bossNum {
            case 1: return .anger
            case 2: return .sadness
            case 3: return .disgust
            case 4: return .love
            default: return .love
            }
        }
    func handleEnemyDestroyed(_ enemy: Enemy) {
           if let index = enemies.firstIndex(of: enemy) {
               enemies.remove(at: index)
               
               if enemies.isEmpty {
                   let delay: TimeInterval = (enemy is Boss) ? 3.5 : 1.0
                   DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                       guard let self = self else { return }
                       
                       if enemy is Boss {
                           // After boss, reset to wave 0
                           self.currentWave = 0
                           self.roadmap?.showRoadmap()
                           self.roadmap?.updateCurrentWave(0)
                           self.setupEnemies()
                       } else {
                           // Check for asteroid field after every 2nd wave
                           if self.currentWave % 6 != 0 && self.currentWave % 6 == 2 {
                               self.currentWave += 1
                               roadmap?.updateCurrentWave(currentWave)
                               self.setupAsteroidField()
                           } else {
                               self.setupEnemies()
                           }
                       }
                   }
               }
           }
       }
    
    
    private var preparedEnemies: [(Enemy, CGPoint)] = []
        
        private func prepareNextWave() {
            guard let scene = scene else { return }
            preparedEnemies.removeAll()
            
            let nextBossType = getBossType()
            let formationKeys = Array(FormationMatrix.formations.keys)
            let formationKey = formationKeys[currentWave % formationKeys.count]
            let formation = FormationMatrix.formations[formationKey] ?? FormationMatrix.formations["standard"]!
            
            let positions = FormationGenerator.generatePositions(
                from: formation,
                in: scene,
                spacing: CGSize(width: 60, height: 50),
                topMargin: 0.8
            )
            
            for (index, position) in positions.enumerated() {
                let enemyType: EnemyType = {
                    switch index % 3 {
                    case 0: return .a
                    case 1: return .b
                    default: return .c
                    }
                }()
                
                let enemy = EnemySpawner.makeEnemy(ofType: enemyType, layoutInfo: scene.layoutInfo)
                enemy.updateTexture(forBossType: nextBossType)
                preparedEnemies.append((enemy, position))
            }
        }
    
    private func showPreparedWave() {
            guard !preparedEnemies.isEmpty else {
                setupEnemies()
                return
            }
            
            for (enemy, _) in preparedEnemies {
                enemies.append(enemy)
            }
            
            let orderedQueue = orderEnemiesForEntry(preparedEnemies)
            waveManager.startNextWave(enemies: orderedQueue)
            
            assignShooters()
            assignPowerUpDroppers()
            assignEnemyMovements()
            
            preparedEnemies.removeAll()
            
            if currentWave > 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.assignKamikazeEnemies()
                }
            }
        }
    func handleBulletCollision(bullet: SKNode, enemy: Enemy) {
        guard let bullet = bullet as? Bullet else { return }
        
        
        if enemy.takeDamage(bullet.damage) {
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
            
            // Delay activation of `canShoot` based on spawn animation duration
            let spawnAnimationDuration: TimeInterval = 2.0 // Adjust based on your animation duration
            DispatchQueue.main.asyncAfter(deadline: .now() + spawnAnimationDuration) {
                enemy.canShoot = true
            }
            
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
        let powerUpHolders = Array(0..<enemies.count).shuffled().prefix(1)
        
        for (indices, holderIndex) in powerUpHolders.enumerated() {
            let enemy = enemies[holderIndex]
            enemy.holdsPowerUp = true
            
        }
        
        
        
    }
    deinit {
        print("EnemyManager is being deallocated")
    }

}

