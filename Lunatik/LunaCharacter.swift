import SpriteKit

class LunaCharacter: SKNode {

    private var sprite: SKSpriteNode!
    private var shadow: SKShapeNode!
    private(set) var currentLane: Lane = .center
    private(set) var isJumping = false
    private(set) var isSliding = false
    private var sceneWidth: CGFloat = 390

    var baseY: CGFloat = 0

    init(sceneWidth: CGFloat) {
        self.sceneWidth = sceneWidth
        super.init()
        buildSprite()
        buildShadow()
        setupPhysics()
        startRunBob()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Build

    private func buildSprite() {
        let texture = SKTexture(imageNamed: "LunaSprite")
        let aspectRatio = texture.size().width / texture.size().height
        let height = GameConstants.lunaSpriteHeight
        let width = height * aspectRatio

        sprite = SKSpriteNode(texture: texture, size: CGSize(width: width, height: height))
        sprite.zPosition = 1
        addChild(sprite)
    }

    private func buildShadow() {
        shadow = SKShapeNode(ellipseOf: CGSize(width: 55, height: 18))
        shadow.fillColor = SKColor(white: 0.0, alpha: 0.25)
        shadow.strokeColor = .clear
        shadow.zPosition = 0
        shadow.position = CGPoint(x: 0, y: -GameConstants.lunaSpriteHeight * 0.4)
        addChild(shadow)
    }

    private func setupPhysics() {
        let bodySize = CGSize(
            width: GameConstants.lunaSpriteHeight * 0.45,
            height: GameConstants.lunaSpriteHeight * 0.7
        )
        let body = SKPhysicsBody(rectangleOf: bodySize)
        body.isDynamic = true
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.luna
        body.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.collectible
        body.collisionBitMask = 0
        self.physicsBody = body
    }

    // MARK: - Run Animation

    private func startRunBob() {
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 0.12),
            SKAction.moveBy(x: 0, y: -3, duration: 0.12)
        ])
        sprite.run(SKAction.repeatForever(bob), withKey: "runBob")
    }

    // MARK: - Lane Switching

    func switchToLane(_ lane: Lane) {
        guard lane != currentLane else { return }
        currentLane = lane
        let targetX = lane.xPosition(sceneWidth: sceneWidth)
        removeAction(forKey: "laneSwitch")

        // Lean into the turn
        let leanAngle: CGFloat = targetX > position.x ? -0.12 : 0.12
        let lean = SKAction.rotate(toAngle: leanAngle, duration: GameConstants.laneSwitchDuration * 0.5)
        let straighten = SKAction.rotate(toAngle: 0, duration: GameConstants.laneSwitchDuration * 0.8)

        let move = SKAction.moveTo(x: targetX, duration: GameConstants.laneSwitchDuration)
        move.timingMode = .easeOut

        run(SKAction.group([move, SKAction.sequence([lean, straighten])]), withKey: "laneSwitch")
        SoundManager.shared.playSwoosh()
    }

    func moveLeft() {
        if let newLane = currentLane.moveLeft() {
            switchToLane(newLane)
        }
    }

    func moveRight() {
        if let newLane = currentLane.moveRight() {
            switchToLane(newLane)
        }
    }

    // MARK: - Jump

    func jump() {
        guard !isJumping && !isSliding else { return }
        isJumping = true

        sprite.removeAction(forKey: "runBob")

        let halfDur = GameConstants.jumpDuration / 2

        // Sprite goes up
        let jumpUp = SKAction.moveBy(x: 0, y: GameConstants.jumpHeight, duration: halfDur)
        jumpUp.timingMode = .easeOut
        let jumpDown = SKAction.moveBy(x: 0, y: -GameConstants.jumpHeight, duration: halfDur)
        jumpDown.timingMode = .easeIn

        // Squash and stretch on sprite
        let stretch = SKAction.scaleY(to: 1.12, duration: halfDur * 0.4)
        let normal1 = SKAction.scaleY(to: 1.0, duration: halfDur * 0.6)
        let squash = SKAction.group([
            SKAction.scaleX(to: 1.1, duration: 0.04),
            SKAction.scaleY(to: 0.88, duration: 0.04)
        ])
        let normal2 = SKAction.group([
            SKAction.scaleX(to: 1.0, duration: 0.06),
            SKAction.scaleY(to: 1.0, duration: 0.06)
        ])

        sprite.run(SKAction.sequence([
            SKAction.group([
                SKAction.sequence([jumpUp, jumpDown]),
                SKAction.sequence([stretch, normal1, squash, normal2])
            ]),
            SKAction.run { [weak self] in
                self?.isJumping = false
                self?.startRunBob()
            }
        ]), withKey: "jump")

        // Shadow shrinks and fades during jump
        let shadowShrink = SKAction.group([
            SKAction.scale(to: 0.5, duration: halfDur),
            SKAction.fadeAlpha(to: 0.1, duration: halfDur)
        ])
        let shadowGrow = SKAction.group([
            SKAction.scale(to: 1.0, duration: halfDur),
            SKAction.fadeAlpha(to: 0.25, duration: halfDur)
        ])
        shadow.run(SKAction.sequence([shadowShrink, shadowGrow]), withKey: "jumpShadow")

        SoundManager.shared.playJump()
    }

    // MARK: - Slide

    func slide() {
        guard !isJumping && !isSliding else { return }
        isSliding = true

        let squish = SKAction.group([
            SKAction.scaleY(to: 0.4, duration: 0.08),
            SKAction.scaleX(to: 1.3, duration: 0.08)
        ])
        let hold = SKAction.wait(forDuration: GameConstants.slideDuration - 0.18)
        let unsquish = SKAction.group([
            SKAction.scaleY(to: 1.0, duration: 0.1),
            SKAction.scaleX(to: 1.0, duration: 0.1)
        ])

        sprite.run(SKAction.sequence([squish, hold, unsquish]))

        // Shadow widens
        let widen = SKAction.scaleX(to: 1.4, duration: 0.08)
        let unwiden = SKAction.sequence([
            SKAction.wait(forDuration: GameConstants.slideDuration - 0.18),
            SKAction.scaleX(to: 1.0, duration: 0.1)
        ])
        shadow.run(SKAction.sequence([widen, unwiden]))

        run(SKAction.sequence([
            SKAction.wait(forDuration: GameConstants.slideDuration),
            SKAction.run { [weak self] in
                self?.isSliding = false
            }
        ]))

        SoundManager.shared.playSlide()
    }

    // MARK: - Effects

    func collectAnimation() {
        let pop = SKAction.sequence([
            SKAction.scale(to: 1.18, duration: 0.05),
            SKAction.scale(to: 0.94, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.05)
        ])
        sprite.run(pop)
    }

    func hitAnimation() {
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: 0.06),
            SKAction.fadeAlpha(to: 1.0, duration: 0.06)
        ])
        run(SKAction.repeat(blink, count: 6))
    }
}
