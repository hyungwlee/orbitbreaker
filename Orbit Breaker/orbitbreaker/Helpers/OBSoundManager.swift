//
//  OBSoundManager.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 12/20/24.
//
import SpriteKit

class OBSoundManager {
    static let shared = OBSoundManager()
    private var sounds: [String: SKAction] = [:]
    private var scene: SKScene?
    
    private init() {}
    
    func setScene(_ scene: SKScene) {
        self.scene = scene
    }
    
    func preloadSounds() {
        let soundNames = [
            "OBannouncementSound.mp3",
            "OBloveShoot.mp3",
            "OBsadnessShoot.mp3",
            "OBdisgustShoot.mp3",
            "OBangerShoot.mp3",
            "OBloveShield.mp3",
            "OBloveShield1.mp3",
            "OBangerDive.mp3",
            "OBdisgustRing.mp3",
            "OBenemyHit.mp4a",
            "OBshieldDamaged.mp3",
            "OBpowerUp.mp3",
            "OBplayerDeath.mp3",
            "OBufo_descent.mp3",
            "OBnew_enemy_shoot.mp3",
            "OBbossDeath.mp3",
            "OBasteroidHit.mp3",  // Add asteroid-related sounds
            "OBasteroidWarning.mp3",
            "OBgameOver.mp3"
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

