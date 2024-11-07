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
    case moreBullets
}

class PowerUp : SKSpriteNode {
    let type : PowerUps
    private let duration : TimeInterval
    
    init(type: PowerUps, duration: TimeInterval = 5.0, color: UIColor, size: CGSize) {
        self.type = type
        self.duration = duration
        
        super.init(texture: nil, color: color, size: size)
        
    }
    
    required init?(coder aDecoder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
    
    func apply(to player: Player) {
        switch type {
        case .shield:
            player.addShield()
            scheduleEndEffect(for: player, after: duration)
            // enemy bullets damage = 0
        case .doubleDamage:
            player.damageMultiplier = 2
        case .moreBullets:
            break
        }
    }
    
    
    
    private func scheduleEndEffect(for player: Player, after duration: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.remove(from: player)
        }
    }
    
    private func remove(from Player: Player) {
        switch type {
        case .shield:
            Player.removeShield()
        case .doubleDamage:
            Player.damageMultiplier = 1
        case .moreBullets:
            break
        }
    }
}


