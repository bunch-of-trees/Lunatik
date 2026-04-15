import AVFoundation

class SoundManager {
    static let shared = SoundManager()

    private var soundData: [String: Data] = [:]
    private var activePlayers: [AVAudioPlayer] = []
    private(set) var isReady = false

    // Background music
    private var musicData: [Int: Data] = [:] // zone -> WAV data
    private var currentMusicPlayer: AVAudioPlayer?
    private var nextMusicPlayer: AVAudioPlayer?
    private var currentMusicZone: Int = -1
    private let musicVolume: Float = 0.08

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

            // Generate ambient music loops per zone
            let music: [Int: Data] = [
                0: generateWAV(generator: zone0Music, duration: 6.0, volume: 1.0),
                1: generateWAV(generator: zone1Music, duration: 6.0, volume: 1.0),
                2: generateWAV(generator: zone2Music, duration: 6.0, volume: 1.0),
                3: generateWAV(generator: zone3Music, duration: 8.0, volume: 1.0),
            ]

            DispatchQueue.main.async {
                self.soundData = sounds
                self.musicData = music
                self.isReady = true
            }
        }
    }

    /// Call early (e.g. from ContentView) so sounds are ready before gameplay
    func warmUp() {}

    // MARK: - Play SFX

    func playJump() { play("jump") }
    func playCollect() { play("collect") }
    func playHit() { play("hit") }
    func playSwoosh() { play("swoosh") }
    func playSlide() { play("slide") }
    func playGameOver() { play("gameOver") }

    private func play(_ name: String) {
        guard GameSettings.shared.sfxEnabled else { return }
        guard isReady, let data = soundData[name] else { return }
        guard let player = try? AVAudioPlayer(data: data) else { return }
        player.volume = 0.5
        // Clean up finished players
        activePlayers.removeAll { !$0.isPlaying }
        activePlayers.append(player)
        player.play()
    }

    // MARK: - Background Music

    func startMusic(zone: Int) {
        guard GameSettings.shared.musicEnabled else { return }
        guard isReady, let data = musicData[zone] else { return }
        guard zone != currentMusicZone else { return }
        currentMusicZone = zone

        currentMusicPlayer?.stop()
        guard let player = try? AVAudioPlayer(data: data) else { return }
        player.numberOfLoops = -1
        player.volume = musicVolume
        player.play()
        currentMusicPlayer = player
    }

    func crossfadeToZone(_ zone: Int) {
        guard GameSettings.shared.musicEnabled else { return }
        guard isReady, let data = musicData[zone] else { return }
        guard zone != currentMusicZone else { return }
        currentMusicZone = zone

        // Set up new player at zero volume
        guard let newPlayer = try? AVAudioPlayer(data: data) else { return }
        newPlayer.numberOfLoops = -1
        newPlayer.volume = 0
        newPlayer.play()
        nextMusicPlayer = newPlayer

        let oldPlayer = currentMusicPlayer
        let targetVolume = musicVolume

        // Crossfade over ~2 seconds using a timer
        let steps = 20
        let interval = 2.0 / Double(steps)
        for i in 0...steps {
            let delay = interval * Double(i)
            let progress = Float(i) / Float(steps)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                oldPlayer?.volume = targetVolume * (1.0 - progress)
                newPlayer.volume = targetVolume * progress
                if i == steps {
                    oldPlayer?.stop()
                    self?.currentMusicPlayer = newPlayer
                    self?.nextMusicPlayer = nil
                }
            }
        }
    }

    func fadeOutMusic(duration: Double = 1.0) {
        let player = currentMusicPlayer
        let steps = 15
        let interval = duration / Double(steps)
        for i in 0...steps {
            let delay = interval * Double(i)
            let progress = Float(i) / Float(steps)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                player?.volume = self?.musicVolume ?? 0.08 * (1.0 - progress)
                if i == steps {
                    player?.stop()
                    self?.currentMusicPlayer = nil
                    self?.currentMusicZone = -1
                }
            }
        }
        nextMusicPlayer?.stop()
        nextMusicPlayer = nil
    }

    func stopMusic() {
        currentMusicPlayer?.stop()
        currentMusicPlayer = nil
        nextMusicPlayer?.stop()
        nextMusicPlayer = nil
        currentMusicZone = -1
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

    // MARK: - SFX Wave Generators

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

    // MARK: - Music Wave Generators

    // Zone 0 (Day): Bright C major pad — C4, E4, G4 layered with slow LFO shimmer
    private func zone0Music(t: Float, progress: Float) -> Float {
        let c4: Float = 261.63
        let e4: Float = 329.63
        let g4: Float = 392.00

        // Smooth loop envelope: fade in/out at edges for seamless looping
        let loopEnv = smoothLoopEnvelope(progress)

        // Slow amplitude modulation for shimmer
        let lfo = 1.0 + 0.15 * sinf(2 * .pi * 0.8 * t)

        let s1 = sinf(2 * .pi * c4 * t) * 0.35
        let s2 = sinf(2 * .pi * e4 * t) * 0.25
        let s3 = sinf(2 * .pi * g4 * t) * 0.2
        // Sub-bass octave below
        let sub = sinf(2 * .pi * (c4 / 2) * t) * 0.15

        return (s1 + s2 + s3 + sub) * loopEnv * lfo
    }

    // Zone 1 (Sunset): Warm Cmaj7 — C4, E4, G4, B4 with detuned warmth
    private func zone1Music(t: Float, progress: Float) -> Float {
        let c4: Float = 261.63
        let e4: Float = 329.63
        let g4: Float = 392.00
        let b4: Float = 493.88

        let loopEnv = smoothLoopEnvelope(progress)
        let lfo = 1.0 + 0.12 * sinf(2 * .pi * 0.5 * t)

        let s1 = sinf(2 * .pi * c4 * t) * 0.3
        // Slightly detuned for warmth
        let s2 = sinf(2 * .pi * (e4 + 1.0) * t) * 0.22
        let s3 = sinf(2 * .pi * g4 * t) * 0.18
        let s4 = sinf(2 * .pi * b4 * t) * 0.12
        let sub = sinf(2 * .pi * (c4 / 2) * t) * 0.12

        return (s1 + s2 + s3 + s4 + sub) * loopEnv * lfo
    }

    // Zone 2 (Dusk): Mysterious A minor — A3, C4, E4 with subtle vibrato
    private func zone2Music(t: Float, progress: Float) -> Float {
        let a3: Float = 220.00
        let c4: Float = 261.63
        let e4: Float = 329.63

        let loopEnv = smoothLoopEnvelope(progress)
        // Slow vibrato
        let vib = sinf(2 * .pi * 3.5 * t) * 2.0

        let s1 = sinf(2 * .pi * (a3 + vib) * t) * 0.3
        let s2 = sinf(2 * .pi * c4 * t) * 0.22
        let s3 = sinf(2 * .pi * (e4 + vib * 0.5) * t) * 0.18
        let sub = sinf(2 * .pi * (a3 / 2) * t) * 0.15

        // Subtle high overtone for eeriness
        let shimmer = sinf(2 * .pi * (e4 * 2) * t) * 0.04 * sinf(2 * .pi * 0.3 * t)

        return (s1 + s2 + s3 + sub + shimmer) * loopEnv
    }

    // Zone 3 (Night): Dark, sparse D minor — D3, F3, A3, very low
    private func zone3Music(t: Float, progress: Float) -> Float {
        let d3: Float = 146.83
        let f3: Float = 174.61
        let a3: Float = 220.00

        let loopEnv = smoothLoopEnvelope(progress)
        // Very slow pulsing
        let lfo = 1.0 + 0.2 * sinf(2 * .pi * 0.25 * t)

        let s1 = sinf(2 * .pi * d3 * t) * 0.3
        let s2 = sinf(2 * .pi * f3 * t) * 0.18
        let s3 = sinf(2 * .pi * a3 * t) * 0.12
        // Deep sub-bass
        let sub = sinf(2 * .pi * (d3 / 2) * t) * 0.2

        // Sparse high note that fades in and out
        let highEnv = max(0, sinf(2 * .pi * 0.15 * t)) * 0.06
        let high = sinf(2 * .pi * (a3 * 2) * t) * highEnv

        return (s1 + s2 + s3 + sub + high) * loopEnv * lfo
    }

    /// Smooth envelope that fades in/out at loop boundaries for seamless looping
    private func smoothLoopEnvelope(_ progress: Float) -> Float {
        let fadeLen: Float = 0.08 // 8% of loop at each end
        if progress < fadeLen {
            return progress / fadeLen
        } else if progress > (1.0 - fadeLen) {
            return (1.0 - progress) / fadeLen
        }
        return 1.0
    }
}
