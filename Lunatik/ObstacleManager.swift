import SpriteKit

class ObstacleManager {

    private weak var scene: SKScene?
    private var spawnTimer: TimeInterval = 0
    private var nextSpawnTime: TimeInterval = 1.2
    private var sceneWidth: CGFloat = 390
    private var sceneHeight: CGFloat = 844

    init(scene: SKScene) {
        self.scene = scene
        self.sceneWidth = scene.size.width
        self.sceneHeight = scene.size.height
    }

    // MARK: - Update

    func update(speed: CGFloat, deltaTime: TimeInterval, lunaLane: Lane, lunaIsJumping: Bool) {
        guard let scene = scene else { return }

        spawnTimer += deltaTime
        if spawnTimer >= nextSpawnTime {
            spawnTimer = 0
            // Faster spawning as speed increases
            let speedRatio = GameConstants.initialSpeed / speed
            nextSpawnTime = TimeInterval.random(
                in: GameConstants.minSpawnInterval...GameConstants.maxSpawnInterval
            ) * Double(speedRatio)
            nextSpawnTime = max(0.6, nextSpawnTime)

            spawnRow(in: scene, speed: speed)
        }

        moveAndCleanup(speed: speed, deltaTime: deltaTime)
    }

    // MARK: - Spawning

    private func spawnRow(in scene: SKScene, speed: CGFloat) {
        // Pick which lanes get obstacles (never block all 3)
        var blockedLanes: [Lane] = []
        let allLanes = Lane.allCases

        if Double.random(in: 0...1) < GameConstants.doubleObstacleChance {
            // Block 2 lanes
            let skip = allLanes.randomElement()!
            blockedLanes = allLanes.filter { $0 != skip }
        } else {
            // Block 1 lane
            blockedLanes = [allLanes.randomElement()!]
        }

        // Spawn obstacles in blocked lanes
        for lane in blockedLanes {
            let type = ObstacleType.allCases.randomElement()!
            let obstacle = createObstacle(type: type)
            obstacle.position = CGPoint(
                x: lane.xPosition(sceneWidth: sceneWidth),
                y: sceneHeight + 60
            )
            obstacle.name = "obstacle"
            obstacle.userData = NSMutableDictionary()
            obstacle.userData?["lane"] = lane.rawValue
            obstacle.userData?["jumpable"] = type.isJumpable
            obstacle.zPosition = 10
            scene.addChild(obstacle)
        }

        // Maybe spawn collectibles in open lanes
        let openLanes = allLanes.filter { !blockedLanes.contains($0) }
        if Double.random(in: 0...1) < GameConstants.collectibleChance, let lane = openLanes.randomElement() {
            let type = CollectibleType.allCases.randomElement()!
            let collectible = createCollectible(type: type)
            collectible.position = CGPoint(
                x: lane.xPosition(sceneWidth: sceneWidth),
                y: sceneHeight + 60
            )
            collectible.name = "collectible"
            collectible.userData = NSMutableDictionary()
            collectible.userData?["type"] = type
            collectible.userData?["lane"] = lane.rawValue
            collectible.zPosition = 10
            scene.addChild(collectible)
        }
    }

    private func moveAndCleanup(speed: CGFloat, deltaTime: TimeInterval) {
        guard let scene = scene else { return }
        let dy = -speed * CGFloat(deltaTime)

        scene.enumerateChildNodes(withName: "obstacle") { node, _ in
            node.position.y += dy
            if node.position.y < -80 {
                node.removeFromParent()
            }
        }

        scene.enumerateChildNodes(withName: "collectible") { node, _ in
            node.position.y += dy
            if node.position.y < -80 {
                node.removeFromParent()
            }
        }
    }

    // MARK: - Create Visuals

    private func createObstacle(type: ObstacleType) -> SKNode {
        let node = SKNode()

        switch type {
        case .fireHydrant:
            let body = SKShapeNode(rectOf: CGSize(width: 28, height: 42), cornerRadius: 4)
            body.fillColor = .red
            body.strokeColor = SKColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1.0)
            body.lineWidth = 1.5
            node.addChild(body)
            // Cap
            let cap = SKSpriteNode(color: SKColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0),
                                   size: CGSize(width: 36, height: 8))
            cap.position.y = 21
            node.addChild(cap)
            // Side nubs
            for xOff: CGFloat in [-17, 17] {
                let nub = SKSpriteNode(color: .red, size: CGSize(width: 8, height: 8))
                nub.position = CGPoint(x: xOff, y: 3)
                node.addChild(nub)
            }

        case .trashCan:
            let body = SKShapeNode(rectOf: CGSize(width: 40, height: 50), cornerRadius: 3)
            body.fillColor = .darkGray
            body.strokeColor = SKColor(white: 0.25, alpha: 1.0)
            body.lineWidth = 1.5
            node.addChild(body)
            let lid = SKSpriteNode(color: SKColor(white: 0.45, alpha: 1.0),
                                   size: CGSize(width: 46, height: 6))
            lid.position.y = 25
            node.addChild(lid)
            // Handle
            let handle = SKShapeNode(rectOf: CGSize(width: 14, height: 4), cornerRadius: 2)
            handle.fillColor = SKColor(white: 0.5, alpha: 1.0)
            handle.strokeColor = .clear
            handle.position.y = 30
            node.addChild(handle)

        case .cone:
            let conePath = CGMutablePath()
            conePath.move(to: CGPoint(x: -15, y: -15))
            conePath.addLine(to: CGPoint(x: 0, y: 25))
            conePath.addLine(to: CGPoint(x: 15, y: -15))
            conePath.closeSubpath()
            let cone = SKShapeNode(path: conePath)
            cone.fillColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
            cone.strokeColor = SKColor(red: 0.8, green: 0.3, blue: 0.0, alpha: 1.0)
            cone.lineWidth = 1.5
            node.addChild(cone)
            // White stripes
            let stripe1 = SKSpriteNode(color: .white, size: CGSize(width: 20, height: 4))
            stripe1.position.y = 5
            node.addChild(stripe1)
            let stripe2 = SKSpriteNode(color: .white, size: CGSize(width: 12, height: 3))
            stripe2.position.y = 14
            node.addChild(stripe2)
        }

        // Physics
        let physics = SKPhysicsBody(rectangleOf: CGSize(width: 35, height: 40))
        physics.isDynamic = false
        physics.categoryBitMask = PhysicsCategory.obstacle
        physics.contactTestBitMask = PhysicsCategory.luna
        node.physicsBody = physics

        return node
    }

    private func createCollectible(type: CollectibleType) -> SKNode {
        let node = SKNode()

        switch type {
        case .bone:
            let shaft = SKSpriteNode(color: .white, size: CGSize(width: 22, height: 7))
            node.addChild(shaft)
            for xOff: CGFloat in [-11, 11] {
                let knob = SKShapeNode(circleOfRadius: 6)
                knob.fillColor = SKColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1.0)
                knob.strokeColor = SKColor(white: 0.82, alpha: 1.0)
                knob.lineWidth = 1
                knob.position.x = xOff
                node.addChild(knob)
            }

        case .pizza:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 12))
            path.addLine(to: CGPoint(x: -10, y: -8))
            path.addLine(to: CGPoint(x: 10, y: -8))
            path.closeSubpath()
            let slice = SKShapeNode(path: path)
            slice.fillColor = SKColor(red: 1.0, green: 0.82, blue: 0.3, alpha: 1.0)
            slice.strokeColor = SKColor(red: 0.85, green: 0.6, blue: 0.1, alpha: 1.0)
            slice.lineWidth = 1.5
            node.addChild(slice)
            for pos in [CGPoint(x: -3, y: 2), CGPoint(x: 4, y: -2), CGPoint(x: 0, y: 7)] {
                let pep = SKShapeNode(circleOfRadius: 2.5)
                pep.fillColor = SKColor(red: 0.75, green: 0.15, blue: 0.1, alpha: 1.0)
                pep.strokeColor = .clear
                pep.position = pos
                node.addChild(pep)
            }

        case .tennisBall:
            let ball = SKShapeNode(circleOfRadius: 10)
            ball.fillColor = SKColor(red: 0.8, green: 1.0, blue: 0.0, alpha: 1.0)
            ball.strokeColor = SKColor(red: 0.6, green: 0.8, blue: 0.0, alpha: 1.0)
            ball.lineWidth = 1.5
            node.addChild(ball)
        }

        // Float animation
        let float = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 0.4),
            SKAction.moveBy(x: 0, y: -5, duration: 0.4)
        ])
        node.run(SKAction.repeatForever(float))

        // Glow / pulse
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.12, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])
        node.run(SKAction.repeatForever(pulse))

        // Physics
        let physics = SKPhysicsBody(circleOfRadius: 12)
        physics.isDynamic = false
        physics.categoryBitMask = PhysicsCategory.collectible
        physics.contactTestBitMask = PhysicsCategory.luna
        node.physicsBody = physics

        return node
    }

    func reset() {
        spawnTimer = 0
        nextSpawnTime = 1.2
        scene?.enumerateChildNodes(withName: "obstacle") { node, _ in
            node.removeFromParent()
        }
        scene?.enumerateChildNodes(withName: "collectible") { node, _ in
            node.removeFromParent()
        }
    }
}
