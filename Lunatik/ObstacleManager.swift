import SpriteKit

class ObstacleManager {

    private weak var scene: SKScene?
    private var spawnTimer: TimeInterval = 0
    private var nextSpawnTime: TimeInterval = 1.2
    private var sceneWidth: CGFloat = 390
    private var sceneHeight: CGFloat = 844
    private var lunaY: CGFloat = 0

    init(scene: SKScene) {
        self.scene = scene
        self.sceneWidth = scene.size.width
        self.sceneHeight = scene.size.height
        self.lunaY = scene.size.height * GameConstants.lunaYPosition
    }

    // MARK: - Update

    func update(speed: CGFloat, deltaTime: TimeInterval) {
        guard let scene = scene else { return }

        spawnTimer += deltaTime
        if spawnTimer >= nextSpawnTime {
            spawnTimer = 0
            let speedRatio = GameConstants.initialSpeed / speed
            nextSpawnTime = TimeInterval.random(
                in: GameConstants.minSpawnInterval...GameConstants.maxSpawnInterval
            ) * Double(speedRatio)
            nextSpawnTime = max(0.55, nextSpawnTime)

            spawnRow(in: scene)

            // Occasionally spawn a collectible pattern
            if Double.random(in: 0...1) < GameConstants.collectiblePatternChance {
                spawnCollectiblePattern(in: scene)
            }
        }

        moveAndScale(speed: speed, deltaTime: deltaTime)
    }

    // MARK: - Perspective Math

    /// Returns 0.0 at spawn (top), 1.0 at Luna (bottom)
    private func depthProgress(y: CGFloat) -> CGFloat {
        let spawnY = sceneHeight + 60
        return max(0, min(1, (spawnY - y) / (spawnY - lunaY)))
    }

    private func scaleForDepth(_ dp: CGFloat) -> CGFloat {
        GameConstants.farScale + (GameConstants.nearScale - GameConstants.farScale) * dp
    }

    // MARK: - Spawning

    private func spawnRow(in scene: SKScene) {
        let allLanes = Lane.allCases
        var blockedLanes: [Lane] = []

        if Double.random(in: 0...1) < GameConstants.doubleObstacleChance {
            let skip = allLanes.randomElement()!
            blockedLanes = allLanes.filter { $0 != skip }
        } else {
            blockedLanes = [allLanes.randomElement()!]
        }

        for lane in blockedLanes {
            let type = ObstacleType.allCases.randomElement()!
            let obstacle = createObstacle(type: type)
            let spawnY = sceneHeight + 60
            let dp = depthProgress(y: spawnY)
            obstacle.position = CGPoint(
                x: lane.xAtDepth(sceneWidth: sceneWidth, depthProgress: dp),
                y: spawnY
            )
            obstacle.setScale(scaleForDepth(dp))
            obstacle.name = "obstacle"
            obstacle.userData = NSMutableDictionary()
            obstacle.userData?["lane"] = lane.rawValue
            obstacle.userData?["jumpable"] = type.isJumpable
            obstacle.zPosition = 10
            scene.addChild(obstacle)
        }

        // Single collectible in an open lane
        let openLanes = allLanes.filter { !blockedLanes.contains($0) }
        if Double.random(in: 0...1) < GameConstants.collectibleChance,
           let lane = openLanes.randomElement() {
            let type = CollectibleType.allCases.randomElement()!
            let collectible = createCollectible(type: type)
            let spawnY = sceneHeight + 60
            let dp = depthProgress(y: spawnY)
            collectible.position = CGPoint(
                x: lane.xAtDepth(sceneWidth: sceneWidth, depthProgress: dp),
                y: spawnY
            )
            collectible.setScale(scaleForDepth(dp))
            collectible.name = "collectible"
            collectible.userData = NSMutableDictionary()
            collectible.userData?["type"] = type
            collectible.userData?["lane"] = lane.rawValue
            collectible.zPosition = 10
            scene.addChild(collectible)
        }
    }

    /// Spawn a line of collectibles in a lane (3-5 items)
    private func spawnCollectiblePattern(in scene: SKScene) {
        let lane = Lane.allCases.randomElement()!
        let type = CollectibleType.allCases.randomElement()!
        let count = Int.random(in: 3...5)
        let spacing: CGFloat = 55

        for i in 0..<count {
            let collectible = createCollectible(type: type)
            let spawnY = sceneHeight + 120 + CGFloat(i) * spacing
            let dp = depthProgress(y: spawnY)
            collectible.position = CGPoint(
                x: lane.xAtDepth(sceneWidth: sceneWidth, depthProgress: dp),
                y: spawnY
            )
            collectible.setScale(scaleForDepth(dp))
            collectible.name = "collectible"
            collectible.userData = NSMutableDictionary()
            collectible.userData?["type"] = type
            collectible.userData?["lane"] = lane.rawValue
            collectible.zPosition = 10
            scene.addChild(collectible)
        }
    }

    // MARK: - Move & Scale (Perspective)

    private func moveAndScale(speed: CGFloat, deltaTime: TimeInterval) {
        guard let scene = scene else { return }
        let dy = -speed * CGFloat(deltaTime)

        for name in ["obstacle", "collectible"] {
            scene.enumerateChildNodes(withName: name) { [self] node, _ in
                node.position.y += dy

                if node.position.y < -80 {
                    node.removeFromParent()
                    return
                }

                // Update perspective scale and x position
                let dp = self.depthProgress(y: node.position.y)
                let newScale = self.scaleForDepth(dp)
                node.setScale(newScale)

                // Update x to follow converging lane
                if let laneRaw = node.userData?["lane"] as? Int,
                   let lane = Lane(rawValue: laneRaw) {
                    node.position.x = lane.xAtDepth(sceneWidth: self.sceneWidth, depthProgress: dp)
                }

                // Increase zPosition as objects get closer (draw on top)
                node.zPosition = 10 + dp * 5
            }
        }
    }

    // MARK: - Create Visuals

    private func createObstacle(type: ObstacleType) -> SKNode {
        let node = SKNode()

        switch type {
        case .fireHydrant:
            let body = SKShapeNode(rectOf: CGSize(width: 30, height: 44), cornerRadius: 4)
            body.fillColor = .red
            body.strokeColor = SKColor(red: 0.65, green: 0.0, blue: 0.0, alpha: 1.0)
            body.lineWidth = 2
            node.addChild(body)
            let cap = SKSpriteNode(color: SKColor(red: 0.75, green: 0.0, blue: 0.0, alpha: 1.0),
                                   size: CGSize(width: 38, height: 8))
            cap.position.y = 22
            node.addChild(cap)
            for xOff: CGFloat in [-18, 18] {
                let nub = SKSpriteNode(color: .red, size: CGSize(width: 9, height: 9))
                nub.position = CGPoint(x: xOff, y: 3)
                node.addChild(nub)
            }

        case .trashCan:
            let body = SKShapeNode(rectOf: CGSize(width: 42, height: 52), cornerRadius: 3)
            body.fillColor = SKColor(white: 0.35, alpha: 1.0)
            body.strokeColor = SKColor(white: 0.22, alpha: 1.0)
            body.lineWidth = 2
            node.addChild(body)
            let lid = SKSpriteNode(color: SKColor(white: 0.42, alpha: 1.0),
                                   size: CGSize(width: 48, height: 6))
            lid.position.y = 26
            node.addChild(lid)
            let handle = SKShapeNode(rectOf: CGSize(width: 16, height: 5), cornerRadius: 2)
            handle.fillColor = SKColor(white: 0.5, alpha: 1.0)
            handle.strokeColor = .clear
            handle.position.y = 31
            node.addChild(handle)

        case .cone:
            let conePath = CGMutablePath()
            conePath.move(to: CGPoint(x: -16, y: -16))
            conePath.addLine(to: CGPoint(x: 0, y: 28))
            conePath.addLine(to: CGPoint(x: 16, y: -16))
            conePath.closeSubpath()
            let cone = SKShapeNode(path: conePath)
            cone.fillColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
            cone.strokeColor = SKColor(red: 0.8, green: 0.3, blue: 0.0, alpha: 1.0)
            cone.lineWidth = 2
            node.addChild(cone)
            let stripe1 = SKSpriteNode(color: .white, size: CGSize(width: 22, height: 4))
            stripe1.position.y = 5
            node.addChild(stripe1)
            let stripe2 = SKSpriteNode(color: .white, size: CGSize(width: 14, height: 3))
            stripe2.position.y = 15
            node.addChild(stripe2)
        }

        // Shadow under obstacle
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 40, height: 12))
        shadow.fillColor = SKColor(white: 0.0, alpha: 0.2)
        shadow.strokeColor = .clear
        shadow.position.y = -25
        shadow.zPosition = -1
        node.addChild(shadow)

        // Physics
        let physics = SKPhysicsBody(rectangleOf: CGSize(width: 32, height: 38))
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
            path.move(to: CGPoint(x: 0, y: 13))
            path.addLine(to: CGPoint(x: -11, y: -8))
            path.addLine(to: CGPoint(x: 11, y: -8))
            path.closeSubpath()
            let slice = SKShapeNode(path: path)
            slice.fillColor = SKColor(red: 1.0, green: 0.82, blue: 0.3, alpha: 1.0)
            slice.strokeColor = SKColor(red: 0.85, green: 0.6, blue: 0.1, alpha: 1.0)
            slice.lineWidth = 1.5
            node.addChild(slice)
            for pos in [CGPoint(x: -3, y: 2), CGPoint(x: 4, y: -2), CGPoint(x: 0, y: 8)] {
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
            SKAction.moveBy(x: 0, y: 5, duration: 0.35),
            SKAction.moveBy(x: 0, y: -5, duration: 0.35)
        ])
        node.run(SKAction.repeatForever(float))

        // Gentle spin
        let spin = SKAction.sequence([
            SKAction.rotate(byAngle: 0.15, duration: 0.4),
            SKAction.rotate(byAngle: -0.15, duration: 0.4)
        ])
        node.run(SKAction.repeatForever(spin))

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
        scene?.enumerateChildNodes(withName: "obstacle") { node, _ in node.removeFromParent() }
        scene?.enumerateChildNodes(withName: "collectible") { node, _ in node.removeFromParent() }
    }
}
