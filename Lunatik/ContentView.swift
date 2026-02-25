import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var sceneReady = false
    @State private var menuScene: SKScene?

    init() {
        SoundManager.shared.warmUp()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let scene = menuScene, sceneReady {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                        .transition(.opacity)
                } else {
                    // Splash screen while SpriteKit loads
                    splashView
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.3), value: sceneReady)
            .onAppear {
                // Build the scene off the first frame so the splash shows immediately
                DispatchQueue.main.async {
                    let scene = MenuScene(size: geometry.size)
                    scene.scaleMode = .resizeFill
                    menuScene = scene
                    // Small delay to let the scene fully initialize
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        sceneReady = true
                    }
                }
            }
        }
    }

    private var splashView: some View {
        ZStack {
            Color(red: 0.15, green: 0.25, blue: 0.45)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("LUNATIK")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))

                Text("Luna's Wild Run!")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}
