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

    // Swipe tracking
    private var touchStart: CGPoint?

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.35, green: 0.68, blue: 0.28, alpha: 1.0)

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        setupBackground()
        setupLuna()
        setupHUD()
        obstacleManager = ObstacleManager(scene: self)
    }

    // MARK: - Setup

    private func setupBackground() {
        background = ParallaxBackground(scene: self)
    }

    private func setupLuna() {
        luna = LunaCharacter(sceneWidth: size.width)
        luna.baseY = size.height * GameConstants.lunaYPosition
        luna.position = CGPoint(
            x: Lane.center.xPosition(sceneWidth: size.width),
            y: luna.baseY
        )
        luna.zPosition = 50
        addChild(luna)
    }

    private func setupHUD() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: size.width - 20, y: size.height - 55)
        scoreLabel.zPosition = 100
        scoreLabel.text = "0"
        addChild(scoreLabel)

        let scoreTitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        scoreTitle.text = "Score"
        scoreTitle.fontSize = 14
        scoreTitle.fontColor = SKColor(white: 1.0, alpha: 0.7)
        scoreTitle.horizontalAlignmentMode = .right
        scoreTitle.position = CGPoint(x: size.width - 20, y: size.height - 30)
        scoreTitle.zPosition = 100
        addChild(scoreTitle)

        // Shadow for readability
        let shadow = SKLabelNode(fontNamed: "AvenirNext-Bold")
        shadow.fontSize = 28
        shadow.fontColor = SKColor(white: 0.0, alpha: 0.35)
        shadow.horizontalAlignmentMode = .right
        shadow.position = CGPoint(x: 1.5, y: -1.5)
        shadow.zPosition = -1
        shadow.name = "scoreShadow"
        scoreLabel.addChild(shadow)
    }

    // MARK: - Touch / Swipe Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchStart = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let start = touchStart else { return }
        let end = touch.location(in: self)
        touchStart = nil

        if isGameOver {
            transitionToGameOver()
            return
        }

        let dx = end.x - start.x
        let dy = end.y - start.y
        let threshold: CGFloat = 30

        // Determine swipe direction
        if abs(dx) > abs(dy) {
            // Horizontal swipe
            if dx > threshold {
                luna.moveRight()
            } else if dx < -threshold {
                luna.moveLeft()
            }
        } else {
            // Vertical swipe
            if dy > threshold {
                luna.jump()
            } else if dy < -threshold {
                luna.slide()
            }
        }
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
        obstacleManager.update(
            speed: currentSpeed,
            deltaTime: deltaTime,
            lunaLane: luna.currentLane,
            lunaIsJumping: luna.isJumping
        )

        // Distance score
        distanceScore += currentSpeed * CGFloat(deltaTime) * 0.01
        updateScore()
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
            let obstacleNode = contact.bodyA.categoryBitMask == PhysicsCategory.obstacle
                ? contact.bodyA.node : contact.bodyB.node

            // If jumping over a jumpable obstacle, skip the hit
            if luna.isJumping,
               let jumpable = obstacleNode?.userData?["jumpable"] as? Bool,
               jumpable {
                return
            }

            // If sliding, dodge tall obstacles
            if luna.isSliding {
                return
            }

            handleObstacleHit()
        } else if collision == PhysicsCategory.luna | PhysicsCategory.collectible {
            let collectibleNode = contact.bodyA.categoryBitMask == PhysicsCategory.collectible
                ? contact.bodyA.node : contact.bodyB.node
            handleCollectiblePickup(node: collectibleNode)
        }
    }

    private func handleObstacleHit() {
        guard !isGameOver else { return }
        isGameOver = true

        // Flash
        let flash = SKSpriteNode(color: SKColor(red: 1.0, green: 0.2, blue: 0.15, alpha: 0.35), size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 200
        addChild(flash)
        flash.run(SKAction.fadeOut(withDuration: 0.3)) { flash.removeFromParent() }

        // Shake
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 8, y: 0, duration: 0.03),
            SKAction.moveBy(x: -16, y: 0, duration: 0.03),
            SKAction.moveBy(x: 12, y: 0, duration: 0.03),
            SKAction.moveBy(x: -8, y: 0, duration: 0.03),
            SKAction.moveBy(x: 4, y: 0, duration: 0.03),
        ])
        scene?.run(shake)

        luna.hitAnimation()

        run(SKAction.wait(forDuration: 0.8)) { [weak self] in
            self?.showGameOverPrompt()
        }
    }

    private func showGameOverPrompt() {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "Tap to continue"
        label.fontSize = 22
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.zPosition = 200
        addChild(label)

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.6),
            SKAction.fadeAlpha(to: 1.0, duration: 0.6)
        ])
        label.run(SKAction.repeatForever(pulse))
    }

    private func handleCollectiblePickup(node: SKNode?) {
        guard let node = node else { return }

        if let type = node.userData?["type"] as? CollectibleType {
            score += type.points
        } else {
            score += 1
        }

        luna.collectAnimation()

        // Score popup
        let popup = SKLabelNode(fontNamed: "AvenirNext-Bold")
        if let type = node.userData?["type"] as? CollectibleType {
            popup.text = "+\(type.points)"
        } else {
            popup.text = "+1"
        }
        popup.fontSize = 20
        popup.fontColor = .yellow
        popup.position = node.position
        popup.zPosition = 80
        addChild(popup)
        popup.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 50, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))

        node.removeFromParent()
        updateScore()
    }

    // MARK: - Transition

    private func transitionToGameOver() {
        let finalScore = score + Int(distanceScore)
        let highScore = UserDefaults.standard.integer(forKey: "LunatikHighScore")
        if finalScore > highScore {
            UserDefaults.standard.set(finalScore, forKey: "LunatikHighScore")
        }

        let gameOverScene = GameOverScene(size: size)
        gameOverScene.scaleMode = scaleMode
        gameOverScene.finalScore = finalScore
        gameOverScene.highScore = max(finalScore, highScore)

        view?.presentScene(gameOverScene, transition: SKTransition.fade(withDuration: 0.5))
    }
}
