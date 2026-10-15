import Foundation

public struct TileMotion: Identifiable {
    public var id: UUID { tile.id }
    public let tile: Tile
    public let row: Int
    public let column: Int
}

public struct MoveFeedback {
    public let motions: [TileMotion]
    public let mergedIDs: Set<UUID>
}

/// The same time curves used by the Web Canvas renderer, expressed in seconds.
public enum TileAnimation {
    public static let slideDuration = 0.110
    public static let feedbackDuration = 0.130
    public static let duration = slideDuration + feedbackDuration

    public static func slideProgress(at elapsed: Double) -> Double {
        let progress = min(1, max(0, elapsed / slideDuration))
        return 1 - pow(1 - progress, 3)
    }

    public static func mergeScale(at elapsed: Double) -> Double {
        let progress = min(1, max(0, (elapsed - slideDuration) / feedbackDuration))
        return 1 + 0.15 * sin(progress * .pi)
    }

    public static func spawnScale(at elapsed: Double) -> Double {
        min(1, max(0, (elapsed - slideDuration) / (feedbackDuration * 0.8)))
    }
}
