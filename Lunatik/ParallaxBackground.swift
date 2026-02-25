import SpriteKit

class ParallaxBackground {

    private weak var scene: SKScene?
    private var roadStripes: [SKNode] = []
    private var sideObjects: [SKNode] = []
    private let stripeSpacing: CGFloat = 70

    init(scene: SKScene) {
        self.scene = scene
        buildBackground()
    }

    private func buildBackground() {
        guard let scene = scene else { return }
        let w = scene.size.width
        let h = scene.size.height

        // Grass background
        let grass = SKSpriteNode(
            color: SKColor(red: 0.32, green: 0.65, blue: 0.25, alpha: 1.0),
            size: scene.size
        )
        grass.position = CGPoint(x: w / 2, y: h / 2)
        grass.zPosition = -100
        scene.addChild(grass)

        // Perspective road (trapezoid)
        let roadPath = CGMutablePath()
        let nearWidth = w * 0.92
        let farWidth = w * 0.32
        let nearLeft = (w - nearWidth) / 2
        let nearRight = nearLeft + nearWidth
        let farLeft = (w - farWidth) / 2
        let farRight = farLeft + farWidth

        roadPath.move(to: CGPoint(x: nearLeft, y: 0))
        roadPath.addLine(to: CGPoint(x: farLeft, y: h))
        roadPath.addLine(to: CGPoint(x: farRight, y: h))
        roadPath.addLine(to: CGPoint(x: nearRight, y: 0))
        roadPath.closeSubpath()

        let road = SKShapeNode(path: roadPath)
        road.fillColor = SKColor(red: 0.68, green: 0.66, blue: 0.62, alpha: 1.0)
        road.strokeColor = .clear
        road.zPosition = -90
        scene.addChild(road)

        // Road edge lines
        let leftEdge = SKShapeNode()
        let leftPath = CGMutablePath()
        leftPath.move(to: CGPoint(x: nearLeft, y: 0))
        leftPath.addLine(to: CGPoint(x: farLeft, y: h))
        leftEdge.path = leftPath
        leftEdge.strokeColor = SKColor(red: 0.5, green: 0.48, blue: 0.45, alpha: 0.8)
        leftEdge.lineWidth = 3
        leftEdge.zPosition = -85
        scene.addChild(leftEdge)

        let rightEdge = SKShapeNode()
        let rightPath = CGMutablePath()
        rightPath.move(to: CGPoint(x: nearRight, y: 0))
        rightPath.addLine(to: CGPoint(x: farRight, y: h))
        rightEdge.path = rightPath
        rightEdge.strokeColor = SKColor(red: 0.5, green: 0.48, blue: 0.45, alpha: 0.8)
        rightEdge.lineWidth = 3
        rightEdge.zPosition = -85
        scene.addChild(rightEdge)

        // Lane divider lines (converging to vanishing point)
        let centerX = w / 2
        for laneDiv in [-1, 1] as [CGFloat] {
            let nearX = centerX + (nearWidth / 3) * laneDiv * 0.5
            let farX = centerX + (farWidth / 3) * laneDiv * 0.5

            // Dashed lane lines
            let numDashes = Int(h / stripeSpacing) + 2
            for i in 0..<numDashes {
                let t = CGFloat(i) / CGFloat(numDashes)
                let y = t * h
                let x = nearX + (farX - nearX) * t
                let dashScale = 1.0 - t * 0.6

                let dash = SKSpriteNode(
                    color: SKColor(white: 1.0, alpha: 0.15 + 0.15 * (1 - t)),
                    size: CGSize(width: 3 * dashScale, height: 25 * dashScale)
                )
                dash.position = CGPoint(x: x, y: y)
                dash.zPosition = -80
                dash.name = "roadDash"
                scene.addChild(dash)
                roadStripes.append(dash)
            }
        }

        // Side decorations
        buildSideDecorations(scene: scene)
    }

    private func buildSideDecorations(scene: SKScene) {
        let w = scene.size.width
        let h = scene.size.height
        let spacing: CGFloat = 160

        for i in 0..<(Int(h / spacing) + 3) {
            let t = CGFloat(i) / CGFloat(Int(h / spacing) + 3)

            // Left side
            let leftDecor = createSideDecoration(scale: 1.0 - t * 0.5)
            let leftX: CGFloat = max(5, (w * 0.04) + (w * 0.34 - w * 0.04) * t * 0.5)
            leftDecor.position = CGPoint(x: leftX, y: CGFloat(i) * spacing)
            leftDecor.zPosition = -40
            leftDecor.name = "sideDecor"
            scene.addChild(leftDecor)
            sideObjects.append(leftDecor)

            // Right side
            let rightDecor = createSideDecoration(scale: 1.0 - t * 0.5)
            let rightX: CGFloat = min(w - 5, w - (w * 0.04) - (w * 0.34 - w * 0.04) * t * 0.5)
            rightDecor.position = CGPoint(x: rightX, y: CGFloat(i) * spacing + spacing / 2)
            rightDecor.zPosition = -40
            rightDecor.name = "sideDecor"
            rightDecor.xScale = -rightDecor.xScale
            scene.addChild(rightDecor)
            sideObjects.append(rightDecor)
        }
    }

    private func createSideDecoration(scale: CGFloat) -> SKNode {
        let node = SKNode()
        node.setScale(scale)

        if Bool.random() {
            // Tree
            let trunk = SKSpriteNode(
                color: SKColor(red: 0.42, green: 0.28, blue: 0.13, alpha: 1.0),
                size: CGSize(width: 10, height: 30)
            )
            trunk.position.y = 15
            node.addChild(trunk)

            let foliage = SKShapeNode(circleOfRadius: CGFloat.random(in: 16...26))
            foliage.fillColor = SKColor(
                red: CGFloat.random(in: 0.18...0.32),
                green: CGFloat.random(in: 0.5...0.7),
                blue: CGFloat.random(in: 0.12...0.28),
                alpha: 1.0
            )
            foliage.strokeColor = .clear
            foliage.position.y = 38
            node.addChild(foliage)
        } else {
            // Bush / flower
            let bush = SKShapeNode(ellipseOf: CGSize(
                width: CGFloat.random(in: 22...38),
                height: CGFloat.random(in: 14...22)
            ))
            bush.fillColor = SKColor(
                red: CGFloat.random(in: 0.22...0.38),
                green: CGFloat.random(in: 0.52...0.72),
                blue: CGFloat.random(in: 0.12...0.28),
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

        for stripe in roadStripes {
            stripe.position.y += dy
            if stripe.position.y < -30 {
                stripe.position.y += stripeSpacing * CGFloat(Int(scene!.size.height / stripeSpacing) + 3)
            }
        }

        for obj in sideObjects {
            obj.position.y += dy * 0.75
            if obj.position.y < -50 {
                let maxY = sideObjects.map { $0.position.y }.max() ?? 0
                obj.position.y = maxY + 160
            }
        }
    }
}
