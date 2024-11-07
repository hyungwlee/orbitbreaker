//
//  GameScene.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

import SpriteKit
import GameplayKit
import SwiftUI

class GameScene: SKScene, SKPhysicsContactDelegate {
    @State private var hasShield = false
    private var contentCreated = false
    private var enemyManager: EnemyManager!
    private var Player: Player!
    private var PowerUp: PowerUp!
    private var debugControls: UIHostingController<DebugControls>?
    var powerUpsDropped = 0
    let maxPowerUpsDropped = 3
    
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupDebugControls()
        if !contentCreated {
            createContent()
            contentCreated = true
        }
    }
    
    private func setupDebugControls() {
        #if DEBUG
        let debugView = DebugControls(isVisible: .constant(true)) { [weak self] in
            self?.startNextWave()
        }
        
        let hostingController = UIHostingController(rootView: debugView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = CGRect(x: 10, y: 30, width: 120, height: 100)
        
        self.view?.addSubview(hostingController.view)
        self.debugControls = hostingController
        #endif
    }
    
    deinit {
        debugControls?.view.removeFromSuperview()
    }
    private func startNextWave() {
        // Force cleanup of any existing enemies
        enemyManager.forceCleanup()
        // Setup next wave
        enemyManager.setupEnemies()
        
        powerUpsDropped = 0
    }
    
    private func createContent() {
        backgroundColor = .black
        
        // Set up physics world
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        // Initialize managers/systems
        enemyManager = EnemyManager(scene: self)
        Player = Orbit_Breaker.Player(scene: self)
        
        // Setup game elements
        setupGame()
    }
    
    private func setupGame() {
        // Add a slight delay to ensure everything is properly initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.enemyManager.setupEnemies()
        }
    }
    
    // Fixed update method - removed duplicate
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        enemyManager.update(currentTime: currentTime)
        Player.update(currentTime: currentTime)
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        Player.handleTouch(touch)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
            let nodeA = contact.bodyA.node
            let nodeB = contact.bodyB.node

            // Check bullet-enemy collisions
            if let bullet = nodeA as? Bullet, let enemy = nodeB as? Enemy {
               handleBulletEnemyCollision(bullet: bullet, enemy: enemy)
            } else if let bullet = nodeB as? Bullet, let enemy = nodeA as? Enemy {
               handleBulletEnemyCollision(bullet: bullet, enemy: enemy)
            }

            // Check player-enemy bullet collisions
            if let bullet = nodeA, let player = nodeB,
               (bullet.name == "enemyBullet" && player.name == "testPlayer") {
                if !Player.hasShield {  // Use Player's shield state
                    handlePlayerHit()
                } else {
                    Player.hasShield = false
                    Player.removeShield()
                }
                bullet.removeFromParent()
            } else if let bullet = nodeB, let player = nodeA,
                      (bullet.name == "enemyBullet" && player.name == "testPlayer") {
                if !Player.hasShield {  // Use Player's shield state
                    handlePlayerHit()
                } else {
                    Player.hasShield = false
                    Player.removeShield()
                }
                bullet.removeFromParent()
            }
        
            // Check player-powerUp collisions
            if let powerUp = nodeA as? PowerUp, let player = nodeB,
               (powerUp.name == "powerUp" && player.name == "testPlayer") {
                powerUp.apply(to: Player)
                powerUp.removeFromParent()
            } else if let powerUp = nodeB as? PowerUp, let player = nodeA,
                      (powerUp.name == "powerUp" && player.name == "testPlayer") {
                powerUp.apply(to: Player)
                powerUp.removeFromParent()
            }

            // Check player-boss collisions
            if let _ = nodeA as? Boss, let player = nodeB as? SKSpriteNode,
               player.name == "testPlayer" {
                if !Player.hasShield {  // Use Player's shield state
                    handlePlayerHit()
                } else {
                    Player.hasShield = false
                    Player.removeShield()
                }
            } else if let _ = nodeB as? Boss, let player = nodeA as? SKSpriteNode,
                      player.name == "testPlayer" {
                if !Player.hasShield {  // Use Player's shield state
                    handlePlayerHit()
                } else {
                    Player.hasShield = false
                    Player.removeShield()
                }
            }
        }
    
    private func restartGame() {
            // Remove game over screen and all other nodes
            removeAllChildren()
            
            // Reset game state
            isPaused = false
            
            // Reset enemy manager and wave count
            enemyManager = EnemyManager(scene: self)
            
            // Create new content
            createContent()
        }
    
    private func gameOver() {
            // Stop all gameplay
            isPaused = true
            
            // Clean up all game objects
            cleanupLevel()
            
            // Create game over label
            let gameOverLabel = SKLabelNode(fontNamed: "Arial")
            gameOverLabel.text = "Game Over"
            gameOverLabel.fontSize = 50
            gameOverLabel.fontColor = .red
            gameOverLabel.position = CGPoint(x: size.width/2, y: size.height/2)
            addChild(gameOverLabel)
            
            // Add restart button
            let restartLabel = SKLabelNode(fontNamed: "Arial")
            restartLabel.text = "Tap to Restart"
            restartLabel.fontSize = 30
            restartLabel.fontColor = .white
            restartLabel.position = CGPoint(x: size.width/2, y: size.height/2 - 50)
            restartLabel.name = "restartButton"
            addChild(restartLabel)
        }
        
        private func cleanupLevel() {
            // Remove all bullets
            enumerateChildNodes(withName: "testBullet") { node, _ in
                node.removeFromParent()
            }
            enumerateChildNodes(withName: "enemyBullet") { node, _ in
                node.removeFromParent()
            }
            enumerateChildNodes(withName: "powerUp") { node, _ in
                node.removeFromParent()
            }
            
            // Remove all enemies through enemy manager
            enemyManager.cleanupAllEnemies()
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            
            // Check if game is over and restart was tapped
            if isPaused {
                let nodes = nodes(at: location)
                if nodes.contains(where: { $0.name == "restartButton" }) {
                    restartGame()
                }
            }
        }
    
    private func handlePlayerHit() {
            print("Player was hit!")
            // Play hit effect
            if let playerNode = childNode(withName: "testPlayer") {
                let flash = SKAction.sequence([
                    SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.1),
                    SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
                ])
                playerNode.run(flash)
            }
            
            // Clean up the player
            Player.cleanup()
            
            // Game over
            gameOver()
        }
    
    private func handleBulletEnemyCollision(bullet: Bullet, enemy: Enemy) {
        // Remove bullet first
        bullet.removeFromParent()
        
        // Handle enemy damage
        if enemy.takeDamage(bullet.damage) {
            enemy.dropPowerUp(scene: self)
//            if (powerUpsDropped < maxPowerUpsDropped){
//                powerUpsDropped += enemy.dropPowerUp()
//            }
            // If enemy should die
            enemy.removeFromParent()
            // Notify enemy manager
            enemyManager.handleEnemyDestroyed(enemy)
        }
    }
    
    
//    func canDropPowerUps() -> Bool{
//        return (powerUpsDropped <= maxPowerUpsDropped)
//    }
    
}


