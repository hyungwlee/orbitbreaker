//
//  GameScene.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    private var contentCreated = false
    private var enemyManager: EnemyManager!
    private var testPlayer: TestPlayer!
    
    override func didMove(to view: SKView) {
        if !contentCreated {
            createContent()
            contentCreated = true
        }
    }
    
    private func createContent() {
        backgroundColor = .black
        
        // Set up physics world
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        // Initialize managers/systems
        enemyManager = EnemyManager(scene: self)
        testPlayer = TestPlayer(scene: self)
        
        // Setup game elements
        setupGame()
    }
    
    private func setupGame() {
        enemyManager.setupEnemies()
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        enemyManager.update(currentTime: currentTime)
           testPlayer.update(currentTime: currentTime)
       
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        

    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            testPlayer.handleTouch(touch)
        }
        
        func didBegin(_ contact: SKPhysicsContact) {
            guard let nodeA = contact.bodyA.node,
                  let nodeB = contact.bodyB.node else { return }
            
            // Handle player bullet hitting enemy
            if nodeA.name == "testBullet" && nodeB.name == "enemy",
               let enemy = nodeB as? Enemy {
                enemyManager.handleBulletCollision(bullet: nodeA, enemy: enemy)
            }
            else if nodeB.name == "testBullet" && nodeA.name == "enemy",
                    let enemy = nodeA as? Enemy {
                enemyManager.handleBulletCollision(bullet: nodeB, enemy: enemy)
            }
            
            // Handle enemy bullet hitting player
            if (nodeA.name == "enemyBullet" && nodeB.name == "testPlayer") ||
               (nodeB.name == "enemyBullet" && nodeA.name == "testPlayer") {
                let bullet = nodeA.name == "enemyBullet" ? nodeA : nodeB
                bullet.removeFromParent()
                // Add player hit feedback here if desired
            }
        }
}

