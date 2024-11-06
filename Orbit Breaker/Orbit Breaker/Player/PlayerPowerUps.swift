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

class PowerUp {
    let type : PowerUps
    private let duration : TimeInterval
    
    init(type: PowerUps, duration: TimeInterval = 5.0) {
        self.type = type
        self.duration = duration
    }
    
    func apply(to player: Player) {
        switch type {
        case .shield:
            Player.addShield()
            scheduleEndEffect(for: player, after: duration)
        case .doubleDamage:
            // TODO
            break
        case .moreBullets:
            
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
            Player.fireRate /= 0.5
        case .moreBullets:
            break
        }
    }

}


