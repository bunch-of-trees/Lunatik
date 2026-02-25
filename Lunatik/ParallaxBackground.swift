import SpriteKit

class ParallaxBackground {

    private weak var scene: SKScene?
    private var roadStripes: [SKNode] = []
    private var sideObjects: [SKNode] = []
    private let stripeSpacing: CGFloat = 80

    init(scene: SKScene) {
        self.scene = scene
        buildBackground()
    }

    private func buildBackground() {
        guard let scene = scene else { return }
        let w = scene.size.width
        let h = scene.size.height

        // Sky / grass background
        let grass = SKSpriteNode(
            color: SKColor(red: 0.35, green: 0.68, blue: 0.28, alpha: 1.0),
            size: scene.size
        )
        grass.position = CGPoint(x: w / 2, y: h / 2)
        grass.zPosition = -100
        scene.addChild(grass)

        // Road / path
        let roadWidth = w * 0.88
        let road = SKSpriteNode(
            color: SKColor(red: 0.72, green: 0.7, blue: 0.66, alpha: 1.0),
            size: CGSize(width: roadWidth, height: h)
        )
        road.position = CGPoint(x: w / 2, y: h / 2)
        road.zPosition = -90
        scene.addChild(road)

        // Road edges
        let edgeWidth: CGFloat = 4
        for xPos in [w / 2 - roadWidth / 2, w / 2 + roadWidth / 2] {
            let edge = SKSpriteNode(
                color: SKColor(red: 0.55, green: 0.53, blue: 0.5, alpha: 1.0),
                size: CGSize(width: edgeWidth, height: h)
            )
            edge.position = CGPoint(x: xPos, y: h / 2)
            edge.zPosition = -85
            scene.addChild(edge)
        }

        // Lane dividers (dashed lines)
        let laneWidth = w / 3.0
        for laneDiv in 1...2 {
            let divX = laneWidth * CGFloat(laneDiv)
            let numDashes = Int(h / stripeSpacing) + 2
            for i in 0..<numDashes {
                let dash = SKSpriteNode(
                    color: SKColor(red: 0.6, green: 0.58, blue: 0.55, alpha: 0.4),
                    size: CGSize(width: 3, height: 30)
                )
                dash.position = CGPoint(x: divX, y: CGFloat(i) * stripeSpacing)
                dash.zPosition = -80
                dash.name = "laneDash"
                scene.addChild(dash)
                roadStripes.append(dash)
            }
        }

        // Center road dashes (scrolling)
        let numCenter = Int(h / stripeSpacing) + 2
        for i in 0..<numCenter {
            let centerDash = SKSpriteNode(
                color: SKColor(red: 0.9, green: 0.88, blue: 0.82, alpha: 0.15),
                size: CGSize(width: 2, height: 20)
            )
            centerDash.position = CGPoint(x: w / 2, y: CGFloat(i) * stripeSpacing + 40)
            centerDash.zPosition = -79
            centerDash.name = "laneDash"
            scene.addChild(centerDash)
            roadStripes.append(centerDash)
        }

        // Side decorations (trees, bushes)
        buildSideDecorations(scene: scene)
    }

    private func buildSideDecorations(scene: SKScene) {
        let w = scene.size.width
        let h = scene.size.height
        let spacing: CGFloat = 180

        for i in 0..<(Int(h / spacing) + 3) {
            let y = CGFloat(i) * spacing

            // Left side
            let leftDecor = createSideDecoration()
            leftDecor.position = CGPoint(x: CGFloat.random(in: -10...25), y: y)
            leftDecor.zPosition = -40
            leftDecor.name = "sideDecor"
            scene.addChild(leftDecor)
            sideObjects.append(leftDecor)

            // Right side
            let rightDecor = createSideDecoration()
            rightDecor.position = CGPoint(x: w - CGFloat.random(in: -10...25), y: y + spacing / 2)
            rightDecor.zPosition = -40
            rightDecor.name = "sideDecor"
            rightDecor.xScale = -1
            scene.addChild(rightDecor)
            sideObjects.append(rightDecor)
        }
    }

    private func createSideDecoration() -> SKNode {
        let node = SKNode()

        if Bool.random() {
            // Tree
            let trunk = SKSpriteNode(
                color: SKColor(red: 0.45, green: 0.3, blue: 0.15, alpha: 1.0),
                size: CGSize(width: 10, height: 35)
            )
            trunk.position.y = 17
            node.addChild(trunk)

            let foliage = SKShapeNode(circleOfRadius: CGFloat.random(in: 18...28))
            foliage.fillColor = SKColor(
                red: CGFloat.random(in: 0.2...0.35),
                green: CGFloat.random(in: 0.5...0.7),
                blue: CGFloat.random(in: 0.15...0.3),
                alpha: 1.0
            )
            foliage.strokeColor = .clear
            foliage.position.y = 40
            node.addChild(foliage)
        } else {
            // Bush
            let bush = SKShapeNode(ellipseOf: CGSize(
                width: CGFloat.random(in: 25...40),
                height: CGFloat.random(in: 15...25)
            ))
            bush.fillColor = SKColor(
                red: CGFloat.random(in: 0.25...0.4),
                green: CGFloat.random(in: 0.55...0.75),
                blue: CGFloat.random(in: 0.15...0.3),
                alpha: 1.0
            )
            bush.strokeColor = .clear
            bush.position.y = 8
            node.addChild(bush)
        }

        return node
    }

    // MARK: - Update

    func update(speed: CGFloat, deltaTime: TimeInterval) {
        let dy = -speed * CGFloat(deltaTime)

        // Scroll road stripes
        for stripe in roadStripes {
            stripe.position.y += dy
            if stripe.position.y < -40 {
                stripe.position.y += stripeSpacing * CGFloat(roadStripes.count / 5 + 2)
            }
        }

        // Scroll side decorations
        for obj in sideObjects {
            obj.position.y += dy * 0.8
            if obj.position.y < -60 {
                let maxY = sideObjects.map { $0.position.y }.max() ?? 0
                obj.position.y = maxY + 180
            }
        }
    }
}
