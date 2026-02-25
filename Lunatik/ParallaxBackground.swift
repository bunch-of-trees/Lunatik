import SpriteKit

class ParallaxBackground {

    private weak var scene: SKScene?
    private var layers: [(nodes: [SKNode], speed: CGFloat)] = []
    private let groundHeight = GameConstants.groundHeight

    init(scene: SKScene) {
        self.scene = scene
        buildBackground()
    }

    private func buildBackground() {
        guard let scene = scene else { return }
        let w = scene.size.width
        let h = scene.size.height

        // Sky gradient
        let sky = SKSpriteNode(color: SKColor(red: 0.45, green: 0.72, blue: 0.95, alpha: 1.0), size: scene.size)
        sky.position = CGPoint(x: w / 2, y: h / 2)
        sky.zPosition = -100
        scene.addChild(sky)

        // Sun
        let sun = SKShapeNode(circleOfRadius: 30)
        sun.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1.0)
        sun.strokeColor = SKColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 0.5)
        sun.lineWidth = 8
        sun.position = CGPoint(x: w * 0.8, y: h * 0.85)
        sun.zPosition = -99
        scene.addChild(sun)

        // Clouds (far layer - slowest)
        var cloudNodes: [SKNode] = []
        for i in 0..<4 {
            let cloud = createCloud()
            cloud.position = CGPoint(
                x: CGFloat(i) * (w / 2) + CGFloat.random(in: -30...30),
                y: h * CGFloat.random(in: 0.7...0.9)
            )
            cloud.zPosition = -90
            scene.addChild(cloud)
            cloudNodes.append(cloud)
        }
        layers.append((nodes: cloudNodes, speed: 0.1))

        // Buildings (mid layer)
        var buildingNodes: [SKNode] = []
        for i in 0..<6 {
            let building = createBuilding()
            let buildingH = building.frame.height
            building.position = CGPoint(
                x: CGFloat(i) * 160 + CGFloat.random(in: -20...20),
                y: groundHeight + buildingH / 2 - 5
            )
            building.zPosition = -50
            scene.addChild(building)
            buildingNodes.append(building)
        }
        layers.append((nodes: buildingNodes, speed: 0.3))

        // Trees (near-mid layer)
        var treeNodes: [SKNode] = []
        for i in 0..<8 {
            let tree = createTree()
            tree.position = CGPoint(
                x: CGFloat(i) * 130 + CGFloat.random(in: -20...20),
                y: groundHeight + 25
            )
            tree.zPosition = -30
            scene.addChild(tree)
            treeNodes.append(tree)
        }
        layers.append((nodes: treeNodes, speed: 0.6))

        // Ground
        buildGround(scene: scene, width: w)
    }

    private func buildGround(scene: SKScene, width: CGFloat) {
        // Grass layer
        let grass = SKSpriteNode(
            color: SKColor(red: 0.35, green: 0.7, blue: 0.25, alpha: 1.0),
            size: CGSize(width: width * 3, height: 15)
        )
        grass.position = CGPoint(x: width, y: groundHeight + 7)
        grass.zPosition = -10
        scene.addChild(grass)

        // Sidewalk
        let sidewalk = SKSpriteNode(
            color: SKColor(red: 0.78, green: 0.76, blue: 0.72, alpha: 1.0),
            size: CGSize(width: width * 3, height: groundHeight)
        )
        sidewalk.position = CGPoint(x: width, y: groundHeight / 2)
        sidewalk.zPosition = -10
        scene.addChild(sidewalk)

        // Sidewalk lines
        for i in 0..<30 {
            let line = SKSpriteNode(
                color: SKColor(red: 0.7, green: 0.68, blue: 0.65, alpha: 0.5),
                size: CGSize(width: 2, height: groundHeight)
            )
            line.position = CGPoint(x: CGFloat(i) * 60, y: groundHeight / 2)
            line.zPosition = -9
            scene.addChild(line)
        }

        // Ground physics body
        let groundBody = SKNode()
        groundBody.position = CGPoint(x: width / 2, y: groundHeight)
        let groundPhysics = SKPhysicsBody(rectangleOf: CGSize(width: width * 5, height: 2))
        groundPhysics.isDynamic = false
        groundPhysics.categoryBitMask = PhysicsCategory.ground
        groundPhysics.contactTestBitMask = PhysicsCategory.luna
        groundPhysics.friction = 0.5
        groundBody.physicsBody = groundPhysics
        scene.addChild(groundBody)
    }

    // MARK: - Create Background Elements

    private func createCloud() -> SKNode {
        let cloud = SKNode()
        let sizes: [(CGFloat, CGFloat)] = [(30, 18), (22, 15), (25, 16)]
        let offsets: [CGPoint] = [CGPoint(x: 0, y: 0), CGPoint(x: 20, y: 3), CGPoint(x: -18, y: -2)]

        for i in 0..<sizes.count {
            let puff = SKShapeNode(ellipseOf: CGSize(width: sizes[i].0, height: sizes[i].1))
            puff.fillColor = SKColor(white: 1.0, alpha: 0.9)
            puff.strokeColor = .clear
            puff.position = offsets[i]
            cloud.addChild(puff)
        }
        return cloud
    }

    private func createBuilding() -> SKNode {
        let building = SKNode()
        let width = CGFloat.random(in: 50...80)
        let height = CGFloat.random(in: 60...120)

        let colors: [SKColor] = [
            SKColor(red: 0.65, green: 0.55, blue: 0.5, alpha: 1.0),
            SKColor(red: 0.55, green: 0.5, blue: 0.6, alpha: 1.0),
            SKColor(red: 0.6, green: 0.6, blue: 0.55, alpha: 1.0),
            SKColor(red: 0.7, green: 0.6, blue: 0.55, alpha: 1.0),
        ]

        let rect = SKSpriteNode(color: colors.randomElement()!, size: CGSize(width: width, height: height))
        building.addChild(rect)

        // Windows
        let windowRows = Int(height / 25)
        let windowCols = Int(width / 20)
        for row in 0..<windowRows {
            for col in 0..<windowCols {
                let window = SKSpriteNode(
                    color: SKColor(red: 0.95, green: 0.92, blue: 0.6, alpha: CGFloat.random(in: 0.3...0.9)),
                    size: CGSize(width: 8, height: 10)
                )
                window.position = CGPoint(
                    x: -width / 2 + 12 + CGFloat(col) * 18,
                    y: -height / 2 + 15 + CGFloat(row) * 22
                )
                building.addChild(window)
            }
        }
        return building
    }

    private func createTree() -> SKNode {
        let tree = SKNode()

        // Trunk
        let trunk = SKSpriteNode(
            color: SKColor(red: 0.45, green: 0.3, blue: 0.15, alpha: 1.0),
            size: CGSize(width: 8, height: 30)
        )
        trunk.position = CGPoint(x: 0, y: 15)
        tree.addChild(trunk)

        // Foliage
        let foliageColors: [SKColor] = [
            SKColor(red: 0.2, green: 0.55, blue: 0.2, alpha: 1.0),
            SKColor(red: 0.25, green: 0.6, blue: 0.25, alpha: 1.0),
            SKColor(red: 0.3, green: 0.65, blue: 0.2, alpha: 1.0),
        ]

        for i in 0..<3 {
            let radius = CGFloat.random(in: 14...22)
            let foliage = SKShapeNode(circleOfRadius: radius)
            foliage.fillColor = foliageColors[i % foliageColors.count]
            foliage.strokeColor = .clear
            foliage.position = CGPoint(
                x: CGFloat.random(in: -8...8),
                y: 30 + CGFloat(i) * 8
            )
            tree.addChild(foliage)
        }
        return tree
    }

    // MARK: - Update

    func update(speed: CGFloat, deltaTime: TimeInterval) {
        guard let scene = scene else { return }
        let w = scene.size.width

        for layer in layers {
            let dx = -speed * layer.speed * CGFloat(deltaTime)
            for node in layer.nodes {
                node.position.x += dx

                // Wrap around when off screen
                if node.position.x < -100 {
                    let maxX = layer.nodes.map { $0.position.x }.max() ?? 0
                    let spacing: CGFloat = layer.speed < 0.2 ? w / 2 : (layer.speed < 0.5 ? 160 : 130)
                    node.position.x = maxX + spacing + CGFloat.random(in: -20...20)
                }
            }
        }
    }
}
