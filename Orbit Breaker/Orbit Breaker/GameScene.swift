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
    private var user: Player!
    private var PowerUp: PowerUp!
    private var debugControls: UIHostingController<DebugControls>?
    var powerUpsDropped = 0
    let maxPowerUpsDropped = 3
    private var score: Int = 0
    private var scoreLabel: SKLabelNode!
    
    var background1: SKSpriteNode!
    var background2: SKSpriteNode!
    
    
    override func didMove(to view: SKView) {
            super.didMove(to: view)
  //          setupDebugControls()
            if !contentCreated {
                createContent()
                contentCreated = true
            }
        
        
                // Initialize and add the background nodes
                background1 = SKSpriteNode(imageNamed: "background")
                background1.size = CGSize(width: size.width, height: size.height)
                background1.position = CGPoint(x: size.width / 2, y: size.height / 2)
                background1.zPosition = -1
                addChild(background1)
                
                background2 = SKSpriteNode(imageNamed: "background")
                background2.size = CGSize(width: size.width, height: size.height)
                background2.position = CGPoint(x: size.width / 2, y: background1.position.y + size.height)
                background2.zPosition = -1
                addChild(background2)
                
                // Define scrolling actions
                let moveDown = SKAction.moveBy(x: 0, y: -size.height, duration: 5.0)
                let resetPosition = SKAction.moveBy(x: 0, y: size.height, duration: 0.0)
                let scrollLoop = SKAction.sequence([moveDown, resetPosition])
                let continuousScroll = SKAction.repeatForever(scrollLoop)
                
                // Apply actions to both backgrounds
                background1.run(continuousScroll)
                background2.run(continuousScroll)
            
        
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

    
    private func createContent() {
           
        let background1 = SKSpriteNode(imageNamed: "background")
            background1.size = self.size
            background1.position = CGPoint(x: size.width / 2, y: size.height / 2)
            background1.zPosition = -1
            addChild(background1)
            
        let background2 = SKSpriteNode(imageNamed: "background")
            background2.size = self.size
            background2.position = CGPoint(x: size.width / 2, y: background1.position.y + size.height)
            background2.zPosition = -1
            addChild(background2)
            
            // Start scrolling
            let moveDown = SKAction.moveBy(x: 0, y: -size.height, duration: 5.0)
            let resetPosition = SKAction.moveBy(x: 0, y: size.height, duration: 0.0)
            let scrollLoop = SKAction.sequence([moveDown, resetPosition])
            let continuousScroll = SKAction.repeatForever(scrollLoop)
            
            background1.run(continuousScroll)
            background2.run(continuousScroll)
            // Set up physics world
            physicsWorld.gravity = CGVector(dx: 0, dy: 0)
            physicsWorld.contactDelegate = self
            
            // Initialize managers/systems
            enemyManager = EnemyManager(scene: self)
            user = Orbit_Breaker.Player(scene: self)
            
            // Setup score label
            setupScoreLabel()
            
            // Setup game elements
            setupGame()
        }
        
        private func setupScoreLabel() {
            scoreLabel = SKLabelNode(fontNamed: "Arial")
            scoreLabel.text = "Score: 0"
            scoreLabel.fontSize = 24
            scoreLabel.fontColor = .white
            scoreLabel.horizontalAlignmentMode = .right
            scoreLabel.position = CGPoint(x: size.width - 20, y: size.height - 40)
            addChild(scoreLabel)
        }
        
        private func updateScore(_ points: Int) {
            score += points
            scoreLabel.text = "Score: \(score)"
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
        user.update(currentTime: currentTime)
        
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        user.handleTouch(touch)
    }
    
    private func startNextWave() {
            // Ensure power-ups and timers are removed before starting next wave
            user.removeShield()
            user.removeDamageBoost()
            
            // Force cleanup of any existing enemies
            enemyManager.forceCleanup()
            
            // Setup next wave
            enemyManager.setupEnemies()
            
            powerUpsDropped = 0
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

           // Handle player collisions with enemy bullets
           if let bullet = nodeA, let playerNode = nodeB as? SKSpriteNode,
              bullet.name == "enemyBullet" && playerNode.name == "testPlayer" {
               handlePlayerBulletCollision(bullet)
           } else if let bullet = nodeB, let playerNode = nodeA as? SKSpriteNode,
                     bullet.name == "enemyBullet" && playerNode.name == "testPlayer" {
               handlePlayerBulletCollision(bullet)
           }

           // Handle power-up collisions
           if let powerUp = nodeA as? PowerUp, let playerNode = nodeB as? SKSpriteNode,
              powerUp.name == "powerUp" && playerNode.name == "testPlayer" {
               handlePowerUpCollision(powerUp)
           } else if let powerUp = nodeB as? PowerUp, let playerNode = nodeA as? SKSpriteNode,
                     powerUp.name == "powerUp" && playerNode.name == "testPlayer" {
               handlePowerUpCollision(powerUp)
           }
       }

       private func handlePlayerBulletCollision(_ bullet: SKNode) {
           if user.hasShield {
               user.removeShield()  // This will set hasShield to false and remove the shield node
               bullet.removeFromParent()
           } else {
               handlePlayerHit()
           }
       }

       private func handlePowerUpCollision(_ powerUp: PowerUp) {
           powerUp.apply(to: user)
           powerUp.removeFromParent()
       }

       private func handlePlayerHit() {
           print("Player was hit!")
           if let playerNode = childNode(withName: "testPlayer") {
               let flash = SKAction.sequence([
                   SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.1),
                   SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
               ])
               playerNode.run(flash)
           }
           
           user.cleanup()
           gameOver()
       }
    
    private func restartGame() {
            // Reset score
            score = 0
            scoreLabel.text = "Score: 0"
            
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

    
    private func handleBulletEnemyCollision(bullet: Bullet, enemy: Enemy) {
            bullet.removeFromParent()
            
            if enemy.takeDamage(bullet.damage) {
                // Add score based on enemy type
                if enemy is Boss {
                    updateScore(500)  // Boss kill
                } else {
                    updateScore(10)   // Regular enemy kill
                }
                
                enemy.dropPowerUp(scene: self)
                enemy.removeFromParent()
                enemyManager.handleEnemyDestroyed(enemy)
            }
        }
    
    
}


