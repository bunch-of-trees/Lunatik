import SpriteKit
import UIKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    private var luna: LunaCharacter!
    private var background: ParallaxBackground!
    private var obstacleManager: ObstacleManager!
    private var hud: HUDManager!
    private var effects: EffectsManager!

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

    // Haptics
    private let hapticLight = UIImpactFeedbackGenerator(style: .light)
    private let hapticHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let hapticSoft = UIImpactFeedbackGenerator(style: .soft)

    private func haptic(_ generator: UIImpactFeedbackGenerator, intensity: CGFloat = 1.0) {
        guard GameSettings.shared.hapticsEnabled else { return }
        generator.impactOccurred(intensity: intensity)
    }

    // Combo system
    private var comboCount: Int = 0
    private var lastCollectTime: TimeInterval = 0

    // Speed lines
    private var speedLineTimer: TimeInterval = 0

    // Pause
    private var isGamePaused = false

    // Countdown
    private var isCountingDown = true

    // Power-ups
    private var hasShield = false
    private var shieldNode: SKShapeNode?
    private var magnetActive = false
    private var magnetTimer: TimeInterval = 0
    private var doubleScoreActive = false
    private var doubleScoreTimer: TimeInterval = 0

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.32, green: 0.65, blue: 0.25, alpha: 1.0)

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        // Performance: enable GPU optimizations
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 120

        MissionManager.shared.startRun()

        background = ParallaxBackground(scene: self)
        setupLuna()
        hud = HUDManager(scene: self)
        effects = EffectsManager(scene: self)
        obstacleManager = ObstacleManager(scene: self)
        setupGestures(in: view)

        // Start zone 0 music and hook zone changes for crossfade
        SoundManager.shared.startMusic(zone: 0)
        background.onZoneChange = { zone in
            SoundManager.shared.crossfadeToZone(zone)
        }

        startCountdown()
    }

    override func willMove(from view: SKView) {
        for gr in addedGestureRecognizers {
            view.removeGestureRecognizer(gr)
        }
        addedGestureRecognizers.removeAll()
    }

    // MARK: - Setup

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

    // MARK: - Gesture Recognizers

    private func setupGestures(in view: SKView) {
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
        if gesture.state == .ended || gesture.state == .cancelled {
            panHandled = false
            return
        }

        guard gesture.state == .changed, !panHandled, !isGameOver, !isGamePaused, !isCountingDown else { return }

        let translation = gesture.translation(in: view)
        let threshold: CGFloat = 8

        guard abs(translation.x) > threshold || abs(translation.y) > threshold else { return }

        panHandled = true

        if abs(translation.x) > abs(translation.y) {
            haptic(hapticLight, intensity: 0.5)
            if translation.x > 0 { luna.moveRight() }
            else { luna.moveLeft() }
        } else {
            haptic(hapticLight)
            if translation.y < 0 { luna.jump() }
            else { luna.slide() }
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        if isGamePaused {
            togglePause()
            return
        }

        guard !isGameOver, !isCountingDown else { return }

        let location = gesture.location(in: view)
        let sceneLocation = convertPoint(fromView: location)
        let pauseArea = CGRect(x: 0, y: size.height - 60, width: 72, height: 60)
        if pauseArea.contains(sceneLocation) {
            togglePause()
            return
        }

        haptic(hapticLight)
        luna.jump()
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let deltaTime = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        lastUpdateTime = currentTime

        guard !isGameOver, !isGamePaused, !isCountingDown else { return }

        currentSpeed = min(
            currentSpeed + GameConstants.speedIncrement * CGFloat(deltaTime) * 60,
            GameConstants.maxSpeed
        )

        background.update(speed: currentSpeed, deltaTime: deltaTime)
        obstacleManager.update(speed: currentSpeed, deltaTime: deltaTime)

        distanceScore += currentSpeed * CGFloat(deltaTime) * 0.01
        hud.updateScore(score + Int(distanceScore))
        background.updateEnvironment(distanceScore: distanceScore)
        MissionManager.shared.reportDistance(Int(distanceScore))

        dustTimer += deltaTime
        if dustTimer > 0.1 {
            dustTimer = 0
            effects.spawnDust(at: luna.position, lunaIsJumping: luna.isJumping)
        }

        // Combo timeout
        if comboCount > 0 && lastUpdateTime - lastCollectTime > 1.5 {
            comboCount = 0
            hud.hideCombo()
        }

        // Power-up timers
        if magnetActive {
            magnetTimer -= deltaTime
            if magnetTimer <= 0 {
                magnetActive = false
            } else {
                applyMagnetEffect()
            }
        }
        if doubleScoreActive {
            doubleScoreTimer -= deltaTime
            if doubleScoreTimer <= 0 {
                doubleScoreActive = false
            }
        }
        hud.updatePowerUpIndicator(
            shield: hasShield,
            magnetTimer: magnetActive ? magnetTimer : 0,
            doubleScoreTimer: doubleScoreActive ? doubleScoreTimer : 0
        )

        // Speed lines at high speed
        if currentSpeed > 550 {
            speedLineTimer += deltaTime
            let rate = 0.08 - Double(currentSpeed - 550) / Double(GameConstants.maxSpeed - 550) * 0.05
            if speedLineTimer > rate {
                speedLineTimer = 0
                effects.spawnSpeedLine()
            }
        }
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
                if obstacleNode?.userData?["nearMiss"] == nil {
                    obstacleNode?.userData?["nearMiss"] = true
                    triggerNearMiss(at: obstacleNode?.position ?? luna.position)
                }
                return
            }

            if luna.isSliding {
                if obstacleNode?.userData?["nearMiss"] == nil {
                    obstacleNode?.userData?["nearMiss"] = true
                    triggerNearMiss(at: obstacleNode?.position ?? luna.position, wasSlide: true)
                }
                return
            }

            if hasShield {
                hasShield = false
                shieldNode?.removeFromParent()
                shieldNode = nil
                haptic(hapticLight)
                effects.shieldBreak(at: luna.position)
                hud.updatePowerUpIndicator(shield: false, magnetTimer: magnetActive ? magnetTimer : 0, doubleScoreTimer: doubleScoreActive ? doubleScoreTimer : 0)
                return
            }

            handleObstacleHit()

        } else if collision == PhysicsCategory.luna | PhysicsCategory.collectible {
            let collectibleNode = contact.bodyA.categoryBitMask == PhysicsCategory.collectible
                ? contact.bodyA.node : contact.bodyB.node

            if collectibleNode?.name == "powerUp",
               let powerUpType = collectibleNode?.userData?["powerUpType"] as? PowerUpType {
                handlePowerUpPickup(type: powerUpType, node: collectibleNode)
                return
            }

            handleCollectiblePickup(node: collectibleNode)
        }
    }

    private func handleObstacleHit() {
        guard !isGameOver else { return }
        isGameOver = true

        haptic(hapticHeavy)
        SoundManager.shared.playHit()
        SoundManager.shared.fadeOutMusic(duration: 1.5)

        self.speed = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            self.speed = 0.3
            self.effects.deathSequence(sceneSize: self.size)
            self.luna.hitAnimation()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                self.speed = 1.0
                SoundManager.shared.playGameOver()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    self?.transitionToGameOver()
                }
            }
        }
    }

    private func handleCollectiblePickup(node: SKNode?) {
        guard let node = node else { return }

        if lastUpdateTime - lastCollectTime < 1.5 && lastCollectTime > 0 {
            comboCount = min(comboCount + 1, 10)
        } else {
            comboCount = 1
        }
        lastCollectTime = lastUpdateTime

        let comboMult = max(1, comboCount)
        let scoreMult = doubleScoreActive ? 2 : 1
        if let type = node.userData?["type"] as? CollectibleType {
            score += type.points * comboMult * scoreMult
            MissionManager.shared.reportCollect(type: type)
        } else {
            score += 1 * comboMult * scoreMult
        }
        MissionManager.shared.reportCombo(comboCount)

        hud.updateCombo(comboCount)

        haptic(hapticSoft)
        SoundManager.shared.playCollect()
        luna.collectAnimation()

        effects.sparkleBurst(at: node.position)

        if let type = node.userData?["type"] as? CollectibleType {
            effects.scorePopup(text: "+\(type.points)", at: node.position)
        } else {
            effects.scorePopup(text: "+1", at: node.position)
        }

        node.removeFromParent()
        hud.updateScore(score + Int(distanceScore), pop: true)
    }

    // MARK: - Near Miss

    private func triggerNearMiss(at position: CGPoint, wasSlide: Bool = false) {
        score += 3
        haptic(hapticLight, intensity: 0.7)
        MissionManager.shared.reportNearMiss()
        if wasSlide { MissionManager.shared.reportSlideDodge() }

        effects.nearMissPopup(at: position)
        hud.updateScore(score + Int(distanceScore), pop: true)
    }

    // MARK: - Power-Ups

    private func handlePowerUpPickup(type: PowerUpType, node: SKNode?) {
        guard let node = node else { return }
        haptic(hapticSoft)
        SoundManager.shared.playCollect()
        MissionManager.shared.reportPowerUp()

        switch type {
        case .magnet:
            magnetActive = true
            magnetTimer = type.duration
        case .shield:
            hasShield = true
            attachShieldVisual()
        case .doubleScore:
            doubleScoreActive = true
            doubleScoreTimer = type.duration
        }

        hud.updatePowerUpIndicator(shield: hasShield, magnetTimer: magnetActive ? magnetTimer : 0, doubleScoreTimer: doubleScoreActive ? doubleScoreTimer : 0)

        let popupText: String
        switch type {
        case .magnet: popupText = "MAGNET!"
        case .shield: popupText = "SHIELD!"
        case .doubleScore: popupText = "2X SCORE!"
        }
        effects.powerUpPopup(text: popupText, at: node.position)

        node.removeFromParent()
        hud.updateScore(score + Int(distanceScore), pop: true)
    }

    private func applyMagnetEffect() {
        let magnetRange = GameConstants.magnetRadius
        enumerateChildNodes(withName: "collectible") { [weak self] node, _ in
            guard let self = self else { return }
            let dx = self.luna.position.x - node.position.x
            let dy = self.luna.position.y - node.position.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist < magnetRange && dist > 5 {
                let pullStrength: CGFloat = 4.0
                node.position.x += dx / dist * pullStrength
                node.position.y += dy / dist * pullStrength
            }
        }
    }

    private func attachShieldVisual() {
        shieldNode?.removeFromParent()
        let shield = SKShapeNode(circleOfRadius: 40)
        shield.fillColor = SKColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.15)
        shield.strokeColor = SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 0.5)
        shield.lineWidth = 2.5
        shield.zPosition = 55
        luna.addChild(shield)
        shieldNode = shield

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.08, duration: 0.6),
            SKAction.fadeAlpha(to: 0.2, duration: 0.6)
        ])
        shield.run(SKAction.repeatForever(pulse))
    }

    // MARK: - Countdown

    private func startCountdown() {
        isCountingDown = true
        let labels = ["3", "2", "1", "GO!"]

        for (i, text) in labels.enumerated() {
            let delay = TimeInterval(i) * 0.7
            run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
                    label.text = text
                    label.fontSize = text == "GO!" ? 64 : 72
                    label.fontColor = text == "GO!"
                        ? SKColor(red: 0.3, green: 1.0, blue: 0.4, alpha: 1.0)
                        : .white
                    label.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
                    label.zPosition = 200
                    label.setScale(0.3)
                    label.alpha = 0
                    self.addChild(label)

                    label.run(SKAction.sequence([
                        SKAction.group([
                            SKAction.scale(to: 1.0, duration: 0.25),
                            SKAction.fadeIn(withDuration: 0.15)
                        ]),
                        SKAction.wait(forDuration: 0.25),
                        SKAction.group([
                            SKAction.scale(to: 1.5, duration: 0.2),
                            SKAction.fadeOut(withDuration: 0.2)
                        ]),
                        SKAction.removeFromParent()
                    ]))
                }
            ]))
        }

        run(SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval(labels.count) * 0.7),
            SKAction.run { [weak self] in
                self?.isCountingDown = false
            }
        ]))
    }

    // MARK: - Pause

    private func togglePause() {
        isGamePaused.toggle()
        if isGamePaused {
            hud.showPause()
        } else {
            hud.hidePause()
        }
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

        let completedMissions = MissionManager.shared.endRun(finalScore: finalScore)

        let gameOverScene = GameOverScene(size: size)
        gameOverScene.scaleMode = scaleMode
        gameOverScene.finalScore = finalScore
        gameOverScene.highScore = max(finalScore, highScore)
        gameOverScene.completedMissions = completedMissions
        gameOverScene.bonesEarned = MissionManager.shared.runBonesEarned

        view?.presentScene(gameOverScene, transition: SKTransition.fade(with: .black, duration: 0.5))
    }
}
