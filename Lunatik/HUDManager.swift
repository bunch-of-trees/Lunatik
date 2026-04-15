import SpriteKit

class HUDManager {

    private weak var scene: SKScene?

    private var scoreLabel: SKLabelNode!
    private var comboLabel: SKLabelNode!
    private var powerUpIndicator: SKLabelNode!
    var pauseButton: SKLabelNode!

    init(scene: SKScene) {
        self.scene = scene
        setupHUD()
    }

    private func setupHUD() {
        guard let scene = scene else { return }
        let w = scene.size.width
        let h = scene.size.height

        let hudBar = SKSpriteNode(
            color: SKColor(white: 0.0, alpha: 0.25),
            size: CGSize(width: w, height: 55)
        )
        hudBar.position = CGPoint(x: w / 2, y: h - 27)
        hudBar.zPosition = 99
        scene.addChild(hudBar)

        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: w / 2, y: h - 30)
        scoreLabel.zPosition = 100
        scoreLabel.text = "0"
        scene.addChild(scoreLabel)

        comboLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        comboLabel.fontSize = 22
        comboLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.1, alpha: 1.0)
        comboLabel.horizontalAlignmentMode = .left
        comboLabel.verticalAlignmentMode = .center
        comboLabel.position = CGPoint(x: w / 2 + 60, y: h - 30)
        comboLabel.zPosition = 100
        comboLabel.alpha = 0
        scene.addChild(comboLabel)

        powerUpIndicator = SKLabelNode(fontNamed: "AvenirNext-Bold")
        powerUpIndicator.fontSize = 18
        powerUpIndicator.fontColor = SKColor(red: 0.4, green: 0.9, blue: 1.0, alpha: 1.0)
        powerUpIndicator.horizontalAlignmentMode = .right
        powerUpIndicator.verticalAlignmentMode = .center
        powerUpIndicator.position = CGPoint(x: w - 16, y: h - 30)
        powerUpIndicator.zPosition = 100
        powerUpIndicator.alpha = 0
        scene.addChild(powerUpIndicator)

        pauseButton = SKLabelNode(fontNamed: "AvenirNext-Bold")
        pauseButton.text = "| |"
        pauseButton.fontSize = 20
        pauseButton.fontColor = SKColor(white: 1, alpha: 0.7)
        pauseButton.horizontalAlignmentMode = .center
        pauseButton.verticalAlignmentMode = .center
        pauseButton.position = CGPoint(x: 36, y: h - 30)
        pauseButton.zPosition = 100
        scene.addChild(pauseButton)
    }

    func updateScore(_ totalScore: Int, pop: Bool = false) {
        scoreLabel.text = "\(totalScore)"
        if pop {
            scoreLabel.removeAction(forKey: "scorePop")
            scoreLabel.setScale(1.0)
            scoreLabel.run(SKAction.sequence([
                SKAction.scale(to: 1.12, duration: 0.06),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]), withKey: "scorePop")
        }
    }

    func updateCombo(_ count: Int) {
        if count > 1 {
            comboLabel.text = "x\(count)"
            comboLabel.alpha = 1.0
            comboLabel.removeAction(forKey: "comboPulse")
            comboLabel.setScale(1.0)
            comboLabel.run(SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.06),
                SKAction.scale(to: 1.0, duration: 0.08)
            ]), withKey: "comboPulse")
        }
    }

    func hideCombo() {
        comboLabel.run(SKAction.fadeOut(withDuration: 0.2))
    }

    func updatePowerUpIndicator(shield: Bool, magnetTimer: TimeInterval, doubleScoreTimer: TimeInterval) {
        var parts: [String] = []
        if shield { parts.append("SHIELD") }
        if magnetTimer > 0 { parts.append("MAGNET \(Int(magnetTimer))s") }
        if doubleScoreTimer > 0 { parts.append("2X \(Int(doubleScoreTimer))s") }

        if parts.isEmpty {
            powerUpIndicator.run(SKAction.fadeOut(withDuration: 0.2))
        } else {
            powerUpIndicator.text = parts.joined(separator: " | ")
            powerUpIndicator.alpha = 1.0
        }
    }

    func showPause() {
        guard let scene = scene else { return }
        let overlay = SKSpriteNode(color: SKColor(white: 0, alpha: 0.6), size: scene.size)
        overlay.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        overlay.zPosition = 150
        overlay.name = "pauseOverlay"
        overlay.alpha = 0
        scene.addChild(overlay)
        overlay.run(SKAction.fadeIn(withDuration: 0.15))

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "PAUSED"
        label.fontSize = 48
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 20)
        overlay.addChild(label)

        let hint = SKLabelNode(fontNamed: "AvenirNext-Medium")
        hint.text = "Tap to Resume"
        hint.fontSize = 22
        hint.fontColor = SKColor(white: 1, alpha: 0.6)
        hint.verticalAlignmentMode = .center
        hint.position = CGPoint(x: 0, y: -30)
        overlay.addChild(hint)

        pauseButton.text = "\u{25B6}"
    }

    func hidePause() {
        scene?.enumerateChildNodes(withName: "pauseOverlay") { node, _ in
            node.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.15),
                SKAction.removeFromParent()
            ]))
        }
        pauseButton.text = "| |"
    }
}
