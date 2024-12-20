//
//  GameScene.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

import SpriteKit
import GameplayKit
import SwiftUI
import CoreHaptics
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    @State private var hasShield = false
    private var contentCreated = false
    var enemyManager: EnemyManager!
    var user: Player!
    private var PowerUp: PowerUp!
    private var debugControls: UIHostingController<DebugControls>?
    var powerUpsDropped = 0
    let maxPowerUpsDropped = 3
    private var score: Int = 0
    private var scoreLabel: SKLabelNode!
    var powerUpManager: PowerUpManager!
    private var waveRoadmap: WaveRoadmap?
    
    var bossCount = 0
    var background1: SKSpriteNode!
    var background2: SKSpriteNode!
    var hapticsEngine: CHHapticEngine?
    
    private var didSceneLoad: Bool = false
    var backgroundMusicPlayer: AVAudioPlayer?
    var audioPlayers: [String: AVAudioPlayer] = [:]
    
    weak var context: GameContext?
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        initializeHaptics()
        // setupDebugControls()
        powerUpManager = PowerUpManager(scene: self)
        super.didMove(to: view)
        didSceneLoad = true
        if !contentCreated {
            createContent()
            contentCreated = true
        }
        
        guard let layoutInfo = context?.layoutInfo else { return }

        
        // Initialize background
        setupBackgroundScrolling()
        
        // Set the scene and preload sounds
        SoundManager.shared.setScene(self)
        SoundManager.shared.preloadSounds()
        
        // Start music playback
        playBackgroundMusic()
        preloadSounds()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

    }
    
//    override func didMove(to view: SKView) {
//        super.didMove(to: view)
//
//        initializeHaptics()
//        powerUpManager = PowerUpManager(scene: self)
//
//        // Ensure layoutInfo is available
//        guard let layoutInfo = context?.layoutInfo else { return }
//
//        // Example: Set up the background using layoutInfo
//        setupBackgroundScrolling()
//
//        // Scale and position other assets dynamically
//        setupGameNodes(using: layoutInfo)
//
//        // Set the scene and preload sounds
//        SoundManager.shared.setScene(self)
//        SoundManager.shared.preloadSounds()
//
//        // Start background music playback
//        playBackgroundMusic()
//        preloadSounds()
//
//        // Notifications for app lifecycle events
//        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
//
//        didSceneLoad = true
//        if !contentCreated {
//            createContent()
//            contentCreated = true
//        }
//    }

//    func setupGameNodes(using layoutInfo: LayoutInfo) {
//        // Example: Create a node and scale it dynamically
//        let sprite = SKSpriteNode(imageNamed: "exampleNode")
//        sprite.size = layoutInfo.nodeSize   // Use calculated size
//        sprite.position = layoutInfo.nodePosition // Use calculated position
//        addChild(sprite)
//        
//        // Repeat for other nodes if needed
//    }

    
    func playBackgroundMusic() {
        guard let musicURL = Bundle.main.url(forResource: "backgroundMusic", withExtension: "mp3") else {
            print("Background music file not found")
            return
        }
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
            backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
            backgroundMusicPlayer?.volume = 0.1       // Set the volume (0.0 to 1.0)
            backgroundMusicPlayer?.play()
        } catch {
            print("Error loading background music: \(error.localizedDescription)")
        }
    }
    
    func preloadSounds() {
        let sounds = ["backgroundMusic.mp3"]
        for soundName in sounds {
            if let url = Bundle.main.url(forResource: soundName, withExtension: nil) {
                do {
                    let audioPlayer = try AVAudioPlayer(contentsOf: url)
                    audioPlayer.prepareToPlay()  // Prepares the player to reduce latency
                    audioPlayers[soundName] = audioPlayer
                } catch {
                    print("Error loading sound: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func preloadGame() {
            // Pre-load all textures at game start
            TextureManager.shared.preloadTextures()
        }
    
    private func setupBackgroundScrolling() {
        bossCount = 0

        // Initialize and add background 1
        background1 = SKSpriteNode(imageNamed: "backgroundANGER")
        background1.size = CGSize(width: size.width, height: size.height)
        background1.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background1.zPosition = -2
        addChild(background1)
        
        // Add a dark overlay to background 1
        let darkOverlay1 = SKSpriteNode(color: SKColor.black, size: background1.size)
        darkOverlay1.alpha = 0.25 // Adjust opacity to control darkness
        darkOverlay1.position = background1.position
        darkOverlay1.zPosition = -1 // In front of the background
        addChild(darkOverlay1)

        // Initialize and add background 2
        background2 = SKSpriteNode(imageNamed: "backgroundANGER")
        background2.size = CGSize(width: size.width, height: size.height)
        background2.position = CGPoint(x: size.width / 2, y: background1.position.y + size.height)
        background2.zPosition = -2
        addChild(background2)
        
        // Add a dark overlay to background 2
        let darkOverlay2 = SKSpriteNode(color: SKColor.black, size: background2.size)
        darkOverlay2.alpha = 0.25 // Adjust opacity to match the first overlay
        darkOverlay2.position = background2.position
        darkOverlay2.zPosition = -1
        addChild(darkOverlay2)

        // Define scrolling actions
        let moveDown = SKAction.moveBy(x: 0, y: -size.height, duration: 5.0)
        let resetPosition = SKAction.moveBy(x: 0, y: size.height, duration: 0.0)
        let scrollLoop = SKAction.sequence([moveDown, resetPosition])
        let continuousScroll = SKAction.repeatForever(scrollLoop)

        // Apply actions to both backgrounds and overlays
        background1.run(continuousScroll)
        background2.run(continuousScroll)
        darkOverlay1.run(continuousScroll)
        darkOverlay2.run(continuousScroll)
    }

    private func setupDebugControls() {
          #if DEBUG
          let debugView = DebugControls(isVisible: .constant(true)) { [weak self] in
              self?.enemyManager.skipCurrentWave()
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
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
    }
    
    private func createContent() {
           guard let layoutInfo = self.context?.layoutInfo else { return }

           setupBackgroundScrolling()
           
           // Set up physics world
           physicsWorld.gravity = CGVector(dx: 0, dy: 0)
           physicsWorld.contactDelegate = self
           
           // Initialize managers/systems
           enemyManager = EnemyManager(scene: self, layoutInfo: layoutInfo)
           user = Orbit_Breaker.Player(scene: self, layoutInfo: layoutInfo)
           
           // Setup score label
           setupScoreLabel()
           
           // Setup game elements
           setupGame()
           
       }
    
    // Call this function when the boss is defeated
    func onBossDefeated(_ boss: Boss) {
            let newBackground: String
            
            switch boss.bossType {
            case .anger: newBackground = "backgroundSAD"
            case .sadness: newBackground = "backgroundDISGUST"
            case .disgust: newBackground = "backgroundLOVE"
            case .love: newBackground = "backgroundANGER"
            }
            
            // Get pre-loaded texture
            if let newTexture = TextureManager.shared.getTexture(newBackground) {
                // Perform the fade transition
                let fadeOutAction = SKAction.fadeOut(withDuration: 1.0)
                let fadeInAction = SKAction.fadeIn(withDuration: 1.0)
                
                background1.run(fadeOutAction) {
                    self.background1.texture = newTexture
                    self.background1.run(fadeInAction)
                }
                
                background2.run(fadeOutAction) {
                    self.background2.texture = newTexture
                    self.background2.run(fadeInAction)
                }
            } else {
                // Fallback if texture isn't cached
                background1.texture = SKTexture(imageNamed: newBackground)
                background2.texture = SKTexture(imageNamed: newBackground)
            }
        }
    
    private func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .right
        
        let screenHeight = UIScreen.main.bounds.height
        let isiPhoneSE = screenHeight <= 667 // SE (2nd gen) has 667 points height
        
        if isiPhoneSE {
            // Specific padding adjustment for iPhone SE
            scoreLabel.position = CGPoint(x: size.width - 20, y: size.height - 30)
        } else {
            scoreLabel.position = CGPoint(x: size.width - 20, y: size.height - 80)
        }
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
        powerUpManager.update(currentTime: currentTime)
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
    private func shieldHit(_ shield: SKSpriteNode) {
        // Find boss in the scene
        enumerateChildNodes(withName: "boss") { node, _ in
            if let boss = node as? Boss {
                boss.damageShield(shield)
            }
        }
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
        
        
        // Handle asteroid collisions
        if (contact.bodyA.categoryBitMask == 0x1 << 6 && contact.bodyB.node?.name == "testPlayer") ||
            (contact.bodyB.categoryBitMask == 0x1 << 6 && contact.bodyA.node?.name == "testPlayer") {
            handlePlayerHit()
        }
        
        // Check for heart shield collision with bullets
        if let bullet = nodeA as? Bullet, let shield = nodeB as? SKSpriteNode,
           shield.name == "heartShield" {
            bullet.removeFromParent()
            shieldHit(shield)
        } else if let bullet = nodeB as? Bullet, let shield = nodeA as? SKSpriteNode,
                  shield.name == "heartShield" {
            bullet.removeFromParent()
            shieldHit(shield)
        }
        
        // Check for slime trail collision with player
        if let cloud = nodeA as? SKShapeNode, let player = nodeB as? SKSpriteNode,
           cloud.fillColor == .init(red: 0.2, green: 0.8, blue: 0.2, alpha: 0.5),
           player.name == "testPlayer" {
            handlePlayerHit()
        } else if let cloud = nodeB as? SKShapeNode, let player = nodeA as? SKSpriteNode,
                  cloud.fillColor == .init(red: 0.2, green: 0.8, blue: 0.2, alpha: 0.5),
                  player.name == "testPlayer" {
            handlePlayerHit()
        }

        // Add check for boss intro state
        if let bullet = nodeA as? Bullet, let boss = nodeB as? Boss {
            if !boss.hasEnteredScene {
                bullet.removeFromParent()
                return
            }
            handleBulletEnemyCollision(bullet: bullet, enemy: boss)
        } else if let bullet = nodeB as? Bullet, let boss = nodeA as? Boss {
            if !boss.hasEnteredScene {
                bullet.removeFromParent()
                return
            }
            handleBulletEnemyCollision(bullet: bullet, enemy: boss)
        }
        
        // Handle player collision with enemy
        if (nodeA?.name == "testPlayer" && nodeB is Enemy) ||
            (nodeB?.name == "testPlayer" && nodeA is Enemy) {
            handlePlayerHit()
            return
        }
        
        // Check bullet-enemy collisions
        if let bullet = nodeA as? Bullet, let enemy = nodeB as? Enemy {
            handleBulletEnemyCollision(bullet: bullet, enemy: enemy)
            playHapticFeedback()
        } else if let bullet = nodeB as? Bullet, let enemy = nodeA as? Enemy {
            handleBulletEnemyCollision(bullet: bullet, enemy: enemy)
            playHapticFeedback()
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
            SoundManager.shared.playSound("shieldDamaged.mp3")
            user.removeShield()  // This will set hasShield to false and remove the shield node
            powerUpManager.hideShieldIndicator()  // Add this line to hide the shield indicator
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
        if let playerNode = childNode(withName: "testPlayer") {
            // Disable player shooting immediately
            user.canShoot = false
            user.cleanup()
            
            // Show death effects first, then do cleanup
            VisualEffects.addPlayerDeathEffect(at: playerNode.position, in: self) { [weak self] in
                guard let self = self else { return }
                
                // Do thorough cleanup after death animation
                self.cleanupLevel()
                
                enumerateChildNodes(withName: "boss") { node, _ in
                    if let boss = node as? Boss {
                        boss.cleanup()
                    }
                }
                
                // Additional thorough cleanup for any remaining effects
                self.enumerateChildNodes(withName: "//*") { node, _ in
                    if let sprite = node as? SKSpriteNode,
                       sprite.texture?.description.contains("raincloud") == true {
                        sprite.removeAllActions()
                        sprite.removeFromParent()
                    }
                }
                
                // Clean up any active boss effects
                self.enemyManager.getAllEnemies().forEach { enemy in
                    if let boss = enemy as? Boss {
                        boss.cleanup()
                    }
                    enemy.removeFromParent()
                }
                
                // Remove all enemy bullets
                self.enumerateChildNodes(withName: "enemyBullet") { node, _ in
                    node.removeAllActions()
                    node.removeFromParent()
                }
                
                // Finally show game over
                self.gameOver()
            }
        }
    }
    
    func initializeHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticsEngine = try CHHapticEngine()
            try hapticsEngine?.start()
        } catch {
            print("Haptics Engine Error: \(error.localizedDescription)")
        }
    }
    
    func playHapticFeedback() {
        guard let engine = hapticsEngine else { return }
        
        do {
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [sharpness, intensity], relativeTime: 0)
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic feedback: \(error.localizedDescription)")
        }
    }
    
    func assignEnemyMovements() {
        guard let enemies = enemyManager?.getAllEnemies() else { return }
        
        for (index, enemy) in enemies.enumerated() {
            // Skip bosses
            guard !(enemy is Boss) else { continue }
            
            // Assign different movement patterns based on position or random chance
            let pattern: Enemy.MovementPattern
            switch index % 4 {
            case 0: pattern = .oscillate
            case 1: pattern = .circle
            case 2: pattern = .figure8
            default: pattern = .dive
            }
            
            enemy.addDynamicMovement(pattern)
        }
    }
    
    private func restartGame() {
        // Reset score
        score = 0
        scoreLabel.text = "Score: 0"
        
        guard let layoutInfo = self.context?.layoutInfo else {
            fatalError("LayoutInfo is nil. Ensure context is properly set in GameContext.")
        }

        // Cleanup the roadmap before removing all children
        waveRoadmap?.cleanup()
        waveRoadmap = nil
        
        // Remove all nodes
        removeAllChildren()
        
        // Reset game state
        isPaused = false
        
        // Reset enemy manager and wave count
        enemyManager = EnemyManager(scene: self, layoutInfo: layoutInfo)
        
        // Reset power up manager
        powerUpManager = PowerUpManager(scene: self)
        
        // Create new content
        createContent()
        
        // Reset user shooting ability
        user.canShoot = true  // Add this line
        
        // Restart background music
        backgroundMusicPlayer?.stop()           // Stop playback if it's still playing
        backgroundMusicPlayer?.currentTime = 0  // Reset playback position to the beginning
        backgroundMusicPlayer?.play()           // Start playback from the beginning
    }
    
    private func gameOver() {
        // Ensure we're on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Clean up all game objects
            self.cleanupLevel()
            
            // Create game over label
            let gameOverLabel = SKLabelNode(fontNamed: "Arial")
            gameOverLabel.text = "Game Over"
            gameOverLabel.fontSize = 50
            gameOverLabel.fontColor = .red
            gameOverLabel.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
            gameOverLabel.zPosition = 1000  // Ensure it's above everything
            self.addChild(gameOverLabel)
            
            // Add restart button
            let restartLabel = SKLabelNode(fontNamed: "Arial")
            restartLabel.text = "Tap to Restart"
            restartLabel.fontSize = 30
            restartLabel.fontColor = .white
            restartLabel.position = CGPoint(x: self.size.width/2, y: self.size.height/2 - 50)
            restartLabel.name = "restartButton"
            restartLabel.zPosition = 1000  // Ensure it's above everything
            self.addChild(restartLabel)
            
            // Set isPaused after adding game over UI
            self.isPaused = true
            
            backgroundMusicPlayer?.stop()

        }
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
            
            // Remove all heart shields
            enumerateChildNodes(withName: "heartShield") { node, _ in
                node.physicsBody = nil
                node.removeFromParent()
            }
            
            // Remove all toxic trails (slime nodes)
            enumerateChildNodes(withName: "//*") { node, _ in
                if let cloud = node as? SKShapeNode,
                   cloud.physicsBody?.categoryBitMask == 0x1 << 3,  // Check for enemy bullet category
                   cloud.fillColor == .init(red: 0.2, green: 0.8, blue: 0.2, alpha: 0.5),
                   cloud.strokeColor == .green {
                    // First remove any glow effects
                    cloud.removeAllChildren()
                    // Remove physics body
                    cloud.physicsBody = nil
                    // Remove any remaining actions
                    cloud.removeAllActions()
                    // Finally remove the node
                    cloud.removeFromParent()
                }
            }
            
            // Remove all enemies through enemy manager
            enemyManager.cleanupAllEnemies()
        }
    
    @objc private func handleAppWillResignActive() {
        backgroundMusicPlayer?.pause()
    }
    
    @objc private func handleAppWillEnterForeground() {
        if let musicPlayer = backgroundMusicPlayer, !musicPlayer.isPlaying {
            musicPlayer.play()  // Resume the music if it’s not already playing
            print("App has come to the foreground, music resumed.")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if isPaused {
            // Use converted point for better touch detection
            let touchedNodes = nodes(at: location)
            if touchedNodes.contains(where: { $0.name == "restartButton" }) {
                isPaused = false  // Unpause before restart
                restartGame()
            }
            return
        }
        
        // Only handle regular touches if not paused
        if !isPaused {
            user.handleTouch(touch)
        }
    }
    
    
    private func handleBulletEnemyCollision(bullet: Bullet, enemy: Enemy) {
        bullet.removeFromParent()
        
        if enemy.takeDamage(bullet.damage) {
            // Add explosion effect
            
            // Add screen shake for boss defeats
            // Check if it's a boss defeat
                       if let boss = enemy as? Boss {
                           // Create epic boss defeat sequence
                           handleBossDefeat(boss)
                           updateScore(100)
            } else {
                // Regular enemy defeat
                VisualEffects.addExplosion(at: enemy.position, in: self)
                updateScore(10)
            }
            
            enemy.dropPowerUp(scene: self)
            enemy.removeFromParent()
            enemyManager.handleEnemyDestroyed(enemy)
        }
    }
    
    private func handleBossDefeat(_ boss: Boss) {
            // Create multiple explosion waves
        SoundManager.shared.playSound("bossDeath.mp3")
            for i in 0...3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    // Create expanding ring
                    let ring = SKShapeNode(circleOfRadius: 10)
                    ring.position = boss.position
                    ring.strokeColor = boss.bossType.color
                    ring.lineWidth = 3
                    ring.zPosition = 5
                    self.addChild(ring)
                    
                    // Expand and fade ring
                    let expand = SKAction.scale(to: 20, duration: 0.5)
                    let fade = SKAction.fadeOut(withDuration: 0.5)
                    ring.run(SKAction.sequence([
                        SKAction.group([expand, fade]),
                        SKAction.removeFromParent()
                    ]))
                }
            }
            
            // Add multiple particle explosions
            for _ in 0...8 {
                let delay = Double.random(in: 0...0.5)
                let position = CGPoint(
                    x: boss.position.x + CGFloat.random(in: -50...50),
                    y: boss.position.y + CGFloat.random(in: -50...50)
                )
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    VisualEffects.addExplosion(at: position, in: self)
                }
            }
            
            // Add screen flash
            let flash = SKSpriteNode(color: boss.bossType.color, size: self.size)
            flash.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
            flash.zPosition = 100
            flash.alpha = 0
            addChild(flash)
            
            flash.run(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ]))
            
            // Add boss-specific effects
            switch boss.bossType {
            case .anger:
                // Add flame particles spiraling outward
                for i in 0...12 {
                    let angle = CGFloat(i) * .pi * 2 / 12
                    let flame = SKSpriteNode(color: .orange, size: CGSize(width: 10, height: 10))
                    flame.position = boss.position
                    flame.zPosition = 4
                    addChild(flame)
                    
                    let path = UIBezierPath()
                    path.move(to: .zero)
                    path.addCurve(
                        to: CGPoint(x: cos(angle) * 200, y: sin(angle) * 200),
                        controlPoint1: CGPoint(x: cos(angle) * 100, y: sin(angle) * 100),
                        controlPoint2: CGPoint(x: cos(angle) * 150, y: sin(angle) * 150)
                    )
                    
                    let follow = SKAction.follow(path.cgPath, asOffset: true, orientToPath: true, duration: 1.0)
                    flame.run(SKAction.sequence([follow, SKAction.removeFromParent()]))
                }
                
            case .sadness:
                // Add rain drops falling upward
                for _ in 0...20 {
                    let raindrop = SKSpriteNode(color: .blue, size: CGSize(width: 3, height: 10))
                    raindrop.position = CGPoint(
                        x: boss.position.x + CGFloat.random(in: -100...100),
                        y: boss.position.y
                    )
                    raindrop.zPosition = 4
                    addChild(raindrop)
                    
                    let moveUp = SKAction.moveBy(x: 0, y: 200, duration: 1.0)
                    let fade = SKAction.fadeOut(withDuration: 1.0)
                    raindrop.run(SKAction.sequence([
                        SKAction.group([moveUp, fade]),
                        SKAction.removeFromParent()
                    ]))
                }
                
            case .disgust:
                // Add toxic burst effect
                for _ in 0...15 {
                    let toxic = SKShapeNode(circleOfRadius: 5)
                    toxic.fillColor = .green
                    toxic.strokeColor = .clear
                    toxic.position = boss.position
                    toxic.zPosition = 4
                    addChild(toxic)
                    
                    let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
                    let distance = CGFloat.random(in: 100...200)
                    let vector = CGVector(
                        dx: cos(angle) * distance,
                        dy: sin(angle) * distance
                    )

                    let move = SKAction.move(by: vector, duration: 0.8)
                    let fade = SKAction.fadeOut(withDuration: 0.8)
                    toxic.run(SKAction.sequence([
                        SKAction.group([move, fade]),
                        SKAction.removeFromParent()
                    ]))
                }
                
            case .love:
                // Add hearts bursting outward
                for _ in 0...12 {
                    let heart = SKSpriteNode(imageNamed: "heart")
                    heart.size = CGSize(width: 20, height: 20)
                    heart.position = boss.position
                    heart.zPosition = 4
                    addChild(heart)
                    
                    let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
                    let distance = CGFloat.random(in: 100...200)
                    
                    let moveAction = SKAction.move(
                        by: CGVector(dx: cos(angle) * distance, dy: sin(angle) * distance),
                        duration: 1.0
                    )
                    let rotateAction = SKAction.rotate(byAngle: .pi * 4, duration: 1.0)
                    let fadeAction = SKAction.fadeOut(withDuration: 1.0)
                    
                    heart.run(SKAction.sequence([
                        SKAction.group([moveAction, rotateAction, fadeAction]),
                        SKAction.removeFromParent()
                    ]))
                }
            }
            
            // Add intense screen shake
            VisualEffects.addScreenShake(to: self, intensity: 30)
            
            // Add victory text
            let victoryLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            victoryLabel.text = "\(String(describing: boss.bossType).capitalized) Defeated!"
            victoryLabel.fontSize = 40
            victoryLabel.fontColor = boss.bossType.color
       
        // Resize font based on screen size
        let maxWidth = self.size.width * 0.95 // Allow some padding
               while victoryLabel.frame.width > maxWidth {
                   victoryLabel.fontSize -= 1 // Reduce font size until it fits
               }
        
        
            victoryLabel.position = CGPoint(x: size.width/2, y: size.height/2)
            victoryLabel.setScale(0)
            victoryLabel.zPosition = 101
            addChild(victoryLabel)
            
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
            let wait = SKAction.wait(forDuration: 1.0)
            let fade = SKAction.fadeOut(withDuration: 0.3)
            
            victoryLabel.run(SKAction.sequence([
                scaleUp,
                scaleDown,
                wait,
                fade,
                SKAction.removeFromParent()
            ]))
        
        onBossDefeated(boss);
        }
    
}


extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}

class SoundManager {
    static let shared = SoundManager()
    private var sounds: [String: SKAction] = [:]
    private var scene: SKScene?
    
    private init() {}
    
    func setScene(_ scene: SKScene) {
        self.scene = scene
    }
    
    func preloadSounds() {
        let soundNames = [
            "announcementSound.mp3",
            "loveShoot.mp3",
            "sadnessShoot.mp3",
            "disgustShoot.mp3",
            "angerShoot.mp3",
            "loveShield.mp3",
            "loveShield1.mp3",
            "angerDive.mp3",
            "disgustRing.mp3",
            "enemyHit.mp4a",
            "shieldDamaged.mp3",
            "powerUp.mp3",
            "playerDeath.mp3",
            "ufo_descent.mp3",
            "new_enemy_shoot.mp3",
            "bossDeath.mp3",
            "asteroidHit.mp3",  // Add asteroid-related sounds
            "asteroidWarning.mp3"
        ]
        
        for name in soundNames {
            if let sound = SKAction.playSoundFileNamed(name, waitForCompletion: false) as SKAction? {
                sounds[name] = sound
            } else {
                print("Warning: Could not find sound file: \(name)")
            }
        }
    }
    
    func playSound(_ name: String) {
        guard let scene = scene else {
            print("Warning: No scene set for SoundManager")
            return
        }
        
        guard let sound = sounds[name] else {
            print("Warning: Sound \(name) not loaded")
            return
        }
        
        scene.run(sound)
    }
}

