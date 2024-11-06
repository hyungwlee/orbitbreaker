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

class PowerUp {
    let type : PowerUps
    private let duration : TimeInterval
    
    // intitialize all power up traits
    init(type: PowerUps, duration: TimeInterval = 5.0) {
        self.type = type
        self.duration = duration
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
    private func remove(from Player: Player) {
        switch type {
        case .shield:
            Player.removeShield()
        case .doubleDamage:
            Player.damageMultiplier = 1

        }
    }
}


