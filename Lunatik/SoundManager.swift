import AVFoundation

class SoundManager {
    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100

    // Pre-generated buffers
    private var jumpBuffer: AVAudioPCMBuffer?
    private var collectBuffer: AVAudioPCMBuffer?
    private var hitBuffer: AVAudioPCMBuffer?
    private var swooshBuffer: AVAudioPCMBuffer?
    private var slideBuffer: AVAudioPCMBuffer?
    private var gameOverBuffer: AVAudioPCMBuffer?

    private init() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        try? engine.start()
        generateAllSounds()
    }

    // MARK: - Play

    func playJump() { play(jumpBuffer) }
    func playCollect() { play(collectBuffer) }
    func playHit() { play(hitBuffer) }
    func playSwoosh() { play(swooshBuffer) }
    func playSlide() { play(slideBuffer) }
    func playGameOver() { play(gameOverBuffer) }

    private func play(_ buffer: AVAudioPCMBuffer?) {
        guard let buffer = buffer else { return }
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        if !playerNode.isPlaying { playerNode.play() }
    }

    // MARK: - Sound Generation

    private func generateAllSounds() {
        jumpBuffer = generateJumpSound()
        collectBuffer = generateCollectSound()
        hitBuffer = generateHitSound()
        swooshBuffer = generateSwooshSound()
        slideBuffer = generateSlideSound()
        gameOverBuffer = generateGameOverSound()
    }

    private func makeBuffer(duration: Double) -> (AVAudioPCMBuffer, UnsafeMutablePointer<Float>)? {
        let length = Int(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(length))
        else { return nil }
        buffer.frameLength = AVAudioFrameCount(length)
        return (buffer, buffer.floatChannelData![0])
    }

    // Bouncy ascending chirp
    private func generateJumpSound() -> AVAudioPCMBuffer? {
        let dur = 0.18
        guard let (buffer, data) = makeBuffer(duration: dur) else { return nil }
        let length = Int(sampleRate * dur)
        for i in 0..<length {
            let t = Float(i) / Float(sampleRate)
            let progress = Float(i) / Float(length)
            let freq: Float = 350 + 500 * progress * progress
            let envelope = (1.0 - progress) * (1.0 - progress)
            data[i] = sinf(2 * .pi * freq * t) * 0.3 * envelope
        }
        return buffer
    }

    // Bright double chime
    private func generateCollectSound() -> AVAudioPCMBuffer? {
        let dur = 0.2
        guard let (buffer, data) = makeBuffer(duration: dur) else { return nil }
        let length = Int(sampleRate * dur)
        for i in 0..<length {
            let t = Float(i) / Float(sampleRate)
            let progress = Float(i) / Float(length)
            let envelope = max(0, 1.0 - progress * 2.5)
            // Two harmonics for a chime
            let s1 = sinf(2 * .pi * 1200 * t) * 0.15
            let s2 = sinf(2 * .pi * 1600 * t) * 0.1
            // Second chime delayed
            let env2: Float = progress > 0.3 ? max(0, 1.0 - (progress - 0.3) * 3.0) : 0
            let s3 = sinf(2 * .pi * 1500 * t) * 0.15 * env2
            data[i] = (s1 + s2) * envelope + s3
        }
        return buffer
    }

    // Low impact thud
    private func generateHitSound() -> AVAudioPCMBuffer? {
        let dur = 0.25
        guard let (buffer, data) = makeBuffer(duration: dur) else { return nil }
        let length = Int(sampleRate * dur)
        for i in 0..<length {
            let t = Float(i) / Float(sampleRate)
            let progress = Float(i) / Float(length)
            let freq: Float = 120 * (1.0 - progress * 0.5)
            let envelope = (1.0 - progress) * (1.0 - progress)
            let tone = sinf(2 * .pi * freq * t) * 0.4
            let noise = Float.random(in: -0.15...0.15) * (1.0 - progress)
            data[i] = (tone + noise) * envelope
        }
        return buffer
    }

    // Quick swoosh for lane switch
    private func generateSwooshSound() -> AVAudioPCMBuffer? {
        let dur = 0.1
        guard let (buffer, data) = makeBuffer(duration: dur) else { return nil }
        let length = Int(sampleRate * dur)
        for i in 0..<length {
            let progress = Float(i) / Float(length)
            let envelope = sinf(.pi * progress) // smooth bell curve
            let noise = Float.random(in: -1...1)
            data[i] = noise * 0.12 * envelope
        }
        return buffer
    }

    // Sliding scrape
    private func generateSlideSound() -> AVAudioPCMBuffer? {
        let dur = 0.3
        guard let (buffer, data) = makeBuffer(duration: dur) else { return nil }
        let length = Int(sampleRate * dur)
        for i in 0..<length {
            let t = Float(i) / Float(sampleRate)
            let progress = Float(i) / Float(length)
            let envelope = 1.0 - progress
            let noise = Float.random(in: -1...1) * 0.08
            let tone = sinf(2 * .pi * 200 * t) * 0.06
            data[i] = (noise + tone) * envelope
        }
        return buffer
    }

    // Sad descending tone
    private func generateGameOverSound() -> AVAudioPCMBuffer? {
        let dur = 0.6
        guard let (buffer, data) = makeBuffer(duration: dur) else { return nil }
        let length = Int(sampleRate * dur)
        for i in 0..<length {
            let t = Float(i) / Float(sampleRate)
            let progress = Float(i) / Float(length)
            let freq: Float = 440 * (1.0 - progress * 0.6)
            let envelope = max(0, 1.0 - progress * 1.2)
            let s1 = sinf(2 * .pi * freq * t) * 0.2
            let s2 = sinf(2 * .pi * freq * 0.5 * t) * 0.15
            data[i] = (s1 + s2) * envelope
        }
        return buffer
    }
}
