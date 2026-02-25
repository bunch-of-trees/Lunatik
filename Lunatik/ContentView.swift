import SwiftUI
import SpriteKit

struct ContentView: View {
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
