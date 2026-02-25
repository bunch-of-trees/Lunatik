import SpriteKit

class LunaCharacter: SKNode {

    private var body: SKShapeNode!
    private var head: SKShapeNode!
    private var muzzle: SKShapeNode!
    private var leftEar: SKShapeNode!
    private var rightEar: SKShapeNode!
    private var leftEye: SKShapeNode!
    private var rightEye: SKShapeNode!
    private var leftPupil: SKShapeNode!
    private var rightPupil: SKShapeNode!
    private var chest: SKShapeNode!
    private var tail: SKShapeNode!
    private var frontLegTop: SKShapeNode!
    private var frontLegBottom: SKShapeNode!
    private var backLegTop: SKShapeNode!
    private var backLegBottom: SKShapeNode!

    var isOnGround = true
    var isInvincible = false

    override init() {
        super.init()
        buildLuna()
        setupPhysics()
        startRunningAnimation()
        startTailWag()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Build Luna's Sprite

    private func buildLuna() {
        let bw = GameConstants.lunaBodyWidth
        let bh = GameConstants.lunaBodyHeight

        // Body - black oval
        body = SKShapeNode(ellipseOf: CGSize(width: bw, height: bh))
        body.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0)
        body.lineWidth = 1.0
        body.position = CGPoint(x: 0, y: 0)
        addChild(body)

        // White chest patch
        chest = SKShapeNode(ellipseOf: CGSize(width: bw * 0.35, height: bh * 0.6))
        chest.fillColor = SKColor(red: 0.9, green: 0.9, blue: 0.92, alpha: 1.0)
        chest.strokeColor = .clear
        chest.position = CGPoint(x: bw * 0.2, y: -bh * 0.05)
        addChild(chest)

        // Gray speckle patches (Luna's merle coloring)
        let speckle1 = SKShapeNode(ellipseOf: CGSize(width: 8, height: 6))
        speckle1.fillColor = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 0.6)
        speckle1.strokeColor = .clear
        speckle1.position = CGPoint(x: -8, y: 5)
        addChild(speckle1)

        let speckle2 = SKShapeNode(ellipseOf: CGSize(width: 6, height: 5))
        speckle2.fillColor = SKColor(red: 0.45, green: 0.45, blue: 0.5, alpha: 0.5)
        speckle2.strokeColor = .clear
        speckle2.position = CGPoint(x: -14, y: -4)
        addChild(speckle2)

        // Head
        let headSize: CGFloat = bh * 0.75
        head = SKShapeNode(circleOfRadius: headSize / 2)
        head.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
        head.strokeColor = SKColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0)
        head.lineWidth = 1.0
        head.position = CGPoint(x: bw * 0.4, y: bh * 0.25)
        addChild(head)

        // White muzzle/face stripe (Luna has a white stripe)
        muzzle = SKShapeNode(ellipseOf: CGSize(width: headSize * 0.45, height: headSize * 0.55))
        muzzle.fillColor = SKColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1.0)
        muzzle.strokeColor = .clear
        muzzle.position = CGPoint(x: bw * 0.4 + headSize * 0.15, y: bh * 0.15)
        addChild(muzzle)

        // Nose
        let nose = SKShapeNode(ellipseOf: CGSize(width: 5, height: 4))
        nose.fillColor = SKColor(red: 0.2, green: 0.15, blue: 0.15, alpha: 1.0)
        nose.strokeColor = .clear
        nose.position = CGPoint(x: bw * 0.4 + headSize * 0.35, y: bh * 0.2)
        nose.zPosition = 2
        addChild(nose)

        // Eyes
        let eyeRadius: CGFloat = 4.0
        leftEye = SKShapeNode(circleOfRadius: eyeRadius)
        leftEye.fillColor = .white
        leftEye.strokeColor = .clear
        leftEye.position = CGPoint(x: bw * 0.4 + 3, y: bh * 0.35)
        leftEye.zPosition = 1
        addChild(leftEye)

        rightEye = SKShapeNode(circleOfRadius: eyeRadius)
        rightEye.fillColor = .white
        rightEye.strokeColor = .clear
        rightEye.position = CGPoint(x: bw * 0.4 + 12, y: bh * 0.35)
        rightEye.zPosition = 1
        addChild(rightEye)

        // Pupils (brown like Luna's eyes)
        let pupilRadius: CGFloat = 2.5
        leftPupil = SKShapeNode(circleOfRadius: pupilRadius)
        leftPupil.fillColor = SKColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: bw * 0.4 + 4.5, y: bh * 0.35)
        leftPupil.zPosition = 2
        addChild(leftPupil)

        rightPupil = SKShapeNode(circleOfRadius: pupilRadius)
        rightPupil.fillColor = SKColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        rightPupil.strokeColor = .clear
        rightPupil.position = CGPoint(x: bw * 0.4 + 13.5, y: bh * 0.35)
        rightPupil.zPosition = 2
        addChild(rightPupil)

        // Floppy ears
        let earPath = CGMutablePath()
        earPath.move(to: CGPoint(x: 0, y: 0))
        earPath.addLine(to: CGPoint(x: -8, y: 10))
        earPath.addLine(to: CGPoint(x: -12, y: -2))
        earPath.closeSubpath()

        leftEar = SKShapeNode(path: earPath)
        leftEar.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
        leftEar.strokeColor = .clear
        leftEar.position = CGPoint(x: bw * 0.35 - 4, y: bh * 0.5)
        addChild(leftEar)

        let rightEarPath = CGMutablePath()
        rightEarPath.move(to: CGPoint(x: 0, y: 0))
        rightEarPath.addLine(to: CGPoint(x: 6, y: 12))
        rightEarPath.addLine(to: CGPoint(x: 10, y: -1))
        rightEarPath.closeSubpath()

        rightEar = SKShapeNode(path: rightEarPath)
        rightEar.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
        rightEar.strokeColor = .clear
        rightEar.position = CGPoint(x: bw * 0.35 + 10, y: bh * 0.5)
        addChild(rightEar)

        // Tail
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: 0, y: 0))
        tailPath.addQuadCurve(to: CGPoint(x: -18, y: 18), control: CGPoint(x: -5, y: 15))
        tailPath.addLine(to: CGPoint(x: -15, y: 14))
        tailPath.addQuadCurve(to: CGPoint(x: 0, y: -3), control: CGPoint(x: -2, y: 11))
        tailPath.closeSubpath()

        tail = SKShapeNode(path: tailPath)
        tail.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
        tail.strokeColor = .clear
        tail.position = CGPoint(x: -bw * 0.45, y: bh * 0.1)
        addChild(tail)

        // White tail tip
        let tailTip = SKShapeNode(circleOfRadius: 3)
        tailTip.fillColor = SKColor(red: 0.9, green: 0.9, blue: 0.92, alpha: 1.0)
        tailTip.strokeColor = .clear
        tailTip.position = CGPoint(x: -18, y: 18)
        tail.addChild(tailTip)

        // Legs
        let legWidth: CGFloat = 7
        let legHeight: CGFloat = 16

        frontLegTop = SKShapeNode(rectOf: CGSize(width: legWidth, height: legHeight), cornerRadius: 2)
        frontLegTop.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
        frontLegTop.strokeColor = .clear
        frontLegTop.position = CGPoint(x: bw * 0.2, y: -bh * 0.42 - legHeight / 2)
        addChild(frontLegTop)

        frontLegBottom = SKShapeNode(rectOf: CGSize(width: legWidth, height: legHeight), cornerRadius: 2)
        frontLegBottom.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
        frontLegBottom.strokeColor = .clear
        frontLegBottom.position = CGPoint(x: bw * 0.1, y: -bh * 0.42 - legHeight / 2)
        addChild(frontLegBottom)

        backLegTop = SKShapeNode(rectOf: CGSize(width: legWidth, height: legHeight), cornerRadius: 2)
        backLegTop.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
        backLegTop.strokeColor = .clear
        backLegTop.position = CGPoint(x: -bw * 0.18, y: -bh * 0.42 - legHeight / 2)
        addChild(backLegTop)

        backLegBottom = SKShapeNode(rectOf: CGSize(width: legWidth, height: legHeight), cornerRadius: 2)
        backLegBottom.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
        backLegBottom.strokeColor = .clear
        backLegBottom.position = CGPoint(x: -bw * 0.28, y: -bh * 0.42 - legHeight / 2)
        addChild(backLegBottom)

        // White paw tips
        for leg in [frontLegTop, frontLegBottom, backLegTop, backLegBottom] {
            let paw = SKShapeNode(rectOf: CGSize(width: legWidth + 1, height: 4), cornerRadius: 1.5)
            paw.fillColor = SKColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1.0)
            paw.strokeColor = .clear
            paw.position = CGPoint(x: 0, y: -legHeight / 2 + 2)
            leg?.addChild(paw)
        }

        // Z-ordering
        body.zPosition = 10
        chest.zPosition = 11
        head.zPosition = 12
        muzzle.zPosition = 13
        tail.zPosition = 9
    }

    // MARK: - Physics

    private func setupPhysics() {
        let bodySize = CGSize(
            width: GameConstants.lunaBodyWidth * 0.8,
            height: GameConstants.lunaBodyHeight + 16
        )
        let physicsBody = SKPhysicsBody(rectangleOf: bodySize, center: CGPoint(x: 0, y: -4))
        physicsBody.categoryBitMask = PhysicsCategory.luna
        physicsBody.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.collectible
        physicsBody.collisionBitMask = PhysicsCategory.ground
        physicsBody.allowsRotation = false
        physicsBody.friction = 0.2
        physicsBody.restitution = 0.0
        self.physicsBody = physicsBody
    }

    // MARK: - Animations

    private func startRunningAnimation() {
        let legSwing: CGFloat = 12.0
        let duration: TimeInterval = 0.15

        let frontTopRun = SKAction.sequence([
            SKAction.moveBy(x: 0, y: legSwing, duration: duration),
            SKAction.moveBy(x: 0, y: -legSwing, duration: duration)
        ])
        frontLegTop.run(SKAction.repeatForever(frontTopRun), withKey: "run")

        let backTopRun = SKAction.sequence([
            SKAction.moveBy(x: 0, y: -legSwing, duration: duration),
            SKAction.moveBy(x: 0, y: legSwing, duration: duration)
        ])
        frontLegBottom.run(SKAction.repeatForever(backTopRun), withKey: "run")

        let backRun1 = SKAction.sequence([
            SKAction.moveBy(x: 0, y: legSwing, duration: duration),
            SKAction.moveBy(x: 0, y: -legSwing, duration: duration)
        ])
        backLegTop.run(SKAction.repeatForever(backRun1), withKey: "run")

        let backRun2 = SKAction.sequence([
            SKAction.moveBy(x: 0, y: -legSwing, duration: duration),
            SKAction.moveBy(x: 0, y: legSwing, duration: duration)
        ])
        backLegBottom.run(SKAction.repeatForever(backRun2), withKey: "run")

        // Subtle body bob
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 2, duration: duration),
            SKAction.moveBy(x: 0, y: -2, duration: duration)
        ])
        body.run(SKAction.repeatForever(bob), withKey: "bob")
    }

    private func startTailWag() {
        let wagAngle: CGFloat = 0.4
        let wag = SKAction.sequence([
            SKAction.rotate(toAngle: wagAngle, duration: 0.2),
            SKAction.rotate(toAngle: -wagAngle, duration: 0.2)
        ])
        tail.run(SKAction.repeatForever(wag), withKey: "wag")
    }

    // MARK: - Actions

    func jump() {
        guard isOnGround else { return }
        isOnGround = false
        physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        physicsBody?.applyImpulse(CGVector(dx: 0, dy: GameConstants.jumpImpulse))

        // Jump pose - tuck legs
        frontLegTop.removeAction(forKey: "run")
        frontLegBottom.removeAction(forKey: "run")
        backLegTop.removeAction(forKey: "run")
        backLegBottom.removeAction(forKey: "run")

        let tuck = SKAction.moveBy(x: 0, y: 6, duration: 0.1)
        frontLegTop.run(tuck)
        frontLegBottom.run(tuck)
        backLegTop.run(tuck)
        backLegBottom.run(tuck)
    }

    func land() {
        guard !isOnGround else { return }
        isOnGround = true
        startRunningAnimation()
    }

    func flashInvincible() {
        isInvincible = true
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        run(SKAction.repeat(blink, count: 10)) { [weak self] in
            self?.isInvincible = false
            self?.alpha = 1.0
        }
    }

    func collectAnimation() {
        let squash = SKAction.sequence([
            SKAction.scaleX(to: 1.2, y: 0.8, duration: 0.05),
            SKAction.scaleX(to: 0.9, y: 1.1, duration: 0.05),
            SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.05)
        ])
        run(squash)
    }
}
