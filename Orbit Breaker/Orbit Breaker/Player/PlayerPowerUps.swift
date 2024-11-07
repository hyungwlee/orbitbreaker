//
//  PowerUps.swift
//  Orbit Breaker
//
//  Created by Thomas Rife on 11/4/24.
//

import SpriteKit

enum PowerUps: CaseIterable {
    case shield
    case doubleDamage
}

class PowerUp : SKSpriteNode {
    let type : PowerUps
    private let duration : TimeInterval
    
    // intitialize all power up traits
        init(type: PowerUps, duration: TimeInterval = 5.0, color: UIColor, size: CGSize) {
        self.type = type
        self.duration = duration
        
        super.init(texture: nil, color: color, size: size)
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.categoryBitMask = 0x1 << 1
        self.physicsBody?.contactTestBitMask = 0x1 << 2
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.affectedByGravity = false
    }
    
    required init?(coder aDecoder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
    
    // apply to the player ship
    func apply(to player: Player) {
        switch type {
        case .shield:
            player.addShield()
            scheduleEndEffect(for: player, after: duration)
            // enemy bullets damage = 0 or some other way to implement 0 damage for enemies
        case .doubleDamage:
            // alter damage multiplier from player class to double the existing 10 damage
            player.damageMultiplier = 2
        }
    }
    
    
    
    private func scheduleEndEffect(for player: Player, after duration: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.remove(from: player)
        }
    }
    
    // removing these power ups after a certain amout of time (5s at the moment)
    private func remove(from player: Player) {
        switch type {
        case .shield:
            player.removeShield()
        case .doubleDamage:
            player.damageMultiplier = 1

        }
    }
}


