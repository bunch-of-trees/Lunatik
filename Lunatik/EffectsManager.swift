import SpriteKit

class EffectsManager {

    private weak var scene: SKScene?

    init(scene: SKScene) {
        self.scene = scene
    }

    // MARK: - Dust

    func spawnDust(at position: CGPoint, lunaIsJumping: Bool) {
        guard !lunaIsJumping, let scene = scene else { return }
        let sz = CGFloat.random(in: 4...7)
        let dust = SKSpriteNode(color: SKColor(white: 0.7, alpha: CGFloat.random(in: 0.12...0.25)),
                                size: CGSize(width: sz, height: sz))
        dust.position = CGPoint(
            x: position.x + CGFloat.random(in: -12...12),
            y: position.y - GameConstants.lunaSpriteHeight * 0.4
        )
        dust.zPosition = 45
        scene.addChild(dust)
        dust.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: CGFloat.random(in: -8...8), y: CGFloat.random(in: 8...20), duration: 0.35),
                SKAction.fadeOut(withDuration: 0.35)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Speed Lines

    func spawnSpeedLine() {
        guard let scene = scene else { return }
        let lineH = CGFloat.random(in: 40...80)
        let line = SKSpriteNode(
            color: SKColor(white: 1.0, alpha: CGFloat.random(in: 0.06...0.15)),
            size: CGSize(width: 2, height: lineH))
        line.position = CGPoint(
            x: CGFloat.random(in: 30...(scene.size.width - 30)),
            y: scene.size.height + lineH)
        line.zPosition = 30
        scene.addChild(line)

        line.run(SKAction.sequence([
            SKAction.moveBy(x: 0, y: -(scene.size.height + lineH * 2), duration: 0.25),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Sparkle Burst (collectible pickup)

    func sparkleBurst(at position: CGPoint) {
        guard let scene = scene else { return }
        for _ in 0..<5 {
            let sz = CGFloat.random(in: 4...7)
            let spark = SKSpriteNode(
                color: SKColor(red: 1, green: 1, blue: CGFloat.random(in: 0.3...0.8), alpha: 1),
                size: CGSize(width: sz, height: sz))
            spark.position = position
            spark.zPosition = 80
            scene.addChild(spark)

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
    }

    // MARK: - Score / Text Popups

    func scorePopup(text: String, at position: CGPoint) {
        guard let scene = scene else { return }
        let popup = SKLabelNode(fontNamed: "AvenirNext-Bold")
        popup.text = text
        popup.fontSize = 22
        popup.fontColor = .yellow
        popup.position = position
        popup.zPosition = 80
        scene.addChild(popup)
        popup.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 55, duration: 0.45),
                SKAction.fadeOut(withDuration: 0.45)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    func nearMissPopup(at position: CGPoint) {
        guard let scene = scene else { return }
        let popup = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        popup.text = "CLOSE! +3"
        popup.fontSize = 20
        popup.fontColor = SKColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 1.0)
        popup.position = CGPoint(x: position.x, y: position.y + 30)
        popup.zPosition = 80
        scene.addChild(popup)
        popup.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 45, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.scale(to: 1.3, duration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    func powerUpPopup(text: String, at position: CGPoint) {
        guard let scene = scene else { return }
        // Flash
        let flash = SKSpriteNode(
            color: SKColor(white: 1.0, alpha: 0.5),
            size: CGSize(width: 50, height: 50))
        flash.position = position
        flash.zPosition = 80
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.5, duration: 0.25),
                SKAction.fadeOut(withDuration: 0.25)
            ]),
            SKAction.removeFromParent()
        ]))

        // Text
        let popup = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        popup.text = text
        popup.fontSize = 24
        popup.fontColor = SKColor(red: 0.4, green: 1.0, blue: 1.0, alpha: 1.0)
        popup.position = CGPoint(x: position.x, y: position.y + 20)
        popup.zPosition = 85
        scene.addChild(popup)
        popup.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 60, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6),
                SKAction.scale(to: 1.4, duration: 0.6)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Shield Break

    func shieldBreak(at position: CGPoint) {
        guard let scene = scene else { return }
        for _ in 0..<8 {
            let shard = SKSpriteNode(
                color: SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 0.8),
                size: CGSize(width: 6, height: 12))
            shard.position = position
            shard.zPosition = 80
            scene.addChild(shard)
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist = CGFloat.random(in: 30...60)
            shard.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.35),
                    SKAction.fadeOut(withDuration: 0.35),
                    SKAction.rotate(byAngle: CGFloat.random(in: -3...3), duration: 0.35)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Death Effects

    func deathSequence(sceneSize: CGSize) {
        guard let scene = scene else { return }
        // Red flash
        let flash = SKSpriteNode(color: SKColor(red: 1.0, green: 0.15, blue: 0.1, alpha: 0.4), size: sceneSize)
        flash.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        flash.zPosition = 200
        scene.addChild(flash)
        flash.run(SKAction.fadeOut(withDuration: 0.4)) { flash.removeFromParent() }

        // Camera shake
        var shakeActions: [SKAction] = []
        for _ in 0..<5 {
            let dx = CGFloat.random(in: -10...10)
            let dy = CGFloat.random(in: -10...10)
            shakeActions.append(SKAction.moveBy(x: dx, y: dy, duration: 0.025))
            shakeActions.append(SKAction.moveBy(x: -dx, y: -dy, duration: 0.025))
        }
        scene.run(SKAction.sequence(shakeActions))
    }
}
