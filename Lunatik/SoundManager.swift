import AVFoundation

class SoundManager {
    static let shared = SoundManager()

    private var soundData: [String: Data] = [:]
    private var activePlayers: [AVAudioPlayer] = []
    private var isReady = false

    private init() {
        // Generate sounds off main thread so we don't freeze the game
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let sounds = [
                "jump": generateWAV(generator: jumpWave, duration: 0.15, volume: 0.3),
                "collect": generateWAV(generator: collectWave, duration: 0.18, volume: 0.25),
                "hit": generateWAV(generator: hitWave, duration: 0.2, volume: 0.35),
                "swoosh": generateWAV(generator: swooshWave, duration: 0.08, volume: 0.12),
                "slide": generateWAV(generator: slideWave, duration: 0.25, volume: 0.1),
                "gameOver": generateWAV(generator: gameOverWave, duration: 0.5, volume: 0.25),
            ]
            DispatchQueue.main.async {
                self.soundData = sounds
                self.isReady = true
            }
        }
    }

    /// Call early (e.g. from ContentView) so sounds are ready before gameplay
    func warmUp() {}

    // MARK: - Play

    func playJump() { play("jump") }
    func playCollect() { play("collect") }
    func playHit() { play("hit") }
    func playSwoosh() { play("swoosh") }
    func playSlide() { play("slide") }
    func playGameOver() { play("gameOver") }

    private func play(_ name: String) {
        guard isReady, let data = soundData[name] else { return }
        guard let player = try? AVAudioPlayer(data: data) else { return }
        player.volume = 0.5
        // Clean up finished players
        activePlayers.removeAll { !$0.isPlaying }
        activePlayers.append(player)
        player.play()
    }

    // MARK: - WAV Generation

    private typealias WaveGenerator = (_ t: Float, _ progress: Float) -> Float

    private func generateWAV(generator: WaveGenerator, duration: Double, volume: Float) -> Data {
        let sampleRate: Int = 44100
        let numSamples = Int(Double(sampleRate) * duration)
        var data = Data()

        // WAV header (44 bytes)
        let dataSize = numSamples * 2 // 16-bit samples
        let fileSize = 36 + dataSize
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        data.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) })
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) }) // chunk size
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // PCM
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // mono
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate * 2).littleEndian) { Array($0) }) // byte rate
        data.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Array($0) }) // block align
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) }) // bits per sample
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })

        // Generate samples
        for i in 0..<numSamples {
            let t = Float(i) / Float(sampleRate)
            let progress = Float(i) / Float(numSamples)
            let sample = generator(t, progress) * volume
            let clamped = max(-1.0, min(1.0, sample))
            let int16 = Int16(clamped * 32000)
            data.append(contentsOf: withUnsafeBytes(of: int16.littleEndian) { Array($0) })
        }

        return data
    }

    // MARK: - Wave Generators

    private func jumpWave(t: Float, progress: Float) -> Float {
        let freq: Float = 350 + 550 * progress * progress
        let envelope = (1.0 - progress) * (1.0 - progress)
        return sinf(2 * .pi * freq * t) * envelope
    }

    private func collectWave(t: Float, progress: Float) -> Float {
        let env1 = max(0, 1.0 - progress * 3.0)
        let s1 = sinf(2 * .pi * 1200 * t) * 0.6 * env1
        let env2: Float = progress > 0.25 ? max(0, 1.0 - (progress - 0.25) * 3.5) : 0
        let s2 = sinf(2 * .pi * 1500 * t) * 0.6 * env2
        return s1 + s2
    }

    private func hitWave(t: Float, progress: Float) -> Float {
        let freq: Float = 110 * (1.0 - progress * 0.5)
        let envelope = (1.0 - progress) * (1.0 - progress)
        let tone = sinf(2 * .pi * freq * t) * envelope
        return tone
    }

    private func swooshWave(t: Float, progress: Float) -> Float {
        let envelope = sinf(.pi * progress)
        return Float.random(in: -1...1) * envelope
    }

    private func slideWave(t: Float, progress: Float) -> Float {
        let envelope = 1.0 - progress
        let noise = Float.random(in: -1...1) * 0.4
        let tone = sinf(2 * .pi * 180 * t) * 0.3
        return (noise + tone) * envelope
    }

    private func gameOverWave(t: Float, progress: Float) -> Float {
        let freq: Float = 400 * (1.0 - progress * 0.55)
        let envelope = max(0, 1.0 - progress * 1.3)
        let s1 = sinf(2 * .pi * freq * t) * 0.5
        let s2 = sinf(2 * .pi * freq * 0.5 * t) * 0.4
        return (s1 + s2) * envelope
    }
}
