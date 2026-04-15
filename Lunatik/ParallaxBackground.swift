import SpriteKit

class ParallaxBackground {

    private weak var scene: SKScene?

    private struct StripeInfo {
        var t: CGFloat  // parametric position: 0 = near (bottom), 1 = far (top)
        let dividerIndex: Int
        let node: SKSpriteNode
    }

    private var stripes: [StripeInfo] = []
    private var laneDividers: [(nearX: CGFloat, farX: CGFloat)] = []
    private var sideObjects: [SKNode] = []
    private let stripesPerDivider = 7

    // Environment color transition nodes
    private var grassNode: SKSpriteNode?
    private var skyOverlay: SKSpriteNode?
    private var currentZone: Int = 0

    // Color themes: (grass, skyTint alpha, skyTint color)
    private struct ColorTheme {
        let grassColor: SKColor
        let skyAlpha: CGFloat
        let skyColor: SKColor
    }

    private let themes: [ColorTheme] = [
        // Zone 0: Day (default green)
        ColorTheme(
            grassColor: SKColor(red: 0.32, green: 0.65, blue: 0.25, alpha: 1.0),
            skyAlpha: 0.0,
            skyColor: .clear
        ),
        // Zone 1: Sunset (warm golden tones)
        ColorTheme(
            grassColor: SKColor(red: 0.45, green: 0.55, blue: 0.22, alpha: 1.0),
            skyAlpha: 0.18,
            skyColor: SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        ),
        // Zone 2: Dusk (purple/blue tones)
        ColorTheme(
            grassColor: SKColor(red: 0.22, green: 0.38, blue: 0.28, alpha: 1.0),
            skyAlpha: 0.25,
            skyColor: SKColor(red: 0.4, green: 0.25, blue: 0.6, alpha: 1.0)
        ),
        // Zone 3: Night (deep blue)
        ColorTheme(
            grassColor: SKColor(red: 0.12, green: 0.22, blue: 0.18, alpha: 1.0),
            skyAlpha: 0.35,
            skyColor: SKColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0)
        ),
    ]

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
        grassNode = grass

        // Sky/atmosphere overlay for color transitions
        let sky = SKSpriteNode(color: .clear, size: scene.size)
        sky.position = CGPoint(x: w / 2, y: h / 2)
        sky.zPosition = -95
        sky.alpha = 0
        scene.addChild(sky)
        skyOverlay = sky

        // Perspective road (trapezoid)
        let roadPath = CGMutablePath()
        let nearWidth = w * 0.88
        let farWidth = w * 0.42
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
        leftEdge.strokeColor = SKColor(red: 0.5, green: 0.48, blue: 0.45, alpha: 0.5)
        leftEdge.lineWidth = 2
        leftEdge.zPosition = -85
        scene.addChild(leftEdge)

        let rightEdge = SKShapeNode()
        let rightPath = CGMutablePath()
        rightPath.move(to: CGPoint(x: nearRight, y: 0))
        rightPath.addLine(to: CGPoint(x: farRight, y: h))
        rightEdge.path = rightPath
        rightEdge.strokeColor = SKColor(red: 0.5, green: 0.48, blue: 0.45, alpha: 0.5)
        rightEdge.lineWidth = 2
        rightEdge.zPosition = -85
        scene.addChild(rightEdge)

        // Lane divider lines (converging to vanishing point)
        let centerX = w / 2
        for (idx, laneDiv) in ([-1, 1] as [CGFloat]).enumerated() {
            let nearX = centerX + (nearWidth / 3) * laneDiv * 0.5
            let farX = centerX + (farWidth / 3) * laneDiv * 0.5
            laneDividers.append((nearX: nearX, farX: farX))

            for i in 0..<stripesPerDivider {
                let t = CGFloat(i) / CGFloat(stripesPerDivider)
                let dashScale = 1.0 - t * 0.5

                let dash = SKSpriteNode(
                    color: SKColor(white: 0.9, alpha: 1.0),
                    size: CGSize(width: 3.5, height: 18)
                )
                dash.position = CGPoint(
                    x: nearX + (farX - nearX) * t,
                    y: t * h
                )
                dash.setScale(dashScale)
                dash.alpha = 0.08 + 0.10 * (1 - t)
                dash.zPosition = -80
                dash.name = "roadDash"
                scene.addChild(dash)
                stripes.append(StripeInfo(t: t, dividerIndex: idx, node: dash))
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
        let h = scene!.size.height
        let tSpeed = speed / h

        for i in stripes.indices {
            stripes[i].t -= CGFloat(deltaTime) * tSpeed
            if stripes[i].t < 0 {
                stripes[i].t += 1.0
            }

            let t = stripes[i].t
            let divider = laneDividers[stripes[i].dividerIndex]
            let dashScale = 1.0 - t * 0.5

            stripes[i].node.position = CGPoint(
                x: divider.nearX + (divider.farX - divider.nearX) * t,
                y: t * h
            )
            stripes[i].node.setScale(dashScale)
            stripes[i].node.alpha = 0.08 + 0.10 * (1 - t)
        }

        for obj in sideObjects {
            obj.position.y += dy * 0.75
            if obj.position.y < -50 {
                let maxY = sideObjects.map { $0.position.y }.max() ?? 0
                obj.position.y = maxY + 160
            }
        }
    }

    // MARK: - Environment Color Transitions

    /// Called by GameScene to notify zone changes externally (e.g. for music crossfade)
    var onZoneChange: ((Int) -> Void)?

    func updateEnvironment(distanceScore: CGFloat) {
        // Zones: 0-500 day, 500-1200 sunset, 1200-2000 dusk, 2000+ night
        let zoneThresholds: [CGFloat] = [0, 500, 1200, 2000]
        var newZone = 0
        for (i, threshold) in zoneThresholds.enumerated() {
            if distanceScore >= threshold { newZone = i }
        }

        guard newZone != currentZone else { return }
        currentZone = newZone

        let theme = themes[min(newZone, themes.count - 1)]

        // Animate grass color change
        grassNode?.run(SKAction.colorize(
            with: theme.grassColor,
            colorBlendFactor: 1.0,
            duration: 3.0
        ))

        // Animate sky overlay
        skyOverlay?.run(SKAction.group([
            SKAction.colorize(with: theme.skyColor, colorBlendFactor: 1.0, duration: 3.0),
            SKAction.fadeAlpha(to: theme.skyAlpha, duration: 3.0)
        ]))

        // Notify listeners (music crossfade)
        onZoneChange?(newZone)
    }
}
