//
//  OBEnemySpawner.swift
//  Orbit Breaker
//
//  Created by Michelle Bai on 12/20/24.
//

import SpriteKit

class OBEnemySpawner {
    static func makeEnemy(ofType enemyType: OBEnemyType, layoutInfo: OBLayoutInfo) -> OBEnemy {
        return OBEnemy(type: enemyType, layoutInfo: layoutInfo)
    }
}
