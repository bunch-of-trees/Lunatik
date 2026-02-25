import SpriteKit

class GameOverScene: SKScene {

    var finalScore: Int = 0
    var highScore: Int = 0

    private var luna: LunaCharacter!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.15, green: 0.12, blue: 0.22, alpha: 1.0)

        setupBackground()
        setupGameOverText()
        setupScores()
        setupLuna()
        setupRestart()
    }

    private func setupBackground() {
        // Darker moody background
        let overlay = SKSpriteNode(
            color: SKColor(red: 0.1, green: 0.08, blue: 0.18, alpha: 0.5),
            size: size
        )
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = -10
        addChild(overlay)

        // Sad clouds
        for i in 0..<3 {
            let cloud = SKShapeNode(ellipseOf: CGSize(width: 60, height: 25))
            cloud.fillColor = SKColor(white: 0.3, alpha: 0.4)
            cloud.strokeColor = .clear
            cloud.position = CGPoint(
                x: CGFloat(i + 1) * size.width / 4,
                y: size.height * CGFloat.random(in: 0.75...0.9)
            )
            cloud.zPosition = -5
            addChild(cloud)
        }
    }

    private func setupGameOverText() {
        let gameOver = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        gameOver.text = "GAME OVER"
        gameOver.fontSize = 42
        gameOver.fontColor = SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0)
        gameOver.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        gameOver.zPosition = 50
        addChild(gameOver)

        // Drop in animation
        gameOver.setScale(0.1)
        gameOver.run(SKAction.scale(to: 1.0, duration: 0.4))
    }

    private func setupScores() {
        // Final score
        let scoreTitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        scoreTitle.text = "Score"
        scoreTitle.fontSize = 18
        scoreTitle.fontColor = SKColor(white: 0.7, alpha: 1.0)
        scoreTitle.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        scoreTitle.zPosition = 50
        addChild(scoreTitle)

        let scoreValue = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreValue.text = "\(finalScore)"
        scoreValue.fontSize = 48
        scoreValue.fontColor = .white
        scoreValue.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
        scoreValue.zPosition = 50
        addChild(scoreValue)

        // Animate score counting up
        let countDuration = min(Double(finalScore) * 0.01, 1.5)
        if finalScore > 0 {
            var displayScore = 0
            let increment = max(1, finalScore / 30)
            let countAction = SKAction.repeat(
                SKAction.sequence([
                    SKAction.run {
                        displayScore = min(displayScore + increment, self.finalScore)
                        scoreValue.text = "\(displayScore)"
                    },
                    SKAction.wait(forDuration: countDuration / 30)
                ]),
                count: 30
            )
            scoreValue.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.3),
                countAction,
                SKAction.run { scoreValue.text = "\(self.finalScore)" }
            ]))
        }

        // High score
        let hsLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        let isNewRecord = finalScore >= highScore && finalScore > 0
        hsLabel.text = isNewRecord ? "NEW BEST!" : "Best: \(highScore)"
        hsLabel.fontSize = 20
        hsLabel.fontColor = isNewRecord
            ? SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
            : SKColor(white: 0.6, alpha: 1.0)
        hsLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.45)
        hsLabel.zPosition = 50
        addChild(hsLabel)

        if isNewRecord {
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.3)
            ])
            hsLabel.run(SKAction.repeatForever(pulse))
        }
    }

    private func setupLuna() {
        luna = LunaCharacter()
        luna.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
        luna.zPosition = 20
        luna.setScale(1.5)
        addChild(luna)

        // Luna lies down (tilt)
        luna.zRotation = -0.15
    }

    private func setupRestart() {
        let restart = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        restart.text = "Tap to Play Again"
        restart.fontSize = 20
        restart.fontColor = .white
        restart.position = CGPoint(x: size.width / 2, y: size.height * 0.1)
        restart.zPosition = 50
        addChild(restart)

        let fadeInOut = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ])
        restart.run(SKAction.repeatForever(fadeInOut))
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        let transition = SKTransition.doorway(withDuration: 0.8)
        view?.presentScene(gameScene, transition: transition)
    }
}
