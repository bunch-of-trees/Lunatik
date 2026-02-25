import SpriteKit

// MARK: - Physics Categories
struct PhysicsCategory {
    static let none: UInt32        = 0
    static let luna: UInt32        = 0x1 << 0
    static let obstacle: UInt32    = 0x1 << 1
    static let collectible: UInt32 = 0x1 << 2
}

// MARK: - Lanes
enum Lane: Int, CaseIterable {
    case left = 0
    case center = 1
    case right = 2

    /// Full-width lane position (at Luna's Y, near camera)
    func xPosition(sceneWidth: CGFloat) -> CGFloat {
        let laneWidth = sceneWidth / 3.0
        return laneWidth * CGFloat(rawValue) + laneWidth / 2.0
    }

    /// Perspective-adjusted lane position at a given depth
    func xAtDepth(sceneWidth: CGFloat, depthProgress: CGFloat) -> CGFloat {
        let centerX = sceneWidth / 2.0
        let fullOffset = xPosition(sceneWidth: sceneWidth) - centerX
        let perspectiveScale = 0.25 + 0.75 * depthProgress
        return centerX + fullOffset * perspectiveScale
    }

    func moveLeft() -> Lane? { Lane(rawValue: rawValue - 1) }
    func moveRight() -> Lane? { Lane(rawValue: rawValue + 1) }
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
    static let lunaSpriteHeight: CGFloat = 110.0
    static let lunaYPosition: CGFloat = 0.14

    // Speed
    static let initialSpeed: CGFloat = 340.0
    static let maxSpeed: CGFloat = 750.0
    static let speedIncrement: CGFloat = 0.25

    // Spawning
    static let minSpawnInterval: TimeInterval = 0.85
    static let maxSpawnInterval: TimeInterval = 1.7
    static let collectibleChance: Double = 0.5
    static let doubleObstacleChance: Double = 0.28
    static let collectiblePatternChance: Double = 0.3

    // Jumping
    static let jumpHeight: CGFloat = 120.0
    static let jumpDuration: TimeInterval = 0.5

    // Sliding
    static let slideDuration: TimeInterval = 0.55

    // Lane switching
    static let laneSwitchDuration: TimeInterval = 0.09

    // Perspective
    static let farScale: CGFloat = 0.3
    static let nearScale: CGFloat = 1.0
}
