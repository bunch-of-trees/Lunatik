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
    private var hasTransitioned = false

    // Gesture recognizers (cleaned up on scene exit)
    private var addedGestureRecognizers: [UIGestureRecognizer] = []
    private var panHandled = false

    // Dust particles
    private var dustTimer: TimeInterval = 0

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.32, green: 0.65, blue: 0.25, alpha: 1.0)

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        // Performance: enable GPU optimizations
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 120

        setupBackground()
        setupLuna()
        setupHUD()
        obstacleManager = ObstacleManager(scene: self)
        setupGestures(in: view)
    }

    override func willMove(from view: SKView) {
        for gr in addedGestureRecognizers {
            view.removeGestureRecognizer(gr)
        }
        addedGestureRecognizers.removeAll()
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
        let hudBar = SKSpriteNode(
            color: SKColor(white: 0.0, alpha: 0.25),
            size: CGSize(width: size.width, height: 55)
        )
        hudBar.position = CGPoint(x: size.width / 2, y: size.height - 27)
        hudBar.zPosition = 99
        addChild(hudBar)

        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 30)
        scoreLabel.zPosition = 100
        scoreLabel.text = "0"
        addChild(scoreLabel)
    }

    // MARK: - Gesture Recognizers

    private func setupGestures(in view: SKView) {
        // Pan recognizer fires immediately on finger movement (continuous),
        // unlike UISwipeGestureRecognizer which waits to confirm the gesture.
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
        addedGestureRecognizers.append(pan)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.require(toFail: pan)
        view.addGestureRecognizer(tap)
        addedGestureRecognizers.append(tap)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            panHandled = false
            return
        }

        guard gesture.state == .changed, !panHandled, !isGameOver else { return }

        let translation = gesture.translation(in: view)
        let threshold: CGFloat = 8 // Very low - fires almost instantly

        guard abs(translation.x) > threshold || abs(translation.y) > threshold else { return }

        panHandled = true // One action per touch

        if abs(translation.x) > abs(translation.y) {
            // Horizontal: left/right lane change
            if translation.x > 0 { luna.moveRight() }
            else { luna.moveLeft() }
        } else {
            // Vertical: jump/slide (UIKit y is inverted from SpriteKit)
            if translation.y < 0 { luna.jump() }
            else { luna.slide() }
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard !isGameOver else { return }
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

        currentSpeed = min(
            currentSpeed + GameConstants.speedIncrement * CGFloat(deltaTime) * 60,
            GameConstants.maxSpeed
        )

        background.update(speed: currentSpeed, deltaTime: deltaTime)
        obstacleManager.update(speed: currentSpeed, deltaTime: deltaTime)

        distanceScore += currentSpeed * CGFloat(deltaTime) * 0.01
        updateScore()

        dustTimer += deltaTime
        if dustTimer > 0.1 {
            dustTimer = 0
            spawnDust()
        }
    }

    private func updateScore() {
        let totalScore = score + Int(distanceScore)
        scoreLabel.text = "\(totalScore)"
    }

    // MARK: - Particles

    private func spawnDust() {
        guard !luna.isJumping else { return }
        let sz = CGFloat.random(in: 4...7)
        let dust = SKSpriteNode(color: SKColor(white: 0.7, alpha: CGFloat.random(in: 0.12...0.25)),
                                size: CGSize(width: sz, height: sz))
        dust.position = CGPoint(
            x: luna.position.x + CGFloat.random(in: -12...12),
            y: luna.position.y - GameConstants.lunaSpriteHeight * 0.4
        )
        dust.zPosition = 45
        addChild(dust)
        dust.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: CGFloat.random(in: -8...8), y: CGFloat.random(in: 8...20), duration: 0.35),
                SKAction.fadeOut(withDuration: 0.35)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if collision == PhysicsCategory.luna | PhysicsCategory.obstacle {
            let obstacleNode = contact.bodyA.categoryBitMask == PhysicsCategory.obstacle
                ? contact.bodyA.node : contact.bodyB.node

            if luna.isJumping,
               let jumpable = obstacleNode?.userData?["jumpable"] as? Bool,
               jumpable {
                return
            }

            if luna.isSliding { return }

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

        SoundManager.shared.playHit()

        // Red flash
        let flash = SKSpriteNode(color: SKColor(red: 1.0, green: 0.15, blue: 0.1, alpha: 0.4), size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 200
        addChild(flash)
        flash.run(SKAction.fadeOut(withDuration: 0.4)) { flash.removeFromParent() }

        // Camera shake
        var shakeActions: [SKAction] = []
        for _ in 0..<5 {
            let dx = CGFloat.random(in: -10...10)
            let dy = CGFloat.random(in: -10...10)
            shakeActions.append(SKAction.moveBy(x: dx, y: dy, duration: 0.025))
            shakeActions.append(SKAction.moveBy(x: -dx, y: -dy, duration: 0.025))
        }
        scene?.run(SKAction.sequence(shakeActions))

        luna.hitAnimation()

        // Game over sound then auto-transition
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.35),
            SKAction.run { SoundManager.shared.playGameOver() },
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in self?.transitionToGameOver() }
        ]))
    }

    private func handleCollectiblePickup(node: SKNode?) {
        guard let node = node else { return }

        if let type = node.userData?["type"] as? CollectibleType {
            score += type.points
        } else {
            score += 1
        }

        SoundManager.shared.playCollect()
        luna.collectAnimation()

        // Sparkle burst
        for _ in 0..<5 {
            let sz = CGFloat.random(in: 4...7)
            let spark = SKSpriteNode(
                color: SKColor(red: 1, green: 1, blue: CGFloat.random(in: 0.3...0.8), alpha: 1),
                size: CGSize(width: sz, height: sz))
            spark.position = node.position
            spark.zPosition = 80
            addChild(spark)

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist = CGFloat.random(in: 20...50)
            spark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.scale(to: 0.1, duration: 0.3)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Score popup
        let popup = SKLabelNode(fontNamed: "AvenirNext-Bold")
        if let type = node.userData?["type"] as? CollectibleType {
            popup.text = "+\(type.points)"
        } else {
            popup.text = "+1"
        }
        popup.fontSize = 22
        popup.fontColor = .yellow
        popup.position = node.position
        popup.zPosition = 80
        addChild(popup)
        popup.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 55, duration: 0.45),
                SKAction.fadeOut(withDuration: 0.45)
            ]),
            SKAction.removeFromParent()
        ]))

        node.removeFromParent()
        updateScore()
    }

    // MARK: - Transition

    private func transitionToGameOver() {
        guard !hasTransitioned else { return }
        hasTransitioned = true
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
