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
    private var Player: Player!
    
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
        Player = Orbit_Breaker.Player(scene: self)
        
        // Setup game elements
        setupGame()
    }
    
    private func setupGame() {
        enemyManager.setupEnemies()
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        enemyManager.update(currentTime: currentTime)
           Player.update(currentTime: currentTime)
       
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        

    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            Player.handleTouch(touch)
        }
        
    func didBegin(_ contact: SKPhysicsContact) {
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
        
        // Check if the contact is between a bullet and an enemy
        if let bullet = nodeA as? Bullet, let enemy = nodeB as? Enemy {
            enemy.takeDamage(bullet.damage)
            bullet.removeFromParent()  // Remove the bullet after it hits
        } else if let bullet = nodeB as? Bullet, let enemy = nodeA as? Enemy {
            enemy.takeDamage(bullet.damage)
            bullet.removeFromParent()  // Remove the bullet after it hits
        }
    }

}


