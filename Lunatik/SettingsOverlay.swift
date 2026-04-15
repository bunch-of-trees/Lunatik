import SpriteKit

class SettingsOverlay {

    private weak var scene: SKScene?
    private var overlayNode: SKNode?

    init(scene: SKScene) {
        self.scene = scene
    }

    var isVisible: Bool { overlayNode != nil }

    func show() {
        guard let scene = scene, overlayNode == nil else { return }
        let w = scene.size.width
        let h = scene.size.height

        let container = SKNode()
        container.name = "settingsOverlay"
        container.zPosition = 300

        // Dimmed background
        let bg = SKSpriteNode(color: SKColor(white: 0, alpha: 0.7), size: scene.size)
        bg.position = CGPoint(x: w / 2, y: h / 2)
        container.addChild(bg)

        // Panel
        let panelW: CGFloat = w * 0.75
        let panelH: CGFloat = 260
        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 16)
        panel.fillColor = SKColor(red: 0.15, green: 0.2, blue: 0.35, alpha: 0.95)
        panel.strokeColor = SKColor(white: 1, alpha: 0.15)
        panel.lineWidth = 1.5
        panel.position = CGPoint(x: w / 2, y: h / 2)
        container.addChild(panel)

        // Title
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "SETTINGS"
        title.fontSize = 24
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: panelH / 2 - 40)
        panel.addChild(title)

        // Toggle rows
        let settings = GameSettings.shared
        let toggles: [(String, Bool, String)] = [
            ("Sound Effects", settings.sfxEnabled, "sfx"),
            ("Music", settings.musicEnabled, "music"),
            ("Haptics", settings.hapticsEnabled, "haptics"),
        ]

        for (i, (label, enabled, key)) in toggles.enumerated() {
            let yPos = CGFloat(30 - i * 55)
            addToggleRow(parent: panel, label: label, enabled: enabled, key: key, y: yPos, panelWidth: panelW)
        }

        // Close button
        let close = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        close.text = "Done"
        close.fontSize = 20
        close.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
        close.name = "settingsClose"
        close.position = CGPoint(x: 0, y: -panelH / 2 + 25)
        panel.addChild(close)

        container.alpha = 0
        scene.addChild(container)
        container.run(SKAction.fadeIn(withDuration: 0.2))
        overlayNode = container
    }

    func dismiss() {
        overlayNode?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
        overlayNode = nil
    }

    func handleTap(at point: CGPoint) -> Bool {
        guard let overlay = overlayNode else { return false }
        let nodes = overlay.scene?.nodes(at: point) ?? []

        for node in nodes {
            if node.name == "settingsClose" {
                dismiss()
                return true
            }
            if let key = node.name, key.hasPrefix("toggle_") {
                let settingKey = String(key.dropFirst(7))
                toggleSetting(settingKey, node: node)
                return true
            }
        }

        // Tap outside panel dismisses
        if let panelNode = overlay.children.first(where: { $0 is SKShapeNode }) {
            let localPoint = panelNode.convert(point, from: overlay.scene!)
            if !panelNode.contains(localPoint) {
                dismiss()
                return true
            }
        }

        return true // consume tap when overlay is visible
    }

    private func addToggleRow(parent: SKNode, label: String, enabled: Bool, key: String, y: CGFloat, panelWidth: CGFloat) {
        let labelNode = SKLabelNode(fontNamed: "AvenirNext-Medium")
        labelNode.text = label
        labelNode.fontSize = 18
        labelNode.fontColor = .white
        labelNode.horizontalAlignmentMode = .left
        labelNode.position = CGPoint(x: -panelWidth / 2 + 30, y: y - 6)
        parent.addChild(labelNode)

        let toggleBg = SKShapeNode(rectOf: CGSize(width: 52, height: 28), cornerRadius: 14)
        toggleBg.fillColor = enabled
            ? SKColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0)
            : SKColor(white: 0.35, alpha: 1.0)
        toggleBg.strokeColor = .clear
        toggleBg.position = CGPoint(x: panelWidth / 2 - 55, y: y)
        toggleBg.name = "toggle_\(key)"
        parent.addChild(toggleBg)

        let knob = SKShapeNode(circleOfRadius: 10)
        knob.fillColor = .white
        knob.strokeColor = .clear
        knob.position = CGPoint(x: enabled ? 11 : -11, y: 0)
        knob.name = "toggle_\(key)"
        toggleBg.addChild(knob)
    }

    private func toggleSetting(_ key: String, node: SKNode) {
        let settings = GameSettings.shared
        let newValue: Bool

        switch key {
        case "sfx":
            settings.sfxEnabled = !settings.sfxEnabled
            newValue = settings.sfxEnabled
        case "music":
            settings.musicEnabled = !settings.musicEnabled
            newValue = settings.musicEnabled
            if !newValue {
                SoundManager.shared.stopMusic()
            } else {
                SoundManager.shared.startMusic(zone: 3)
            }
        case "haptics":
            settings.hapticsEnabled = !settings.hapticsEnabled
            newValue = settings.hapticsEnabled
        default: return
        }

        // Find the toggle background node
        let toggleNode: SKShapeNode
        if let bg = node as? SKShapeNode, bg.children.first is SKShapeNode {
            toggleNode = bg
        } else if let parent = node.parent as? SKShapeNode {
            toggleNode = parent
        } else {
            return
        }

        // Animate toggle
        toggleNode.fillColor = newValue
            ? SKColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0)
            : SKColor(white: 0.35, alpha: 1.0)

        if let knob = toggleNode.children.first {
            knob.run(SKAction.moveTo(x: newValue ? 11 : -11, duration: 0.15))
        }
    }
}
