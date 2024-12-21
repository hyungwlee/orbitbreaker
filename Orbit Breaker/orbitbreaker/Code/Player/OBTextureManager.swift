//
//  OBTextureManager.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 12/12/24.
//

import Foundation
import SpriteKit

class OBTextureManager {
    static let shared = OBTextureManager()
    private var textureCache: [String: SKTexture] = [:]
    
    private init() {}
    
    func preloadTextures() {
        
        let backgroundTextures = [
            "OBbackgroundANGER",
            "OBbackgroundSAD",
            "OBbackgroundDISGUST",
            "OBbackgroundLOVE"
        ]
        
        // Boss-related textures
        let bossTextures = [
            "OBanger", "OBsadness", "OBdisgust", "OBlove",
            "OBheart", "OBheartShield", "OBslimeBall", "OBFireball",
            "OBraindrop", "OBraincloud"
        ]
        
        // Enemy state textures for each boss type
        let enemyStates = ["OBBase", "OBDamaged1", "OBDamaged2", "OBDamaged3"]
        let bossTypes = ["OBAngry", "OBBreathe", "OBSad", "OBLove"]
        
        for bossType in bossTypes {
            for state in enemyStates {
                let textureName = "OB\(bossType) Face UFO (\(state))"
                textureCache[textureName] = SKTexture(imageNamed: textureName)
            }
        }
        
        // Cache boss textures
        for textureName in bossTextures {
            textureCache[textureName] = SKTexture(imageNamed: textureName)
        }
        
        for textureName in backgroundTextures {
                    let texture = SKTexture(imageNamed: textureName)
                    // Force texture to load immediately
                    texture.preload {
                        self.textureCache[textureName] = texture
                    }
                }
        
        let shieldTexture = SKTexture(imageNamed: "OBshield")
                textureCache["shield"] = shieldTexture
                shieldTexture.preload { }
                
                // Create and cache double damage texture
                let lightningBolt = SKShapeNode(rectOf: CGSize(width: 25, height: 25))
                let path = CGMutablePath()
                path.move(to: CGPoint(x: -5, y: 12))
                path.addLine(to: CGPoint(x: 2, y: 2))
                path.addLine(to: CGPoint(x: 8, y: 2))
                path.addLine(to: CGPoint(x: 0, y: -12))
                path.addLine(to: CGPoint(x: 5, y: -2))
                path.addLine(to: CGPoint(x: -2, y: -2))
                path.closeSubpath()
                
                lightningBolt.path = path
                lightningBolt.fillColor = .yellow
                lightningBolt.strokeColor = .orange
                lightningBolt.lineWidth = 2
                
                let powerupTexture = SKView().texture(from: lightningBolt)
                textureCache["powershot"] = powerupTexture
            
    }
    
    func getTexture(_ name: String) -> SKTexture? {
            return textureCache[name]
        }
}
