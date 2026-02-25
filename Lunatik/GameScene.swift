import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    private var luna: LunaCharacter!
    private var background: ParallaxBackground!
    private var obstacleManager: ObstacleManager!

    private var scoreLabel: SKLabelNode!
    private var score: Int = 0
    private var distanceScore: CGFloat = 0

    private var currentSpeed: CGFloat = GameConstants.initialSpeed
    private var lastUpdateTime: TimeInterval = 0
    private var isGameOver = false

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.45, green: 0.72, blue: 0.95, alpha: 1.0)

        physicsWorld.gravity = CGVector(dx: 0, dy: GameConstants.gravity)
        physicsWorld.contactDelegate = self

        setupBackground()
        setupLuna()
        setupHUD()
        setupObstacleManager()
    }

    // MARK: - Setup

    private func setupBackground() {
        background = ParallaxBackground(scene: self)
    }

    private func setupLuna() {
        luna = LunaCharacter()
        luna.position = CGPoint(
            x: GameConstants.lunaStartX,
            y: GameConstants.groundHeight + GameConstants.lunaBodyHeight
        )
        luna.zPosition = 20
        addChild(luna)
    }

    private func setupHUD() {
        // Score label
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: size.width - 20, y: size.height - 45)
        scoreLabel.zPosition = 100
        scoreLabel.text = "0"
        addChild(scoreLabel)

        // Score shadow
        let shadow = SKLabelNode(fontNamed: "AvenirNext-Bold")
        shadow.fontSize = 24
        shadow.fontColor = SKColor(white: 0.0, alpha: 0.3)
        shadow.horizontalAlignmentMode = .right
        shadow.position = CGPoint(x: 1.5, y: -1.5)
        shadow.zPosition = -1
        shadow.text = "0"
        shadow.name = "scoreShadow"
        scoreLabel.addChild(shadow)

        // Bone icon next to score
        let boneIcon = SKLabelNode(text: "Score:")
        boneIcon.fontName = "AvenirNext-Medium"
        boneIcon.fontSize = 16
        boneIcon.fontColor = SKColor(white: 1.0, alpha: 0.8)
        boneIcon.horizontalAlignmentMode = .right
        boneIcon.position = CGPoint(x: size.width - 20, y: size.height - 25)
        boneIcon.zPosition = 100
        addChild(boneIcon)
    }

    private func setupObstacleManager() {
        obstacleManager = ObstacleManager(scene: self)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            transitionToGameOver()
            return
        }
        luna.jump()
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let deltaTime = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        lastUpdateTime = currentTime

        guard !isGameOver else { return }

        // Increase speed
        currentSpeed = min(
            currentSpeed + GameConstants.speedIncrement * CGFloat(deltaTime) * 60,
            GameConstants.maxSpeed
        )

        // Update systems
        background.update(speed: currentSpeed, deltaTime: deltaTime)
        obstacleManager.update(speed: currentSpeed, deltaTime: deltaTime)

        // Distance score
        distanceScore += currentSpeed * CGFloat(deltaTime) * 0.01
        updateScore()

        // Check if Luna landed
        checkGroundContact()
    }

    private func checkGroundContact() {
        guard let lunaBody = luna.physicsBody else { return }
        if lunaBody.velocity.dy > -5 && lunaBody.velocity.dy < 5
            && luna.position.y <= GameConstants.groundHeight + GameConstants.lunaBodyHeight + 5 {
            luna.land()
        }
    }

    private func updateScore() {
        let totalScore = score + Int(distanceScore)
        scoreLabel.text = "\(totalScore)"
        if let shadow = scoreLabel.childNode(withName: "scoreShadow") as? SKLabelNode {
            shadow.text = "\(totalScore)"
        }
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if collision == PhysicsCategory.luna | PhysicsCategory.obstacle {
            handleObstacleHit()
        } else if collision == PhysicsCategory.luna | PhysicsCategory.collectible {
            let collectibleNode = contact.bodyA.categoryBitMask == PhysicsCategory.collectible
                ? contact.bodyA.node : contact.bodyB.node
            handleCollectiblePickup(node: collectibleNode)
        }
    }

    private func handleObstacleHit() {
        guard !luna.isInvincible && !isGameOver else { return }
        isGameOver = true

        // Impact effect
        luna.physicsBody?.velocity = CGVector(dx: 0, dy: 0)

        let flash = SKSpriteNode(color: SKColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 0.4), size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 200
        addChild(flash)
        flash.run(SKAction.fadeOut(withDuration: 0.3)) {
            flash.removeFromParent()
        }

        // Shake
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 8, y: 0, duration: 0.03),
            SKAction.moveBy(x: -16, y: 0, duration: 0.03),
            SKAction.moveBy(x: 12, y: 0, duration: 0.03),
            SKAction.moveBy(x: -8, y: 0, duration: 0.03),
            SKAction.moveBy(x: 4, y: 0, duration: 0.03),
        ])
        scene?.run(shake)

        // Show "Game Over" text after short delay
        let wait = SKAction.wait(forDuration: 0.8)
        run(wait) { [weak self] in
            self?.showGameOverPrompt()
        }
    }

    private func showGameOverPrompt() {
        let tapLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tapLabel.text = "Tap to continue"
        tapLabel.fontSize = 20
        tapLabel.fontColor = .white
        tapLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        tapLabel.zPosition = 200
        tapLabel.alpha = 0
        addChild(tapLabel)

        let fadeInOut = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.5)
        ])
        tapLabel.run(SKAction.repeatForever(fadeInOut))
    }

    private func handleCollectiblePickup(node: SKNode?) {
        guard let node = node else { return }

        if let type = node.userData?["type"] as? CollectibleType {
            score += type.points
        } else {
            score += 1
        }

        luna.collectAnimation()

        // Sparkle effect
        let sparkle = SKEmitterNode()
        sparkle.particleTexture = nil
        sparkle.particleBirthRate = 30
        sparkle.numParticlesToEmit = 15
        sparkle.particleLifetime = 0.4
        sparkle.particleSpeed = 50
        sparkle.particleSpeedRange = 30
        sparkle.emissionAngleRange = .pi * 2
        sparkle.particleScale = 0.15
        sparkle.particleScaleSpeed = -0.3
        sparkle.particleAlpha = 1.0
        sparkle.particleAlphaSpeed = -2.5
        sparkle.particleColor = .yellow
        sparkle.particleColorBlendFactor = 1.0
        sparkle.position = node.position
        sparkle.zPosition = 50
        addChild(sparkle)
        sparkle.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ]))

        // Score popup
        let popup = SKLabelNode(fontNamed: "AvenirNext-Bold")
        if let type = node.userData?["type"] as? CollectibleType {
            popup.text = "+\(type.points)"
        } else {
            popup.text = "+1"
        }
        popup.fontSize = 18
        popup.fontColor = .yellow
        popup.position = node.position
        popup.zPosition = 50
        addChild(popup)
        let popupAction = SKAction.group([
            SKAction.moveBy(x: 0, y: 40, duration: 0.6),
            SKAction.fadeOut(withDuration: 0.6)
        ])
        popup.run(SKAction.sequence([popupAction, SKAction.removeFromParent()]))

        node.removeFromParent()
        updateScore()
    }

    // MARK: - Transitions

    private func transitionToGameOver() {
        let finalScore = score + Int(distanceScore)

        // Save high score
        let highScore = UserDefaults.standard.integer(forKey: "LunatikHighScore")
        if finalScore > highScore {
            UserDefaults.standard.set(finalScore, forKey: "LunatikHighScore")
        }

        let gameOverScene = GameOverScene(size: size)
        gameOverScene.scaleMode = scaleMode
        gameOverScene.finalScore = finalScore
        gameOverScene.highScore = max(finalScore, highScore)

        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameOverScene, transition: transition)
    }
}
