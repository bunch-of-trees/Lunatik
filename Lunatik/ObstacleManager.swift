import SpriteKit

class ObstacleManager {

    private weak var scene: SKScene?
    private var spawnTimer: TimeInterval = 0
    private var nextSpawnTime: TimeInterval = 1.2
    private var sceneWidth: CGFloat = 390
    private var sceneHeight: CGFloat = 844
    private var lunaY: CGFloat = 0

    // Cached textures for performance (avoid creating SKShapeNodes every spawn)
    // Static so they persist across game restarts — built once, reused forever
    private static var obstacleTextures: [ObstacleType: SKTexture] = [:]
    private static var collectibleTextures: [CollectibleType: SKTexture] = [:]
    private static var powerUpTextures: [PowerUpType: SKTexture] = [:]
    private static var texturesCached = false

    // Object pools (recycle instead of create/destroy)
    private var obstaclePool: [SKNode] = []
    private var collectiblePool: [SKNode] = []
    private var powerUpPool: [SKNode] = []

    // Difficulty progression
    private var distanceTraveled: CGFloat = 0
    private var restBlockTimer: TimeInterval = 0
    private var nextRestDistance: CGFloat = 500
    private var gauntletRowsRemaining: Int = 0

    init(scene: SKScene) {
        self.scene = scene
        self.sceneWidth = scene.size.width
        self.sceneHeight = scene.size.height
        self.lunaY = scene.size.height * GameConstants.lunaYPosition
        cacheTextures(in: scene)
        prewarmPools()
    }

    /// Pre-render shape nodes to textures once for fast spawning
    private func cacheTextures(in scene: SKScene) {
        guard !Self.texturesCached else { return }
        guard let view = scene.view else { return }
        for type in ObstacleType.allCases {
            let node = buildObstacleShape(type: type)
            Self.obstacleTextures[type] = view.texture(from: node)
        }
        for type in CollectibleType.allCases {
            let node = buildCollectibleShape(type: type)
            Self.collectibleTextures[type] = view.texture(from: node)
        }
        for type in PowerUpType.allCases {
            let node = buildPowerUpShape(type: type)
            Self.powerUpTextures[type] = view.texture(from: node)
        }
        Self.texturesCached = true
    }

    // MARK: - Update

    func update(speed: CGFloat, deltaTime: TimeInterval) {
        guard let scene = scene else { return }

        // Track distance to match GameScene's scoring formula
        distanceTraveled += speed * CGFloat(deltaTime) * 0.01

        // Rest block: suppress obstacles and spawn bonus collectibles instead
        if restBlockTimer > 0 {
            restBlockTimer -= deltaTime
            // During rest, only move existing nodes (no new obstacles)
            moveAndScale(speed: speed, deltaTime: deltaTime)
            return
        }

        // Check if we've reached the next rest distance threshold
        if distanceTraveled >= nextRestDistance {
            restBlockTimer = 2.0
            nextRestDistance += 500
            spawnRestCollectibles(in: scene)
            moveAndScale(speed: speed, deltaTime: deltaTime)
            return
        }

        spawnTimer += deltaTime
        if spawnTimer >= nextSpawnTime {
            spawnTimer = 0
            let speedRatio = GameConstants.initialSpeed / speed
            nextSpawnTime = TimeInterval.random(
                in: GameConstants.minSpawnInterval...GameConstants.maxSpawnInterval
            ) * Double(speedRatio)
            nextSpawnTime = max(0.55, nextSpawnTime)

            spawnRow(in: scene)

            // Hard phase gauntlet: queue rapid follow-up rows
            if gauntletRowsRemaining > 0 {
                gauntletRowsRemaining -= 1
                nextSpawnTime = 0.3 // Tight spacing for gauntlet rows
            } else if distanceTraveled >= 800 && Double.random(in: 0...1) < 0.12 {
                // ~12% chance to trigger a 3-row gauntlet in hard phase
                gauntletRowsRemaining = 2 // 2 more after this one = 3 total
                nextSpawnTime = 0.3
            }

            // Occasionally spawn a collectible pattern
            if Double.random(in: 0...1) < GameConstants.collectiblePatternChance {
                spawnCollectiblePattern(in: scene)
            }
        }

        moveAndScale(speed: speed, deltaTime: deltaTime)
    }

    // MARK: - Object Pooling

    private func prewarmPools() {
        for _ in 0..<6 {
            let type = [ObstacleType.fireHydrant, .trashCan, .cone].randomElement()!
            obstaclePool.append(createObstacle(type: type))
        }
        for _ in 0..<4 {
            let type = CollectibleType.allCases.randomElement()!
            collectiblePool.append(createCollectible(type: type))
        }
        for _ in 0..<2 {
            let type = PowerUpType.allCases.randomElement()!
            powerUpPool.append(createPowerUp(type: type))
        }
    }

    private func recycleNode(_ node: SKNode) {
        node.removeFromParent()
        node.removeAllActions()
        node.removeAllChildren()
        node.physicsBody = nil
        node.alpha = 1.0
        node.setScale(1.0)
        node.zRotation = 0

        if let name = node.name {
            switch name {
            case "obstacle": obstaclePool.append(node)
            case "collectible": collectiblePool.append(node)
            case "powerUp": powerUpPool.append(node)
            default: break
            }
        }
        node.name = nil
        node.userData = nil
    }

    private func dequeueObstacle(type: ObstacleType) -> SKNode {
        let node: SKNode
        if let pooled = obstaclePool.popLast() {
            node = pooled
        } else {
            node = SKNode()
        }
        // Rebuild visuals
        if let texture = Self.obstacleTextures[type] {
            let sprite = SKSpriteNode(texture: texture)
            node.addChild(sprite)
        }
        let shadow = SKSpriteNode(color: SKColor(white: 0.0, alpha: 0.18), size: CGSize(width: 60, height: 14))
        shadow.position.y = -40
        shadow.zPosition = -1
        node.addChild(shadow)

        let physics = SKPhysicsBody(rectangleOf: CGSize(width: 48, height: 60))
        physics.isDynamic = false
        physics.categoryBitMask = PhysicsCategory.obstacle
        physics.contactTestBitMask = PhysicsCategory.luna
        node.physicsBody = physics
        return node
    }

    private func dequeueCollectible(type: CollectibleType) -> SKNode {
        let node: SKNode
        if let pooled = collectiblePool.popLast() {
            node = pooled
        } else {
            node = SKNode()
        }
        if let texture = Self.collectibleTextures[type] {
            let sprite = SKSpriteNode(texture: texture)
            node.addChild(sprite)
        }
        // Float animation
        let float = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 0.35),
            SKAction.moveBy(x: 0, y: -5, duration: 0.35)
        ])
        node.run(SKAction.repeatForever(float))

        let physics = SKPhysicsBody(circleOfRadius: 18)
        physics.isDynamic = false
        physics.categoryBitMask = PhysicsCategory.collectible
        physics.contactTestBitMask = PhysicsCategory.luna
        node.physicsBody = physics
        return node
    }

    private func dequeuePowerUp(type: PowerUpType) -> SKNode {
        let node: SKNode
        if let pooled = powerUpPool.popLast() {
            node = pooled
        } else {
            node = SKNode()
        }
        if let texture = Self.powerUpTextures[type] {
            let sprite = SKSpriteNode(texture: texture)
            node.addChild(sprite)
        }
        // Glow effect
        let glow = SKShapeNode(circleOfRadius: 22)
        glow.fillColor = SKColor(white: 1.0, alpha: 0.15)
        glow.strokeColor = .clear
        glow.zPosition = -1
        node.addChild(glow)
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.4),
            SKAction.scale(to: 0.9, duration: 0.4)
        ])
        glow.run(SKAction.repeatForever(pulse))

        let float = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 6, duration: 0.3),
            SKAction.moveBy(x: 0, y: -6, duration: 0.3)
        ])
        node.run(SKAction.repeatForever(float))

        let physics = SKPhysicsBody(circleOfRadius: 20)
        physics.isDynamic = false
        physics.categoryBitMask = PhysicsCategory.collectible
        physics.contactTestBitMask = PhysicsCategory.luna
        node.physicsBody = physics
        return node
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

        // Difficulty-phase overrides for double obstacle chance and collectible chance
        let effectiveDoubleChance: Double
        let effectiveCollectibleChance: Double

        if distanceTraveled < 300 {
            // Warm-up: no double obstacles, generous collectibles
            effectiveDoubleChance = 0
            effectiveCollectibleChance = 0.7
        } else if distanceTraveled < 800 {
            // Normal: use default constants
            effectiveDoubleChance = GameConstants.doubleObstacleChance
            effectiveCollectibleChance = GameConstants.collectibleChance
        } else {
            // Hard: use default constants (gauntlets handled in update)
            effectiveDoubleChance = GameConstants.doubleObstacleChance
            effectiveCollectibleChance = GameConstants.collectibleChance
        }

        if Double.random(in: 0...1) < effectiveDoubleChance {
            let skip = allLanes.randomElement()!
            blockedLanes = allLanes.filter { $0 != skip }
        } else {
            blockedLanes = [allLanes.randomElement()!]
        }

        for lane in blockedLanes {
            // Overhead barriers only appear after warm-up, and are rarer
            let type: ObstacleType
            if distanceTraveled >= 300 && Double.random(in: 0...1) < 0.18 {
                type = .overheadBarrier
            } else {
                type = [ObstacleType.fireHydrant, .trashCan, .cone].randomElement()!
            }
            let obstacle = dequeueObstacle(type: type)
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
            obstacle.userData?["requiresSlide"] = type.requiresSlide
            obstacle.zPosition = 10
            scene.addChild(obstacle)
        }

        // Power-up (rare)
        let openLanesForPowerUp = allLanes.filter { !blockedLanes.contains($0) }
        if distanceTraveled >= 200 && Double.random(in: 0...1) < GameConstants.powerUpSpawnChance,
           let lane = openLanesForPowerUp.randomElement() {
            let type = PowerUpType.allCases.randomElement()!
            let powerUp = dequeuePowerUp(type: type)
            let spawnY = sceneHeight + 60
            let dp = depthProgress(y: spawnY)
            powerUp.position = CGPoint(
                x: lane.xAtDepth(sceneWidth: sceneWidth, depthProgress: dp),
                y: spawnY
            )
            powerUp.setScale(scaleForDepth(dp))
            powerUp.name = "powerUp"
            powerUp.userData = NSMutableDictionary()
            powerUp.userData?["powerUpType"] = type
            powerUp.userData?["lane"] = lane.rawValue
            powerUp.zPosition = 10
            scene.addChild(powerUp)
        }

        // Single collectible in an open lane
        let openLanes = allLanes.filter { !blockedLanes.contains($0) }
        if Double.random(in: 0...1) < effectiveCollectibleChance,
           let lane = openLanes.randomElement() {
            let type = CollectibleType.allCases.randomElement()!
            let collectible = dequeueCollectible(type: type)
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
            let collectible = dequeueCollectible(type: type)
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

    /// Spawn bonus collectibles across multiple lanes during a rest block
    private func spawnRestCollectibles(in scene: SKScene) {
        let allLanes = Lane.allCases
        let type = CollectibleType.allCases.randomElement()!
        let count = Int.random(in: 4...6)
        let spacing: CGFloat = 55

        for i in 0..<count {
            // Alternate or randomize lanes for a spread-out pattern
            let lane = allLanes[i % allLanes.count]
            let collectible = dequeueCollectible(type: type)
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
        var nodesToRecycle: [SKNode] = []

        for name in ["obstacle", "collectible", "powerUp"] {
            scene.enumerateChildNodes(withName: name) { [self] node, _ in
                node.position.y += dy

                if node.position.y < -80 {
                    nodesToRecycle.append(node)
                    return
                }

                // Update perspective scale and x position
                let dp = self.depthProgress(y: node.position.y)
                let newScale = self.scaleForDepth(dp)
                node.setScale(newScale)
                node.alpha = 0.7 + 0.3 * dp

                // Update x to follow converging lane
                if let laneRaw = node.userData?["lane"] as? Int,
                   let lane = Lane(rawValue: laneRaw) {
                    node.position.x = lane.xAtDepth(sceneWidth: self.sceneWidth, depthProgress: dp)
                }

                // Increase zPosition as objects get closer (draw on top)
                node.zPosition = 10 + dp * 5
            }
        }

        // Recycle off-screen nodes back to pools
        for node in nodesToRecycle {
            recycleNode(node)
        }
    }

    // MARK: - Create Game Objects (texture-cached for performance)

    private func createObstacle(type: ObstacleType) -> SKNode {
        let node = SKNode()

        if let texture = Self.obstacleTextures[type] {
            let sprite = SKSpriteNode(texture: texture)
            node.addChild(sprite)
        }

        // Shadow
        let shadow = SKSpriteNode(color: SKColor(white: 0.0, alpha: 0.18), size: CGSize(width: 60, height: 14))
        shadow.position.y = -40
        shadow.zPosition = -1
        node.addChild(shadow)

        let physics = SKPhysicsBody(rectangleOf: CGSize(width: 48, height: 60))
        physics.isDynamic = false
        physics.categoryBitMask = PhysicsCategory.obstacle
        physics.contactTestBitMask = PhysicsCategory.luna
        node.physicsBody = physics

        return node
    }

    private func createCollectible(type: CollectibleType) -> SKNode {
        let node = SKNode()

        if let texture = Self.collectibleTextures[type] {
            let sprite = SKSpriteNode(texture: texture)
            node.addChild(sprite)
        }

        // Float animation
        let float = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 0.35),
            SKAction.moveBy(x: 0, y: -5, duration: 0.35)
        ])
        node.run(SKAction.repeatForever(float))

        let physics = SKPhysicsBody(circleOfRadius: 18)
        physics.isDynamic = false
        physics.categoryBitMask = PhysicsCategory.collectible
        physics.contactTestBitMask = PhysicsCategory.luna
        node.physicsBody = physics

        return node
    }

    private func createPowerUp(type: PowerUpType) -> SKNode {
        let node = SKNode()

        if let texture = Self.powerUpTextures[type] {
            let sprite = SKSpriteNode(texture: texture)
            node.addChild(sprite)
        }

        // Glow effect
        let glow = SKShapeNode(circleOfRadius: 22)
        glow.fillColor = SKColor(white: 1.0, alpha: 0.15)
        glow.strokeColor = .clear
        glow.zPosition = -1
        node.addChild(glow)
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.4),
            SKAction.scale(to: 0.9, duration: 0.4)
        ])
        glow.run(SKAction.repeatForever(pulse))

        // Float + spin
        let float = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 6, duration: 0.3),
            SKAction.moveBy(x: 0, y: -6, duration: 0.3)
        ])
        node.run(SKAction.repeatForever(float))

        let physics = SKPhysicsBody(circleOfRadius: 20)
        physics.isDynamic = false
        physics.categoryBitMask = PhysicsCategory.collectible
        physics.contactTestBitMask = PhysicsCategory.luna
        node.physicsBody = physics

        return node
    }

    // MARK: - Shape Builders (used once at init to create cached textures)

    private func buildObstacleShape(type: ObstacleType) -> SKNode {
        let node = SKNode()
        switch type {
        case .fireHydrant:
            // Base plate
            let base = SKShapeNode(rectOf: CGSize(width: 52, height: 10), cornerRadius: 3)
            base.fillColor = SKColor(red: 0.55, green: 0.0, blue: 0.0, alpha: 1.0)
            base.strokeColor = SKColor(red: 0.4, green: 0.0, blue: 0.0, alpha: 1.0)
            base.lineWidth = 1.5
            base.position.y = -30
            node.addChild(base)

            // Main body
            let body = SKShapeNode(rectOf: CGSize(width: 40, height: 58), cornerRadius: 6)
            body.fillColor = SKColor(red: 0.85, green: 0.08, blue: 0.08, alpha: 1.0)
            body.strokeColor = SKColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
            body.lineWidth = 2
            node.addChild(body)

            // Body highlight (left side shine)
            let shine = SKSpriteNode(
                color: SKColor(red: 1.0, green: 0.35, blue: 0.3, alpha: 0.5),
                size: CGSize(width: 8, height: 40))
            shine.position.x = -10
            node.addChild(shine)

            // Top collar
            let collar = SKShapeNode(rectOf: CGSize(width: 48, height: 10), cornerRadius: 3)
            collar.fillColor = SKColor(red: 0.75, green: 0.05, blue: 0.05, alpha: 1.0)
            collar.strokeColor = SKColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
            collar.lineWidth = 1.5
            collar.position.y = 28
            node.addChild(collar)

            // Dome top
            let dome = SKShapeNode(ellipseOf: CGSize(width: 30, height: 20))
            dome.fillColor = SKColor(red: 0.8, green: 0.05, blue: 0.05, alpha: 1.0)
            dome.strokeColor = SKColor(red: 0.55, green: 0.0, blue: 0.0, alpha: 1.0)
            dome.lineWidth = 1.5
            dome.position.y = 38
            node.addChild(dome)

            // Side nozzles
            for xOff: CGFloat in [-26, 26] {
                let nozzle = SKShapeNode(rectOf: CGSize(width: 14, height: 12), cornerRadius: 3)
                nozzle.fillColor = SKColor(red: 0.78, green: 0.05, blue: 0.05, alpha: 1.0)
                nozzle.strokeColor = SKColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
                nozzle.lineWidth = 1.5
                nozzle.position = CGPoint(x: xOff, y: 5)
                node.addChild(nozzle)
            }

            // Bolts on body
            for pos in [CGPoint(x: 0, y: 18), CGPoint(x: 0, y: -14)] {
                let bolt = SKShapeNode(circleOfRadius: 3)
                bolt.fillColor = SKColor(white: 0.7, alpha: 1.0)
                bolt.strokeColor = SKColor(white: 0.4, alpha: 1.0)
                bolt.lineWidth = 1
                bolt.position = pos
                node.addChild(bolt)
            }

        case .trashCan:
            // Tapered body (wider at top)
            let bodyPath = CGMutablePath()
            bodyPath.move(to: CGPoint(x: -25, y: -38))
            bodyPath.addLine(to: CGPoint(x: -30, y: 32))
            bodyPath.addLine(to: CGPoint(x: 30, y: 32))
            bodyPath.addLine(to: CGPoint(x: 25, y: -38))
            bodyPath.closeSubpath()
            let body = SKShapeNode(path: bodyPath)
            body.fillColor = SKColor(white: 0.38, alpha: 1.0)
            body.strokeColor = SKColor(white: 0.2, alpha: 1.0)
            body.lineWidth = 2
            node.addChild(body)

            // Horizontal ridges
            for yOff: CGFloat in [-18, -2, 14] {
                let tAtY = (yOff + 38) / 70  // 0 at bottom, 1 at top
                let halfW: CGFloat = 25 + tAtY * 5
                let ridge = SKSpriteNode(
                    color: SKColor(white: 0.45, alpha: 1.0),
                    size: CGSize(width: halfW * 2 - 4, height: 3))
                ridge.position.y = yOff
                node.addChild(ridge)
            }

            // Lid
            let lid = SKShapeNode(rectOf: CGSize(width: 66, height: 8), cornerRadius: 3)
            lid.fillColor = SKColor(white: 0.48, alpha: 1.0)
            lid.strokeColor = SKColor(white: 0.28, alpha: 1.0)
            lid.lineWidth = 1.5
            lid.position.y = 36
            node.addChild(lid)

            // Lid handle
            let handlePath = CGMutablePath()
            handlePath.addArc(center: CGPoint(x: 0, y: 40), radius: 8,
                              startAngle: 0, endAngle: .pi, clockwise: false)
            let handle = SKShapeNode(path: handlePath)
            handle.strokeColor = SKColor(white: 0.55, alpha: 1.0)
            handle.lineWidth = 3
            handle.fillColor = .clear
            node.addChild(handle)

        case .cone:
            // Square base
            let base = SKShapeNode(rectOf: CGSize(width: 50, height: 8), cornerRadius: 2)
            base.fillColor = SKColor(red: 1.0, green: 0.55, blue: 0.05, alpha: 1.0)
            base.strokeColor = SKColor(red: 0.7, green: 0.3, blue: 0.0, alpha: 1.0)
            base.lineWidth = 1.5
            base.position.y = -24
            node.addChild(base)

            // Cone body (slightly curved sides)
            let conePath = CGMutablePath()
            conePath.move(to: CGPoint(x: -22, y: -20))
            conePath.addQuadCurve(to: CGPoint(x: 0, y: 42),
                                  control: CGPoint(x: -10, y: 12))
            conePath.addQuadCurve(to: CGPoint(x: 22, y: -20),
                                  control: CGPoint(x: 10, y: 12))
            conePath.closeSubpath()
            let cone = SKShapeNode(path: conePath)
            cone.fillColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
            cone.strokeColor = SKColor(red: 0.75, green: 0.3, blue: 0.0, alpha: 1.0)
            cone.lineWidth = 2
            node.addChild(cone)

            // Reflective white stripes
            let stripe1 = SKSpriteNode(color: .white, size: CGSize(width: 30, height: 6))
            stripe1.position.y = -4
            node.addChild(stripe1)
            let stripe2 = SKSpriteNode(color: .white, size: CGSize(width: 18, height: 5))
            stripe2.position.y = 16
            node.addChild(stripe2)

            // Pointed tip
            let tip = SKShapeNode(circleOfRadius: 3)
            tip.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.15, alpha: 1.0)
            tip.strokeColor = .clear
            tip.position.y = 40
            node.addChild(tip)

        case .overheadBarrier:
            // Two vertical poles
            for xOff: CGFloat in [-28, 28] {
                let pole = SKSpriteNode(
                    color: SKColor(white: 0.55, alpha: 1.0),
                    size: CGSize(width: 6, height: 80))
                pole.position = CGPoint(x: xOff, y: 0)
                node.addChild(pole)

                // Pole base
                let base = SKShapeNode(rectOf: CGSize(width: 14, height: 6), cornerRadius: 2)
                base.fillColor = SKColor(white: 0.45, alpha: 1.0)
                base.strokeColor = SKColor(white: 0.3, alpha: 1.0)
                base.lineWidth = 1
                base.position = CGPoint(x: xOff, y: -38)
                node.addChild(base)
            }

            // Horizontal beam (the part you must slide under)
            let beam = SKShapeNode(rectOf: CGSize(width: 62, height: 14), cornerRadius: 3)
            beam.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
            beam.strokeColor = SKColor(red: 0.7, green: 0.55, blue: 0.0, alpha: 1.0)
            beam.lineWidth = 2
            beam.position.y = 22
            node.addChild(beam)

            // Warning stripes on beam
            for i in 0..<3 {
                let stripe = SKSpriteNode(
                    color: SKColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 0.8),
                    size: CGSize(width: 8, height: 10))
                stripe.position = CGPoint(x: CGFloat(i - 1) * 18, y: 22)
                node.addChild(stripe)
            }

            // "SLOW" text indicator
            let slowLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            slowLabel.text = "!"
            slowLabel.fontSize = 16
            slowLabel.fontColor = SKColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 0.9)
            slowLabel.verticalAlignmentMode = .center
            slowLabel.position.y = 22
            node.addChild(slowLabel)
        }
        return node
    }

    private func buildCollectibleShape(type: CollectibleType) -> SKNode {
        let node = SKNode()
        switch type {
        case .bone:
            // Shaft
            let shaft = SKSpriteNode(
                color: SKColor(red: 0.96, green: 0.94, blue: 0.88, alpha: 1.0),
                size: CGSize(width: 34, height: 11))
            node.addChild(shaft)

            // Shaft shadow line
            let shaftShadow = SKSpriteNode(
                color: SKColor(red: 0.85, green: 0.82, blue: 0.75, alpha: 1.0),
                size: CGSize(width: 34, height: 3))
            shaftShadow.position.y = -4
            node.addChild(shaftShadow)

            // Double-knob ends (classic dog bone shape)
            for xOff: CGFloat in [-18, 18] {
                for yOff: CGFloat in [-5, 5] {
                    let knob = SKShapeNode(circleOfRadius: 8)
                    knob.fillColor = SKColor(red: 0.97, green: 0.95, blue: 0.9, alpha: 1.0)
                    knob.strokeColor = SKColor(red: 0.82, green: 0.78, blue: 0.7, alpha: 1.0)
                    knob.lineWidth = 1.5
                    knob.position = CGPoint(x: xOff, y: yOff)
                    node.addChild(knob)
                }
            }

        case .pizza:
            // Crust edge (arc at the wide end)
            let crustPath = CGMutablePath()
            crustPath.move(to: CGPoint(x: -16, y: -12))
            crustPath.addQuadCurve(to: CGPoint(x: 16, y: -12),
                                   control: CGPoint(x: 0, y: -18))
            crustPath.addLine(to: CGPoint(x: 14, y: -8))
            crustPath.addQuadCurve(to: CGPoint(x: -14, y: -8),
                                   control: CGPoint(x: 0, y: -13))
            crustPath.closeSubpath()
            let crust = SKShapeNode(path: crustPath)
            crust.fillColor = SKColor(red: 0.82, green: 0.62, blue: 0.22, alpha: 1.0)
            crust.strokeColor = SKColor(red: 0.65, green: 0.45, blue: 0.12, alpha: 1.0)
            crust.lineWidth = 1.5
            node.addChild(crust)

            // Cheese triangle
            let cheesePath = CGMutablePath()
            cheesePath.move(to: CGPoint(x: 0, y: 20))
            cheesePath.addLine(to: CGPoint(x: -14, y: -8))
            cheesePath.addLine(to: CGPoint(x: 14, y: -8))
            cheesePath.closeSubpath()
            let cheese = SKShapeNode(path: cheesePath)
            cheese.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
            cheese.strokeColor = SKColor(red: 0.88, green: 0.65, blue: 0.15, alpha: 1.0)
            cheese.lineWidth = 1.5
            node.addChild(cheese)

            // Pepperoni (larger, with highlights)
            let pepPositions = [
                CGPoint(x: -5, y: 2), CGPoint(x: 6, y: -2),
                CGPoint(x: 0, y: 12), CGPoint(x: -2, y: -5)]
            for pos in pepPositions {
                let pep = SKShapeNode(circleOfRadius: 4)
                pep.fillColor = SKColor(red: 0.72, green: 0.12, blue: 0.08, alpha: 1.0)
                pep.strokeColor = SKColor(red: 0.55, green: 0.08, blue: 0.05, alpha: 1.0)
                pep.lineWidth = 1
                pep.position = pos
                node.addChild(pep)
                // Pepperoni highlight
                let pepShine = SKShapeNode(circleOfRadius: 1.5)
                pepShine.fillColor = SKColor(red: 0.85, green: 0.25, blue: 0.18, alpha: 0.7)
                pepShine.strokeColor = .clear
                pepShine.position = CGPoint(x: pos.x - 1, y: pos.y + 1)
                node.addChild(pepShine)
            }

            // Cheese drip
            let dripPath = CGMutablePath()
            dripPath.move(to: CGPoint(x: -8, y: -8))
            dripPath.addQuadCurve(to: CGPoint(x: -10, y: -18),
                                  control: CGPoint(x: -6, y: -14))
            dripPath.addQuadCurve(to: CGPoint(x: -5, y: -8),
                                  control: CGPoint(x: -4, y: -13))
            dripPath.closeSubpath()
            let drip = SKShapeNode(path: dripPath)
            drip.fillColor = SKColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 0.9)
            drip.strokeColor = .clear
            node.addChild(drip)

        case .tennisBall:
            // Main ball
            let ball = SKShapeNode(circleOfRadius: 16)
            ball.fillColor = SKColor(red: 0.78, green: 0.92, blue: 0.08, alpha: 1.0)
            ball.strokeColor = SKColor(red: 0.55, green: 0.7, blue: 0.0, alpha: 1.0)
            ball.lineWidth = 2
            node.addChild(ball)

            // Seam line (left curve)
            let seam1Path = CGMutablePath()
            seam1Path.addArc(center: CGPoint(x: -10, y: 0), radius: 12,
                             startAngle: -.pi * 0.35, endAngle: .pi * 0.35, clockwise: false)
            let seam1 = SKShapeNode(path: seam1Path)
            seam1.strokeColor = SKColor(white: 1.0, alpha: 0.6)
            seam1.lineWidth = 2
            seam1.fillColor = .clear
            node.addChild(seam1)

            // Seam line (right curve)
            let seam2Path = CGMutablePath()
            seam2Path.addArc(center: CGPoint(x: 10, y: 0), radius: 12,
                             startAngle: .pi * 0.65, endAngle: .pi * 1.35, clockwise: false)
            let seam2 = SKShapeNode(path: seam2Path)
            seam2.strokeColor = SKColor(white: 1.0, alpha: 0.6)
            seam2.lineWidth = 2
            seam2.fillColor = .clear
            node.addChild(seam2)

            // Fuzzy highlight
            let highlight = SKShapeNode(circleOfRadius: 6)
            highlight.fillColor = SKColor(red: 0.9, green: 1.0, blue: 0.4, alpha: 0.4)
            highlight.strokeColor = .clear
            highlight.position = CGPoint(x: -5, y: 5)
            node.addChild(highlight)
        }
        return node
    }

    private func buildPowerUpShape(type: PowerUpType) -> SKNode {
        let node = SKNode()
        switch type {
        case .magnet:
            // Horseshoe magnet shape
            let armPath = CGMutablePath()
            armPath.addArc(center: CGPoint(x: 0, y: 0), radius: 14,
                           startAngle: 0, endAngle: .pi, clockwise: false)
            armPath.addLine(to: CGPoint(x: -14, y: -12))
            armPath.addLine(to: CGPoint(x: -8, y: -12))
            armPath.addArc(center: CGPoint(x: 0, y: 0), radius: 8,
                           startAngle: .pi, endAngle: 0, clockwise: true)
            armPath.addLine(to: CGPoint(x: 14, y: -12))
            armPath.closeSubpath()
            let magnet = SKShapeNode(path: armPath)
            magnet.fillColor = SKColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1.0)
            magnet.strokeColor = SKColor(red: 0.6, green: 0.05, blue: 0.05, alpha: 1.0)
            magnet.lineWidth = 2
            node.addChild(magnet)

            // Silver tips
            for xOff: CGFloat in [-11, 8] {
                let tip = SKSpriteNode(
                    color: SKColor(white: 0.82, alpha: 1.0),
                    size: CGSize(width: 6, height: 6))
                tip.position = CGPoint(x: xOff, y: -10)
                node.addChild(tip)
            }

        case .shield:
            // Shield shape
            let shieldPath = CGMutablePath()
            shieldPath.move(to: CGPoint(x: 0, y: 18))
            shieldPath.addQuadCurve(to: CGPoint(x: 16, y: 6), control: CGPoint(x: 16, y: 18))
            shieldPath.addQuadCurve(to: CGPoint(x: 0, y: -18), control: CGPoint(x: 16, y: -10))
            shieldPath.addQuadCurve(to: CGPoint(x: -16, y: 6), control: CGPoint(x: -16, y: -10))
            shieldPath.addQuadCurve(to: CGPoint(x: 0, y: 18), control: CGPoint(x: -16, y: 18))
            let shield = SKShapeNode(path: shieldPath)
            shield.fillColor = SKColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.9)
            shield.strokeColor = SKColor(red: 0.15, green: 0.4, blue: 0.85, alpha: 1.0)
            shield.lineWidth = 2.5
            node.addChild(shield)

            // Star/cross highlight
            let star = SKSpriteNode(
                color: SKColor(white: 1.0, alpha: 0.6),
                size: CGSize(width: 4, height: 16))
            star.position.y = 2
            node.addChild(star)
            let starH = SKSpriteNode(
                color: SKColor(white: 1.0, alpha: 0.6),
                size: CGSize(width: 16, height: 4))
            starH.position.y = 2
            node.addChild(starH)

        case .doubleScore:
            // Gold circle
            let circle = SKShapeNode(circleOfRadius: 16)
            circle.fillColor = SKColor(red: 1.0, green: 0.82, blue: 0.1, alpha: 1.0)
            circle.strokeColor = SKColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1.0)
            circle.lineWidth = 2.5
            node.addChild(circle)

            // "2X" label
            let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            label.text = "2X"
            label.fontSize = 14
            label.fontColor = SKColor(red: 0.5, green: 0.25, blue: 0.0, alpha: 1.0)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            node.addChild(label)
        }
        return node
    }

    func reset() {
        spawnTimer = 0
        nextSpawnTime = 1.2
        distanceTraveled = 0
        restBlockTimer = 0
        nextRestDistance = 500
        gauntletRowsRemaining = 0
        // Recycle all active nodes back to pools
        for name in ["obstacle", "collectible", "powerUp"] {
            var toRecycle: [SKNode] = []
            scene?.enumerateChildNodes(withName: name) { node, _ in toRecycle.append(node) }
            for node in toRecycle { recycleNode(node) }
        }
    }
}
