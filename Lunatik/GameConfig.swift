import SpriteKit

// MARK: - Physics Categories
struct PhysicsCategory {
    static let none: UInt32       = 0
    static let luna: UInt32       = 0x1 << 0
    static let obstacle: UInt32   = 0x1 << 1
    static let collectible: UInt32 = 0x1 << 2
}

// MARK: - Lanes
enum Lane: Int, CaseIterable {
    case left = 0
    case center = 1
    case right = 2

    func xPosition(sceneWidth: CGFloat) -> CGFloat {
        let laneWidth = sceneWidth / 3.0
        return laneWidth * CGFloat(rawValue) + laneWidth / 2.0
    }

    func moveLeft() -> Lane? {
        Lane(rawValue: rawValue - 1)
    }

    func moveRight() -> Lane? {
        Lane(rawValue: rawValue + 1)
    }
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
}

// MARK: - Obstacle Types
enum ObstacleType: CaseIterable {
    case fireHydrant
    case trashCan
    case cone

    /// Height relative to the lane (for jump-over detection)
    var isJumpable: Bool {
        switch self {
        case .fireHydrant: return true
        case .trashCan: return false
        case .cone: return true
        }
    }
}

// MARK: - Game Constants
struct GameConstants {
    // Luna
    static let lunaSpriteHeight: CGFloat = 100.0
    static let lunaYPosition: CGFloat = 0.15 // fraction of screen height

    // Speed
    static let initialSpeed: CGFloat = 320.0
    static let maxSpeed: CGFloat = 700.0
    static let speedIncrement: CGFloat = 0.3

    // Spawning
    static let minSpawnInterval: TimeInterval = 0.8
    static let maxSpawnInterval: TimeInterval = 1.8
    static let collectibleChance: Double = 0.45
    static let doubleObstacleChance: Double = 0.25

    // Jumping
    static let jumpHeight: CGFloat = 130.0
    static let jumpDuration: TimeInterval = 0.45

    // Sliding
    static let slideDuration: TimeInterval = 0.6

    // Lane switching
    static let laneSwitchDuration: TimeInterval = 0.12
}
