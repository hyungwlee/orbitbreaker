import SpriteKit

enum DebuffType: CaseIterable {
    case freeze
    
}

class Debuffs: SKSpriteNode {
    let type: DebuffType
    
    init(type: DebuffType, color: UIColor, size: CGSize) {
        self.type = type
        
        super.init(texture: nil, color: color, size: size)
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.categoryBitMask = 0x1 << 1
        self.physicsBody?.contactTestBitMask = 0x1 << 2
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.affectedByGravity = false
        self.name = "debuffs"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func apply(to enemy: Enemy) {
        switch type {
        case .freeze:
            enemy.applyFreezeDebuff(to: [enemy])
        }
    }
}
