//
//  EnemySpawner.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

import SpriteKit

class EnemySpawner {
    static func makeEnemy(ofType enemyType: EnemyType, layoutInfo: OBLayoutInfo) -> Enemy {
        return Enemy(type: enemyType, layoutInfo: layoutInfo)
    }
}
