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
    private var contentCreated = false
    private var enemyManager: EnemyManager!
    private var Player: Player!
    private var debugControls: UIHostingController<DebugControls>?
    
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
            handleBulletEnemyCollision(bullet: bullet, enemy: enemy)
        } else if let bullet = nodeB as? Bullet, let enemy = nodeA as? Enemy {
            handleBulletEnemyCollision(bullet: bullet, enemy: enemy)
        }
    }
    
    private func handleBulletEnemyCollision(bullet: Bullet, enemy: Enemy) {
        // Remove bullet first
        bullet.removeFromParent()
        
        // Handle enemy damage
        if enemy.takeDamage(bullet.damage) {
            // If enemy should die
            enemy.removeFromParent()
            // Notify enemy manager
            enemyManager.handleEnemyDestroyed(enemy)
        }
    }
}


