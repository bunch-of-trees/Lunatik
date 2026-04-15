import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var sceneReady = false
    @State private var menuScene: SKScene?
    @State private var titlePulse = false
    @State private var dotCount = 0

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
                    splashView
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.4), value: sceneReady)
            .onAppear {
                // Animate loading dots
                Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
                    if sceneReady { timer.invalidate(); return }
                    dotCount = (dotCount % 3) + 1
                }

                // Build the scene off the first frame so the splash shows immediately
                DispatchQueue.main.async {
                    let scene = MenuScene(size: geometry.size)
                    scene.scaleMode = .resizeFill
                    menuScene = scene

                    // Gate on SoundManager readiness + minimum display time
                    let startTime = Date()
                    let minDisplay: TimeInterval = 0.5
                    func checkReady() {
                        let elapsed = Date().timeIntervalSince(startTime)
                        if SoundManager.shared.isReady && elapsed >= minDisplay {
                            sceneReady = true
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                checkReady()
                            }
                        }
                    }
                    checkReady()
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
                    .font(.custom("AvenirNext-Heavy", size: 52))
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                    .shadow(color: Color(red: 0.5, green: 0.25, blue: 0.0).opacity(0.5), radius: 0, x: 3, y: 3)
                    .scaleEffect(titlePulse ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: titlePulse)
                    .onAppear { titlePulse = true }

                Text("Luna's Wild Run!")
                    .font(.custom("AvenirNext-Medium", size: 18))
                    .foregroundColor(.white.opacity(0.7))

                Text(String(repeating: ".", count: dotCount))
                    .font(.custom("AvenirNext-Bold", size: 24))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(width: 40, height: 24)
            }
        }
    }
}
