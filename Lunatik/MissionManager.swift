import Foundation

// MARK: - Mission Types

enum MissionType: String, Codable, CaseIterable {
    case collectBones
    case collectPizzas
    case reachDistance
    case nearMisses
    case comboStreak
    case slideDodges
    case pickUpPowerUp
    case singleRunScore

    func description(target: Int) -> String {
        switch self {
        case .collectBones: return "Collect \(target) bones"
        case .collectPizzas: return "Collect \(target) pizzas"
        case .reachDistance: return "Reach distance \(target)"
        case .nearMisses: return "Get \(target) near-misses"
        case .comboStreak: return "Reach a x\(target) combo"
        case .slideDodges: return "Slide under \(target) obstacles"
        case .pickUpPowerUp: return "Pick up \(target) power-ups"
        case .singleRunScore: return "Score \(target) in one run"
        }
    }

    /// Bone reward scales with difficulty
    func reward(target: Int) -> Int {
        switch self {
        case .collectBones: return target * 2
        case .collectPizzas: return target * 5
        case .reachDistance: return target / 10
        case .nearMisses: return target * 8
        case .comboStreak: return target * 10
        case .slideDodges: return target * 6
        case .pickUpPowerUp: return target * 15
        case .singleRunScore: return target / 5
        }
    }
}

// MARK: - Mission

struct Mission: Codable, Identifiable {
    let id: String
    let type: MissionType
    let target: Int
    var progress: Int
    let reward: Int

    var isComplete: Bool { progress >= target }

    var description: String { type.description(target: target) }

    var progressText: String { "\(min(progress, target))/\(target)" }
}

// MARK: - Mission Manager

class MissionManager {
    static let shared = MissionManager()

    private let missionsKey = "LunatikMissions"
    private let bonesKey = "LunatikBones"
    private let completedCountKey = "LunatikCompletedMissions"

    private(set) var activeMissions: [Mission] = []
    private(set) var totalBones: Int = 0
    private(set) var completedMissionCount: Int = 0

    // Per-run tracking (reset each game)
    var runBones: Int = 0
    var runPizzas: Int = 0
    var runDistance: Int = 0
    var runNearMisses: Int = 0
    var runMaxCombo: Int = 0
    var runSlideDodges: Int = 0
    var runPowerUps: Int = 0
    var runScore: Int = 0
    var runBonesEarned: Int = 0

    private init() {
        load()
        if activeMissions.isEmpty {
            generateNewMissions()
        }
    }

    // MARK: - Persistence

    private func load() {
        totalBones = UserDefaults.standard.integer(forKey: bonesKey)
        completedMissionCount = UserDefaults.standard.integer(forKey: completedCountKey)

        if let data = UserDefaults.standard.data(forKey: missionsKey),
           let missions = try? JSONDecoder().decode([Mission].self, from: data) {
            activeMissions = missions
        }
    }

    private func save() {
        UserDefaults.standard.set(totalBones, forKey: bonesKey)
        UserDefaults.standard.set(completedMissionCount, forKey: completedCountKey)

        if let data = try? JSONEncoder().encode(activeMissions) {
            UserDefaults.standard.set(data, forKey: missionsKey)
        }
    }

    // MARK: - Run Lifecycle

    func startRun() {
        runBones = 0
        runPizzas = 0
        runDistance = 0
        runNearMisses = 0
        runMaxCombo = 0
        runSlideDodges = 0
        runPowerUps = 0
        runScore = 0
        runBonesEarned = 0
    }

    /// Called when the run ends. Returns missions completed this run.
    @discardableResult
    func endRun(finalScore: Int) -> [Mission] {
        runScore = finalScore
        updateMissionProgress()

        var justCompleted: [Mission] = []
        for i in activeMissions.indices {
            if activeMissions[i].isComplete {
                justCompleted.append(activeMissions[i])
            }
        }

        // Award bones from completed missions
        for mission in justCompleted {
            totalBones += mission.reward
            runBonesEarned += mission.reward
            completedMissionCount += 1
        }

        // Award run bones (1 bone per 5 collectible bones picked up)
        let runBoneReward = runBones / 5
        totalBones += runBoneReward
        runBonesEarned += runBoneReward

        // Replace completed missions
        activeMissions = activeMissions.filter { !$0.isComplete }
        while activeMissions.count < 3 {
            activeMissions.append(generateMission())
        }

        save()
        return justCompleted
    }

    // MARK: - Event Reporting

    func reportCollect(type: CollectibleType) {
        switch type {
        case .bone: runBones += 1
        case .pizza: runPizzas += 1
        case .tennisBall: break
        }
    }

    func reportNearMiss() {
        runNearMisses += 1
    }

    func reportCombo(_ count: Int) {
        runMaxCombo = max(runMaxCombo, count)
    }

    func reportSlideDodge() {
        runSlideDodges += 1
    }

    func reportPowerUp() {
        runPowerUps += 1
    }

    func reportDistance(_ distance: Int) {
        runDistance = max(runDistance, distance)
    }

    // MARK: - Mission Progress

    private func updateMissionProgress() {
        for i in activeMissions.indices {
            guard !activeMissions[i].isComplete else { continue }
            switch activeMissions[i].type {
            case .collectBones:
                activeMissions[i].progress += runBones
            case .collectPizzas:
                activeMissions[i].progress += runPizzas
            case .reachDistance:
                activeMissions[i].progress = max(activeMissions[i].progress, runDistance)
            case .nearMisses:
                activeMissions[i].progress += runNearMisses
            case .comboStreak:
                activeMissions[i].progress = max(activeMissions[i].progress, runMaxCombo)
            case .slideDodges:
                activeMissions[i].progress += runSlideDodges
            case .pickUpPowerUp:
                activeMissions[i].progress += runPowerUps
            case .singleRunScore:
                activeMissions[i].progress = max(activeMissions[i].progress, runScore)
            }
        }
    }

    // MARK: - Mission Generation

    private func generateNewMissions() {
        activeMissions = []
        for _ in 0..<3 {
            activeMissions.append(generateMission())
        }
        save()
    }

    private func generateMission() -> Mission {
        // Avoid duplicating active mission types
        let activeTypes = Set(activeMissions.map { $0.type })
        let available = MissionType.allCases.filter { !activeTypes.contains($0) }
        let type = (available.isEmpty ? MissionType.allCases : available).randomElement()!

        // Scale difficulty with completed missions
        let tier = min(completedMissionCount / 3, 4)
        let target = targetForType(type, tier: tier)
        let reward = type.reward(target: target)

        return Mission(
            id: UUID().uuidString,
            type: type,
            target: target,
            progress: 0,
            reward: reward
        )
    }

    private func targetForType(_ type: MissionType, tier: Int) -> Int {
        let base: Int
        let scale: Int
        switch type {
        case .collectBones:     base = 5;    scale = 5
        case .collectPizzas:    base = 2;    scale = 2
        case .reachDistance:     base = 300;  scale = 200
        case .nearMisses:       base = 2;    scale = 2
        case .comboStreak:      base = 3;    scale = 1
        case .slideDodges:      base = 2;    scale = 2
        case .pickUpPowerUp:    base = 1;    scale = 1
        case .singleRunScore:   base = 50;   scale = 50
        }
        return base + scale * tier
    }
}
