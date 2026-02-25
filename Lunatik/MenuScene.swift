import SpriteKit

class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.15, green: 0.25, blue: 0.45, alpha: 1.0)

        setupBackground()
        setupTitle()
        setupLunaSprite()
        setupTapToStart()
        setupHighScore()
    }

    private func setupBackground() {
        // Gradient layers
        let top = SKSpriteNode(
            color: SKColor(red: 0.12, green: 0.2, blue: 0.4, alpha: 1.0),
            size: CGSize(width: size.width, height: size.height / 2)
        )
        top.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        top.zPosition = -10
        addChild(top)

        let bottom = SKSpriteNode(
            color: SKColor(red: 0.22, green: 0.35, blue: 0.55, alpha: 1.0),
            size: CGSize(width: size.width, height: size.height / 2)
        )
        bottom.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
        bottom.zPosition = -10
        addChild(bottom)

        // Ground
        let ground = SKSpriteNode(
            color: SKColor(red: 0.3, green: 0.6, blue: 0.25, alpha: 1.0),
            size: CGSize(width: size.width, height: size.height * 0.15)
        )
        ground.position = CGPoint(x: size.width / 2, y: size.height * 0.075)
        ground.zPosition = -5
        addChild(ground)

        // Stars
        for _ in 0..<25 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
            star.fillColor = SKColor(white: 1.0, alpha: CGFloat.random(in: 0.3...0.9))
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height * 0.45...size.height)
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
        let moon = SKShapeNode(circleOfRadius: 30)
        moon.fillColor = SKColor(red: 0.95, green: 0.93, blue: 0.8, alpha: 1.0)
        moon.strokeColor = SKColor(red: 0.9, green: 0.88, blue: 0.7, alpha: 0.4)
        moon.lineWidth = 4
        moon.position = CGPoint(x: size.width * 0.78, y: size.height * 0.88)
        moon.zPosition = -9
        addChild(moon)
    }

    private func setupTitle() {
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "LUNATIK"
        title.fontSize = 58
        title.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        title.zPosition = 50
        addChild(title)

        let shadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        shadow.text = "LUNATIK"
        shadow.fontSize = 58
        shadow.fontColor = SKColor(red: 0.5, green: 0.25, blue: 0.0, alpha: 0.5)
        shadow.position = CGPoint(x: 3, y: -3)
        shadow.zPosition = -1
        title.addChild(shadow)

        let subtitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        subtitle.text = "Luna's Wild Run!"
        subtitle.fontSize = 20
        subtitle.fontColor = SKColor(white: 1.0, alpha: 0.8)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        subtitle.zPosition = 50
        addChild(subtitle)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8)
        ])
        title.run(SKAction.repeatForever(pulse))
    }

    private func setupLunaSprite() {
        let texture = SKTexture(imageNamed: "LunaSprite")
        let aspectRatio = texture.size().width / texture.size().height
        let spriteHeight: CGFloat = 220
        let sprite = SKSpriteNode(texture: texture,
                                  size: CGSize(width: spriteHeight * aspectRatio, height: spriteHeight))
        sprite.position = CGPoint(x: size.width / 2, y: size.height * 0.42)
        sprite.zPosition = 20
        addChild(sprite)

        // Gentle bounce
        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 12, duration: 0.7),
            SKAction.moveBy(x: 0, y: -12, duration: 0.7)
        ])
        sprite.run(SKAction.repeatForever(bounce))
    }

    private func setupTapToStart() {
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = "Tap to Play!"
        label.fontSize = 24
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
        label.zPosition = 50
        addChild(label)

        let fade = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ])
        label.run(SKAction.repeatForever(fade))

        // Swipe hints
        let hints = SKLabelNode(fontNamed: "AvenirNext-Regular")
        hints.text = "Swipe to dodge! ← → ↑ ↓"
        hints.fontSize = 14
        hints.fontColor = SKColor(white: 1.0, alpha: 0.5)
        hints.position = CGPoint(x: size.width / 2, y: size.height * 0.15)
        hints.zPosition = 50
        addChild(hints)
    }

    private func setupHighScore() {
        let hs = UserDefaults.standard.integer(forKey: "LunatikHighScore")
        if hs > 0 {
            let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
            label.text = "Best: \(hs)"
            label.fontSize = 16
            label.fontColor = SKColor(white: 1.0, alpha: 0.55)
            label.position = CGPoint(x: size.width / 2, y: size.height * 0.11)
            label.zPosition = 50
            addChild(label)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        view?.presentScene(gameScene, transition: SKTransition.doorway(withDuration: 0.8))
    }
}
