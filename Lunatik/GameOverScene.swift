import SpriteKit

class GameOverScene: SKScene {

    var finalScore: Int = 0
    var highScore: Int = 0
    var completedMissions: [Mission] = []
    var bonesEarned: Int = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.12, green: 0.1, blue: 0.2, alpha: 1.0)

        setupGameOverText()
        setupScores()
        setupBones()
        setupMissions()
        setupLunaSprite()
        setupRestart()
    }

    private func setupGameOverText() {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "GAME OVER"
        label.fontSize = 44
        label.fontColor = SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0)
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.88)
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
        scoreTitle.position = CGPoint(x: size.width / 2, y: size.height * 0.76)
        scoreTitle.zPosition = 50
        addChild(scoreTitle)

        let scoreValue = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreValue.text = "\(finalScore)"
        scoreValue.fontSize = 48
        scoreValue.fontColor = .white
        scoreValue.position = CGPoint(x: size.width / 2, y: size.height * 0.68)
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
        hsLabel.fontSize = 20
        hsLabel.fontColor = isNewRecord
            ? SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
            : SKColor(white: 0.55, alpha: 1.0)
        hsLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
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

    private func setupBones() {
        guard bonesEarned > 0 else { return }

        let boneLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        boneLabel.text = "+\(bonesEarned) bones"
        boneLabel.fontSize = 20
        boneLabel.fontColor = SKColor(red: 0.96, green: 0.94, blue: 0.88, alpha: 1.0)
        boneLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.57)
        boneLabel.zPosition = 50
        boneLabel.alpha = 0
        addChild(boneLabel)

        boneLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeIn(withDuration: 0.3)
        ]))

        let totalLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        totalLabel.text = "Total: \(MissionManager.shared.totalBones) bones"
        totalLabel.fontSize = 14
        totalLabel.fontColor = SKColor(white: 0.5, alpha: 1.0)
        totalLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.54)
        totalLabel.zPosition = 50
        totalLabel.alpha = 0
        addChild(totalLabel)

        totalLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.8),
            SKAction.fadeIn(withDuration: 0.3)
        ]))
    }

    private func setupMissions() {
        // Show completed missions
        if !completedMissions.isEmpty {
            var yPos = size.height * 0.49
            for (i, mission) in completedMissions.prefix(3).enumerated() {
                let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
                label.text = "COMPLETE: \(mission.description) (+\(mission.reward) bones)"
                label.fontSize = 13
                label.fontColor = SKColor(red: 0.3, green: 1.0, blue: 0.5, alpha: 1.0)
                label.position = CGPoint(x: size.width / 2, y: yPos)
                label.zPosition = 50
                label.alpha = 0
                addChild(label)

                label.run(SKAction.sequence([
                    SKAction.wait(forDuration: 2.0 + Double(i) * 0.3),
                    SKAction.fadeIn(withDuration: 0.3),
                    SKAction.scale(to: 1.08, duration: 0.15),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]))

                yPos -= 22
            }
        }

        // Show current active missions with progress
        let missions = MissionManager.shared.activeMissions
        if !missions.isEmpty {
            let headerY = completedMissions.isEmpty ? size.height * 0.49 : size.height * 0.49 - CGFloat(completedMissions.count) * 22 - 15
            let header = SKLabelNode(fontNamed: "AvenirNext-Medium")
            header.text = "MISSIONS"
            header.fontSize = 14
            header.fontColor = SKColor(white: 0.6, alpha: 1.0)
            header.position = CGPoint(x: size.width / 2, y: headerY)
            header.zPosition = 50
            header.alpha = 0
            addChild(header)

            let headerDelay = completedMissions.isEmpty ? 2.0 : 2.0 + Double(completedMissions.count) * 0.3 + 0.3
            header.run(SKAction.sequence([
                SKAction.wait(forDuration: headerDelay),
                SKAction.fadeIn(withDuration: 0.3)
            ]))

            var missionY = headerY - 20
            for (i, mission) in missions.prefix(3).enumerated() {
                let label = SKLabelNode(fontNamed: "AvenirNext-Regular")
                label.text = "\(mission.description) (\(mission.progressText))"
                label.fontSize = 12
                label.fontColor = SKColor(white: 0.5, alpha: 1.0)
                label.position = CGPoint(x: size.width / 2, y: missionY)
                label.zPosition = 50
                label.alpha = 0
                addChild(label)

                label.run(SKAction.sequence([
                    SKAction.wait(forDuration: headerDelay + 0.15 + Double(i) * 0.15),
                    SKAction.fadeIn(withDuration: 0.2)
                ]))

                missionY -= 18
            }
        }
    }

    private func setupLunaSprite() {
        let texture = SKTexture(imageNamed: "LunaSprite")
        let aspectRatio = texture.size().width / texture.size().height
        let spriteHeight: CGFloat = 120
        let sprite = SKSpriteNode(texture: texture,
                                  size: CGSize(width: spriteHeight * aspectRatio, height: spriteHeight))
        sprite.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
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
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.07)
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
        view?.presentScene(gameScene, transition: SKTransition.fade(with: .black, duration: 0.6))
    }
}
