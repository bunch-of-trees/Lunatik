import SpriteKit

class GameOverScene: SKScene {

    var finalScore: Int = 0
    var highScore: Int = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.12, green: 0.1, blue: 0.2, alpha: 1.0)

        setupGameOverText()
        setupScores()
        setupLunaSprite()
        setupRestart()
    }

    private func setupGameOverText() {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "GAME OVER"
        label.fontSize = 44
        label.fontColor = SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0)
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.82)
        label.zPosition = 50
        addChild(label)

        label.setScale(0.1)
        label.run(SKAction.scale(to: 1.0, duration: 0.4))
    }

    private func setupScores() {
        let scoreTitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        scoreTitle.text = "Score"
        scoreTitle.fontSize = 18
        scoreTitle.fontColor = SKColor(white: 0.7, alpha: 1.0)
        scoreTitle.position = CGPoint(x: size.width / 2, y: size.height * 0.68)
        scoreTitle.zPosition = 50
        addChild(scoreTitle)

        let scoreValue = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreValue.text = "\(finalScore)"
        scoreValue.fontSize = 52
        scoreValue.fontColor = .white
        scoreValue.position = CGPoint(x: size.width / 2, y: size.height * 0.59)
        scoreValue.zPosition = 50
        addChild(scoreValue)

        // Count up animation
        if finalScore > 0 {
            var display = 0
            let inc = max(1, finalScore / 25)
            let countAction = SKAction.repeat(
                SKAction.sequence([
                    SKAction.run {
                        display = min(display + inc, self.finalScore)
                        scoreValue.text = "\(display)"
                    },
                    SKAction.wait(forDuration: 0.04)
                ]),
                count: 25
            )
            scoreValue.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.3),
                countAction,
                SKAction.run { scoreValue.text = "\(self.finalScore)" }
            ]))
        }

        let isNewRecord = finalScore >= highScore && finalScore > 0
        let hsLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        hsLabel.text = isNewRecord ? "NEW BEST!" : "Best: \(highScore)"
        hsLabel.fontSize = 22
        hsLabel.fontColor = isNewRecord
            ? SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
            : SKColor(white: 0.55, alpha: 1.0)
        hsLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
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

    private func setupLunaSprite() {
        let texture = SKTexture(imageNamed: "LunaSprite")
        let aspectRatio = texture.size().width / texture.size().height
        let spriteHeight: CGFloat = 160
        let sprite = SKSpriteNode(texture: texture,
                                  size: CGSize(width: spriteHeight * aspectRatio, height: spriteHeight))
        sprite.position = CGPoint(x: size.width / 2, y: size.height * 0.3)
        sprite.zPosition = 20
        addChild(sprite)

        // Sad tilt
        sprite.zRotation = -0.1
    }

    private func setupRestart() {
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = "Tap to Play Again"
        label.fontSize = 22
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.1)
        label.zPosition = 50
        addChild(label)

        let fade = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ])
        label.run(SKAction.repeatForever(fade))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        view?.presentScene(gameScene, transition: SKTransition.doorway(withDuration: 0.8))
    }
}
