import XCTest
@testable import GameCore

final class AnimationTests: XCTestCase {
    func testMergeKeepsBothOriginalTilesUntilTheyReachTheSameCell() throws {
        var game = Game(tiles: [
            Tile(value: 2, row: 0, column: 0),
            Tile(value: 2, row: 0, column: 2)
        ])
        let originalIDs = Set(game.tiles.map(\.id))
        let feedback = try XCTUnwrap(game.moveWithFeedback(.left))
        XCTAssertEqual(Set(feedback.motions.map(\.id)), originalIDs)
        XCTAssertEqual(feedback.motions.map { $0.tile.value }, [2, 2])
        XCTAssertTrue(feedback.motions.allSatisfy { $0.row == 0 && $0.column == 0 })
        XCTAssertEqual(game.tiles.count, 1)
        XCTAssertEqual(game.tiles[0].value, 4)
        XCTAssertEqual(feedback.mergedIDs, [game.tiles[0].id])
    }

    func testSeparatePairsProduceSeparateMergeFeedback() throws {
        var game = Game(tiles: (0..<4).map { Tile(value: 2, row: 0, column: $0) })
        let feedback = try XCTUnwrap(game.moveWithFeedback(.right))
        XCTAssertEqual(feedback.motions.map(\.column), [3, 3, 2, 2])
        XCTAssertEqual(feedback.mergedIDs.count, 2)
        XCTAssertEqual(game.score, 8)
    }

    func testSlideWithoutMergeAndInvalidMove() throws {
        var game = Game(tiles: [Tile(value: 4, row: 2, column: 3)])
        let feedback = try XCTUnwrap(game.moveWithFeedback(.up))
        XCTAssertTrue(feedback.mergedIDs.isEmpty)
        XCTAssertEqual(feedback.motions[0].row, 0)
        XCTAssertEqual(feedback.motions[0].column, 3)
        XCTAssertNil(game.moveWithFeedback(.up))
    }

    func testTimingMatchesWebCanvasCurves() {
        XCTAssertEqual(TileAnimation.duration, 0.24, accuracy: 0.000001)
        XCTAssertEqual(TileAnimation.slideProgress(at: 0), 0)
        XCTAssertEqual(TileAnimation.slideProgress(at: 0.055), 0.875, accuracy: 0.000001)
        XCTAssertEqual(TileAnimation.slideProgress(at: 0.110), 1)
        XCTAssertEqual(TileAnimation.mergeScale(at: 0.110), 1, accuracy: 0.000001)
        XCTAssertEqual(TileAnimation.mergeScale(at: 0.175), 1.15, accuracy: 0.000001)
        XCTAssertEqual(TileAnimation.mergeScale(at: 0.240), 1, accuracy: 0.000001)
        XCTAssertEqual(TileAnimation.spawnScale(at: 0.110), 0, accuracy: 0.000001)
        XCTAssertEqual(TileAnimation.spawnScale(at: 0.162), 0.5, accuracy: 0.000001)
        XCTAssertEqual(TileAnimation.spawnScale(at: 0.214), 1, accuracy: 0.000001)
    }
}
