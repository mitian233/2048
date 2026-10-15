import Foundation

public enum Direction: CaseIterable { case left, right, up, down }

public struct Tile: Identifiable, Codable, Equatable {
    public let id: UUID
    public var value: Int
    public var row: Int
    public var column: Int

    public init(value: Int, row: Int, column: Int, id: UUID = UUID()) {
        self.id = id
        self.value = value
        self.row = row
        self.column = column
    }
}

public struct Game: Codable, Equatable {
    public private(set) var tiles: [Tile]
    public private(set) var score: Int
    public var continued: Bool

    public init(tiles: [Tile] = [], score: Int = 0, continued: Bool = false) {
        self.tiles = tiles
        self.score = score
        self.continued = continued
    }

    public var won: Bool { !continued && tiles.contains { $0.value >= 2048 } }
    public var isValid: Bool {
        score >= 0 && tiles.count <= 16 && Set(tiles.map(\.id)).count == tiles.count &&
        Set(tiles.map { $0.row * 4 + $0.column }).count == tiles.count &&
        tiles.allSatisfy { (0..<4).contains($0.row) && (0..<4).contains($0.column) &&
            $0.value >= 2 && $0.value <= (1 << 40) && ($0.value & ($0.value - 1)) == 0 }
    }
    public var canMove: Bool {
        tiles.count < 16 || Direction.allCases.contains { direction in
            var copy = self
            return copy.move(direction)
        }
    }

    @discardableResult
    public mutating func spawn(random: () -> Double = { Double.random(in: 0..<1) }) -> UUID? {
        let occupied = Set(tiles.map { $0.row * 4 + $0.column })
        let empty = (0..<16).filter { !occupied.contains($0) }
        guard !empty.isEmpty else { return nil }
        let index = empty[min(empty.count - 1, max(0, Int(random() * Double(empty.count))))]
        let tile = Tile(value: random() < 0.9 ? 2 : 4, row: index / 4, column: index % 4)
        tiles.append(tile)
        return tile.id
    }

    /// Moves without spawning; callers animate this result before adding the new tile.
    @discardableResult
    public mutating func move(_ direction: Direction) -> Bool {
        moveWithFeedback(direction) != nil
    }

    public mutating func moveWithFeedback(_ direction: Direction) -> MoveFeedback? {
        func position(_ line: Int, _ index: Int) -> (Int, Int) {
            switch direction {
            case .left: return (line, index)
            case .right: return (line, 3 - index)
            case .up: return (index, line)
            case .down: return (3 - index, line)
            }
        }
        let original = tiles
        var output: [Tile] = []
        var motions: [TileMotion] = []
        var mergedIDs: Set<UUID> = []
        var gained = 0
        for line in 0..<4 {
            let ordered = (0..<4).compactMap { index -> Tile? in
                let (row, column) = position(line, index)
                return original.first { $0.row == row && $0.column == column }
            }
            var index = 0
            var destination = 0
            while index < ordered.count {
                var tile = ordered[index]
                let (row, column) = position(line, destination)
                motions.append(TileMotion(tile: tile, row: row, column: column))
                tile.row = row
                tile.column = column
                if index + 1 < ordered.count && tile.value == ordered[index + 1].value {
                    motions.append(TileMotion(tile: ordered[index + 1], row: row, column: column))
                    mergedIDs.insert(tile.id)
                    tile.value *= 2
                    gained += tile.value
                    index += 1
                }
                output.append(tile)
                index += 1
                destination += 1
            }
        }
        let changed = output.count != original.count || output.contains { tile in
            guard let previous = original.first(where: { $0.id == tile.id }) else { return true }
            return previous != tile
        }
        guard changed else { return nil }
        tiles = output
        score += gained
        return MoveFeedback(motions: motions, mergedIDs: mergedIDs)
    }
}
