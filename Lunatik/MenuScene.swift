import SpriteKit

class MenuScene: SKScene {

    private var luna: LunaCharacter!
    private var tapToStart: SKLabelNode!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.2, green: 0.35, blue: 0.55, alpha: 1.0)

        setupBackground()
        setupTitle()
        setupLuna()
        setupTapToStart()
        setupHighScore()
    }

    private func setupBackground() {
        // Gradient-like background with shapes
        let topColor = SKSpriteNode(
            color: SKColor(red: 0.15, green: 0.25, blue: 0.45, alpha: 1.0),
            size: CGSize(width: size.width, height: size.height / 2)
        )
        topColor.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        topColor.zPosition = -10
        addChild(topColor)

        let bottomColor = SKSpriteNode(
            color: SKColor(red: 0.25, green: 0.4, blue: 0.6, alpha: 1.0),
            size: CGSize(width: size.width, height: size.height / 2)
        )
        bottomColor.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
        bottomColor.zPosition = -10
        addChild(bottomColor)

        // Ground stripe
        let ground = SKSpriteNode(
            color: SKColor(red: 0.35, green: 0.65, blue: 0.25, alpha: 1.0),
            size: CGSize(width: size.width, height: 60)
        )
        ground.position = CGPoint(x: size.width / 2, y: 30)
        ground.zPosition = -5
        addChild(ground)

        // Stars / sparkles
        for _ in 0..<20 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2.5))
            star.fillColor = SKColor(white: 1.0, alpha: CGFloat.random(in: 0.3...0.8))
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height * 0.5...size.height)
            )
            star.zPosition = -8
            addChild(star)

            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: Double.random(in: 0.5...1.5)),
                SKAction.fadeAlpha(to: 0.9, duration: Double.random(in: 0.5...1.5))
            ])
            star.run(SKAction.repeatForever(twinkle))
        }

        // Moon
        let moon = SKShapeNode(circleOfRadius: 25)
        moon.fillColor = SKColor(red: 0.95, green: 0.93, blue: 0.8, alpha: 1.0)
        moon.strokeColor = SKColor(red: 0.9, green: 0.88, blue: 0.7, alpha: 0.5)
        moon.lineWidth = 3
        moon.position = CGPoint(x: size.width * 0.8, y: size.height * 0.8)
        moon.zPosition = -9
        addChild(moon)

        // Moon crater
        let crater = SKShapeNode(circleOfRadius: 5)
        crater.fillColor = SKColor(red: 0.85, green: 0.83, blue: 0.7, alpha: 0.5)
        crater.strokeColor = .clear
        crater.position = CGPoint(x: 5, y: 5)
        moon.addChild(crater)
    }

    private func setupTitle() {
        // Main title
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "LUNATIK"
        title.fontSize = 56
        title.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        title.zPosition = 50
        addChild(title)

        // Title shadow
        let shadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        shadow.text = "LUNATIK"
        shadow.fontSize = 56
        shadow.fontColor = SKColor(red: 0.6, green: 0.3, blue: 0.0, alpha: 0.5)
        shadow.position = CGPoint(x: 3, y: -3)
        shadow.zPosition = -1
        title.addChild(shadow)

        // Subtitle
        let subtitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        subtitle.text = "Luna's Wild Run!"
        subtitle.fontSize = 18
        subtitle.fontColor = SKColor(white: 1.0, alpha: 0.8)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.63)
        subtitle.zPosition = 50
        addChild(subtitle)

        // Pulse animation on title
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8)
        ])
        title.run(SKAction.repeatForever(pulse))
    }

    private func setupLuna() {
        luna = LunaCharacter()
        luna.position = CGPoint(x: size.width / 2, y: 110)
        luna.zPosition = 20
        luna.setScale(1.8)
        addChild(luna)

        // Gentle bounce
        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 10, duration: 0.6),
            SKAction.moveBy(x: 0, y: -10, duration: 0.6)
        ])
        luna.run(SKAction.repeatForever(bounce))
    }

    private func setupTapToStart() {
        tapToStart = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        tapToStart.text = "Tap to Play!"
        tapToStart.fontSize = 22
        tapToStart.fontColor = .white
        tapToStart.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
        tapToStart.zPosition = 50
        addChild(tapToStart)

        let fadeInOut = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ])
        tapToStart.run(SKAction.repeatForever(fadeInOut))
    }

    private func setupHighScore() {
        let highScore = UserDefaults.standard.integer(forKey: "LunatikHighScore")
        if highScore > 0 {
            let hsLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            hsLabel.text = "Best: \(highScore)"
            hsLabel.fontSize = 16
            hsLabel.fontColor = SKColor(white: 1.0, alpha: 0.6)
            hsLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.14)
            hsLabel.zPosition = 50
            addChild(hsLabel)
        }
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        let transition = SKTransition.doorway(withDuration: 0.8)
        view?.presentScene(gameScene, transition: transition)
    }
}
