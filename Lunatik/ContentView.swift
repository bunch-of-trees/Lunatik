import SwiftUI
import SpriteKit

struct ContentView: View {
    init() {
        // Pre-warm sound generation on a background thread
        SoundManager.shared.warmUp()
    }

    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: makeMenuScene(size: geometry.size))
                .ignoresSafeArea()
        }
    }

    private func makeMenuScene(size: CGSize) -> SKScene {
        let scene = MenuScene(size: size)
        scene.scaleMode = .resizeFill
        return scene
    }
}
