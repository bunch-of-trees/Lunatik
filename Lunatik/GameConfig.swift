import SpriteKit

// MARK: - Physics Categories
struct PhysicsCategory {
    static let none: UInt32       = 0
    static let luna: UInt32       = 0x1 << 0
    static let ground: UInt32     = 0x1 << 1
    static let obstacle: UInt32   = 0x1 << 2
    static let collectible: UInt32 = 0x1 << 3
}

// MARK: - Collectible Types
enum CollectibleType: CaseIterable {
    case bone
    case pizza
    case tennisBall

    var points: Int {
        switch self {
        case .bone: return 1
        case .pizza: return 5
        case .tennisBall: return 2
        }
    }

    var color: SKColor {
        switch self {
        case .bone: return .white
        case .pizza: return SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        case .tennisBall: return SKColor(red: 0.8, green: 1.0, blue: 0.0, alpha: 1.0)
        }
    }
}

// MARK: - Obstacle Types
enum ObstacleType: CaseIterable {
    case fireHydrant
    case trashCan
    case fence

    var size: CGSize {
        switch self {
        case .fireHydrant: return CGSize(width: 25, height: 40)
        case .trashCan: return CGSize(width: 30, height: 45)
        case .fence: return CGSize(width: 15, height: 55)
        }
    }

    var color: SKColor {
        switch self {
        case .fireHydrant: return .red
        case .trashCan: return .darkGray
        case .fence: return SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        }
    }
}

// MARK: - Game Constants
struct GameConstants {
    static let gravity: CGFloat = -30.0
    static let jumpImpulse: CGFloat = 520.0
    static let initialSpeed: CGFloat = 280.0
    static let maxSpeed: CGFloat = 600.0
    static let speedIncrement: CGFloat = 0.15 // per second
    static let groundHeight: CGFloat = 80.0
    static let lunaStartX: CGFloat = 100.0

    static let minObstacleInterval: TimeInterval = 1.2
    static let maxObstacleInterval: TimeInterval = 2.8
    static let collectibleChance: Double = 0.4

    static let lunaBodyWidth: CGFloat = 50.0
    static let lunaBodyHeight: CGFloat = 35.0
}
