import SpriteKit

class LunaCharacter: SKNode {

    private var sprite: SKSpriteNode!
    private(set) var currentLane: Lane = .center
    private(set) var isJumping = false
    private(set) var isSliding = false
    private var sceneWidth: CGFloat = 390

    var baseY: CGFloat = 0

    init(sceneWidth: CGFloat) {
        self.sceneWidth = sceneWidth
        super.init()
        buildSprite()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildSprite() {
        let texture = SKTexture(imageNamed: "LunaSprite")
        let aspectRatio = texture.size().width / texture.size().height
        let height = GameConstants.lunaSpriteHeight
        let width = height * aspectRatio

        sprite = SKSpriteNode(texture: texture, size: CGSize(width: width, height: height))
        addChild(sprite)
    }

    private func setupPhysics() {
        let bodySize = CGSize(
            width: GameConstants.lunaSpriteHeight * 0.5,
            height: GameConstants.lunaSpriteHeight * 0.8
        )
        let body = SKPhysicsBody(rectangleOf: bodySize)
        body.isDynamic = true
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.luna
        body.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.collectible
        body.collisionBitMask = 0
        self.physicsBody = body
    }

    // MARK: - Lane Switching

    func switchToLane(_ lane: Lane) {
        guard !isSliding else { return }
        currentLane = lane
        let targetX = lane.xPosition(sceneWidth: sceneWidth)
        let move = SKAction.moveTo(x: targetX, duration: GameConstants.laneSwitchDuration)
        move.timingMode = .easeInEaseOut
        run(move, withKey: "laneSwitch")
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

        let jumpUp = SKAction.moveBy(x: 0, y: GameConstants.jumpHeight, duration: GameConstants.jumpDuration / 2)
        jumpUp.timingMode = .easeOut
        let jumpDown = SKAction.moveBy(x: 0, y: -GameConstants.jumpHeight, duration: GameConstants.jumpDuration / 2)
        jumpDown.timingMode = .easeIn

        // Squash and stretch
        let stretch = SKAction.scaleY(to: 1.15, duration: GameConstants.jumpDuration / 4)
        let normal = SKAction.scaleY(to: 1.0, duration: GameConstants.jumpDuration / 4)
        let squash = SKAction.group([
            SKAction.scaleX(to: 1.1, duration: 0.05),
            SKAction.scaleY(to: 0.85, duration: 0.05)
        ])
        let unsquash = SKAction.group([
            SKAction.scaleX(to: 1.0, duration: 0.05),
            SKAction.scaleY(to: 1.0, duration: 0.05)
        ])

        let jumpSequence = SKAction.sequence([jumpUp, jumpDown])
        let spriteSequence = SKAction.sequence([stretch, normal, squash, unsquash])

        run(jumpSequence, withKey: "jump")
        sprite.run(spriteSequence)

        run(SKAction.sequence([
            SKAction.wait(forDuration: GameConstants.jumpDuration),
            SKAction.run { [weak self] in
                self?.isJumping = false
            }
        ]))
    }

    // MARK: - Slide

    func slide() {
        guard !isJumping && !isSliding else { return }
        isSliding = true

        let squish = SKAction.group([
            SKAction.scaleY(to: 0.45, duration: 0.1),
            SKAction.scaleX(to: 1.3, duration: 0.1)
        ])
        let hold = SKAction.wait(forDuration: GameConstants.slideDuration - 0.2)
        let unsquish = SKAction.group([
            SKAction.scaleY(to: 1.0, duration: 0.1),
            SKAction.scaleX(to: 1.0, duration: 0.1)
        ])

        sprite.run(SKAction.sequence([squish, hold, unsquish]))

        run(SKAction.sequence([
            SKAction.wait(forDuration: GameConstants.slideDuration),
            SKAction.run { [weak self] in
                self?.isSliding = false
            }
        ]))
    }

    // MARK: - Collect Animation

    func collectAnimation() {
        let pop = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.06),
            SKAction.scale(to: 0.95, duration: 0.06),
            SKAction.scale(to: 1.0, duration: 0.06)
        ])
        sprite.run(pop)
    }

    // MARK: - Hit Animation

    func hitAnimation() {
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.08),
            SKAction.fadeAlpha(to: 1.0, duration: 0.08)
        ])
        run(SKAction.repeat(blink, count: 5))
    }
}
