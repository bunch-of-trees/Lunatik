import SpriteKit

class ObstacleManager {

    private weak var scene: SKScene?
    private var spawnTimer: TimeInterval = 0
    private var nextSpawnTime: TimeInterval = 1.5

    init(scene: SKScene) {
        self.scene = scene
    }

    // MARK: - Update

    func update(speed: CGFloat, deltaTime: TimeInterval) {
        guard let scene = scene else { return }

        spawnTimer += deltaTime
        if spawnTimer >= nextSpawnTime {
            spawnTimer = 0
            nextSpawnTime = TimeInterval.random(
                in: GameConstants.minObstacleInterval...GameConstants.maxObstacleInterval
            )
            // Adjust interval based on speed
            let speedFactor = GameConstants.initialSpeed / speed
            nextSpawnTime *= Double(speedFactor)
            nextSpawnTime = max(0.8, nextSpawnTime)

            spawnObstacle(in: scene, speed: speed)

            if Double.random(in: 0...1) < GameConstants.collectibleChance {
                spawnCollectible(in: scene, speed: speed)
            }
        }

        // Move and clean up existing obstacles/collectibles
        moveAndCleanup(speed: speed, deltaTime: deltaTime)
    }

    // MARK: - Spawning

    private func spawnObstacle(in scene: SKScene, speed: CGFloat) {
        let type = ObstacleType.allCases.randomElement()!
        let obstacle = createObstacle(type: type)
        obstacle.position = CGPoint(
            x: scene.size.width + 50,
            y: GameConstants.groundHeight + type.size.height / 2
        )
        obstacle.name = "obstacle"
        obstacle.zPosition = 5
        scene.addChild(obstacle)
    }

    private func spawnCollectible(in scene: SKScene, speed: CGFloat) {
        let type = CollectibleType.allCases.randomElement()!
        let collectible = createCollectible(type: type)

        let heights: [CGFloat] = [
            GameConstants.groundHeight + 20,   // ground level
            GameConstants.groundHeight + 80,   // low air
            GameConstants.groundHeight + 140,  // high air
        ]
        let y = heights.randomElement()!

        collectible.position = CGPoint(
            x: scene.size.width + 80 + CGFloat.random(in: 0...100),
            y: y
        )
        collectible.name = "collectible"
        collectible.zPosition = 5
        scene.addChild(collectible)
    }

    private func moveAndCleanup(speed: CGFloat, deltaTime: TimeInterval) {
        guard let scene = scene else { return }
        let dx = -speed * CGFloat(deltaTime)

        scene.enumerateChildNodes(withName: "obstacle") { node, _ in
            node.position.x += dx
            if node.position.x < -100 {
                node.removeFromParent()
            }
        }

        scene.enumerateChildNodes(withName: "collectible") { node, _ in
            node.position.x += dx
            if node.position.x < -100 {
                node.removeFromParent()
            }
        }
    }

    // MARK: - Create Visuals

    private func createObstacle(type: ObstacleType) -> SKNode {
        let node = SKNode()

        switch type {
        case .fireHydrant:
            // Base
            let base = SKSpriteNode(color: type.color, size: CGSize(width: type.size.width, height: type.size.height * 0.7))
            node.addChild(base)
            // Cap
            let cap = SKSpriteNode(color: type.color.withAlphaComponent(0.8), size: CGSize(width: type.size.width * 1.3, height: 8))
            cap.position.y = type.size.height * 0.35
            node.addChild(cap)
            // Nozzles
            let leftNozzle = SKSpriteNode(color: type.color, size: CGSize(width: 8, height: 6))
            leftNozzle.position = CGPoint(x: -type.size.width * 0.5 - 3, y: 2)
            node.addChild(leftNozzle)
            let rightNozzle = SKSpriteNode(color: type.color, size: CGSize(width: 8, height: 6))
            rightNozzle.position = CGPoint(x: type.size.width * 0.5 + 3, y: 2)
            node.addChild(rightNozzle)

        case .trashCan:
            let body = SKShapeNode(rectOf: type.size, cornerRadius: 3)
            body.fillColor = type.color
            body.strokeColor = SKColor(white: 0.3, alpha: 1.0)
            body.lineWidth = 1
            node.addChild(body)
            // Lid
            let lid = SKSpriteNode(
                color: SKColor(white: 0.45, alpha: 1.0),
                size: CGSize(width: type.size.width + 6, height: 5)
            )
            lid.position.y = type.size.height / 2
            node.addChild(lid)
            // Lines on can
            for i in 0..<3 {
                let line = SKSpriteNode(
                    color: SKColor(white: 0.35, alpha: 0.5),
                    size: CGSize(width: type.size.width - 6, height: 1)
                )
                line.position.y = -type.size.height * 0.3 + CGFloat(i) * 12
                node.addChild(line)
            }

        case .fence:
            // Posts
            let post = SKSpriteNode(color: type.color, size: type.size)
            node.addChild(post)
            let topPoint = SKShapeNode(path: {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: -type.size.width / 2, y: type.size.height / 2))
                p.addLine(to: CGPoint(x: 0, y: type.size.height / 2 + 8))
                p.addLine(to: CGPoint(x: type.size.width / 2, y: type.size.height / 2))
                p.closeSubpath()
                return p
            }())
            topPoint.fillColor = type.color
            topPoint.strokeColor = .clear
            node.addChild(topPoint)
        }

        // Physics
        let physics = SKPhysicsBody(rectangleOf: type.size)
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
            // Bone shape
            let shaft = SKSpriteNode(color: .white, size: CGSize(width: 18, height: 6))
            node.addChild(shaft)
            for xOff: CGFloat in [-9, 9] {
                let knob = SKShapeNode(circleOfRadius: 5)
                knob.fillColor = SKColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1.0)
                knob.strokeColor = SKColor(white: 0.85, alpha: 1.0)
                knob.lineWidth = 0.5
                knob.position = CGPoint(x: xOff, y: 0)
                node.addChild(knob)
            }

        case .pizza:
            // Pizza slice triangle
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 10))
            path.addLine(to: CGPoint(x: -8, y: -6))
            path.addLine(to: CGPoint(x: 8, y: -6))
            path.closeSubpath()
            let slice = SKShapeNode(path: path)
            slice.fillColor = SKColor(red: 1.0, green: 0.82, blue: 0.3, alpha: 1.0)
            slice.strokeColor = SKColor(red: 0.85, green: 0.6, blue: 0.1, alpha: 1.0)
            slice.lineWidth = 1
            node.addChild(slice)
            // Pepperoni
            for pos in [CGPoint(x: -2, y: 2), CGPoint(x: 3, y: -1), CGPoint(x: 0, y: 6)] {
                let pep = SKShapeNode(circleOfRadius: 2)
                pep.fillColor = SKColor(red: 0.75, green: 0.15, blue: 0.1, alpha: 1.0)
                pep.strokeColor = .clear
                pep.position = pos
                node.addChild(pep)
            }

        case .tennisBall:
            let ball = SKShapeNode(circleOfRadius: 8)
            ball.fillColor = SKColor(red: 0.8, green: 1.0, blue: 0.0, alpha: 1.0)
            ball.strokeColor = SKColor(red: 0.6, green: 0.8, blue: 0.0, alpha: 1.0)
            ball.lineWidth = 1
            node.addChild(ball)
            // Seam line
            let seam = SKShapeNode(ellipseOf: CGSize(width: 12, height: 6))
            seam.fillColor = .clear
            seam.strokeColor = SKColor(white: 1.0, alpha: 0.6)
            seam.lineWidth = 1
            node.addChild(seam)
        }

        // Floating animation
        let float = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 6, duration: 0.5),
            SKAction.moveBy(x: 0, y: -6, duration: 0.5)
        ])
        node.run(SKAction.repeatForever(float))

        // Gentle rotation
        let spin = SKAction.rotate(byAngle: 0.3, duration: 0.8)
        let spinBack = SKAction.rotate(byAngle: -0.3, duration: 0.8)
        node.run(SKAction.repeatForever(SKAction.sequence([spin, spinBack])))

        // Physics
        let physics = SKPhysicsBody(circleOfRadius: 10)
        physics.isDynamic = false
        physics.categoryBitMask = PhysicsCategory.collectible
        physics.contactTestBitMask = PhysicsCategory.luna
        node.physicsBody = physics

        // Store type
        node.userData = NSMutableDictionary()
        node.userData?["type"] = type

        return node
    }

    func reset() {
        spawnTimer = 0
        nextSpawnTime = 1.5
        scene?.enumerateChildNodes(withName: "obstacle") { node, _ in
            node.removeFromParent()
        }
        scene?.enumerateChildNodes(withName: "collectible") { node, _ in
            node.removeFromParent()
        }
    }
}
