import XCTest
@testable import GameCore

final class GameTests: XCTestCase {
    private func game(_ rows: [[Int]]) -> Game {
        Game(tiles: rows.enumerated().flatMap { row, values in
            values.enumerated().compactMap { column, value in
                value == 0 ? nil : Tile(value: value, row: row, column: column)
            }
        })
    }
    private func values(_ game: Game, row: Int) -> [Int] {
        (0..<4).map { column in game.tiles.first { $0.row == row && $0.column == column }?.value ?? 0 }
    }
    func testMergesOnlyOnce() {
        var state = game([[2, 2, 2, 2], [4, 4, 8, 0]])
        XCTAssertTrue(state.move(.left))
        XCTAssertEqual(values(state, row: 0), [4, 4, 0, 0])
        XCTAssertEqual(values(state, row: 1), [8, 8, 0, 0])
        XCTAssertEqual(state.score, 16)
    }
    func testDirectionsAndIdentity() {
        for direction in Direction.allCases {
            var state = game([[0, 0, 0, 0], [0, 2, 0, 0]])
            let identity = state.tiles[0].id
            XCTAssertTrue(state.move(direction))
            XCTAssertEqual(state.tiles[0].id, identity)
            switch direction {
            case .left: XCTAssertEqual(state.tiles[0].column, 0)
            case .right: XCTAssertEqual(state.tiles[0].column, 3)
            case .up: XCTAssertEqual(state.tiles[0].row, 0)
            case .down: XCTAssertEqual(state.tiles[0].row, 3)
            }
        }
    }
    func testInvalidMoveDoesNotChangeState() {
        var state = game([[2, 4, 0, 0]])
        let previous = state
        XCTAssertFalse(state.move(.left))
        XCTAssertEqual(state, previous)
    }
    func testLossAndWin() {
        let stuck = game([[2,4,2,4],[4,2,4,2],[2,4,2,4],[4,2,4,2]])
        XCTAssertFalse(stuck.canMove)
        XCTAssertTrue(game([[2,2,4,8],[4,8,16,32],[8,16,32,64],[16,32,64,128]]).canMove)
        var winning = game([[1024,1024,0,0]])
        winning.move(.left)
        XCTAssertTrue(winning.won)
        winning.continued = true
        XCTAssertFalse(winning.won)
    }
    func testSpawnAndRoundTrip() throws {
        var state = Game()
        state.spawn(random: { 0 })
        state.spawn(random: { 0.99 })
        XCTAssertEqual(state.tiles.map(\.value), [2,4])
        XCTAssertEqual(state.tiles[0].column, 0)
        XCTAssertEqual(state.tiles[1].row, 3)
        XCTAssertTrue(state.isValid)
        XCTAssertEqual(try JSONDecoder().decode(Game.self, from: JSONEncoder().encode(state)), state)
    }
    func testRejectsCorruptSave() {
        XCTAssertFalse(Game(tiles: [Tile(value: 3, row: 0, column: 0)]).isValid)
        XCTAssertFalse(Game(tiles: [Tile(value: 2, row: 4, column: 0)]).isValid)
        XCTAssertFalse(Game(tiles: [Tile(value: 2, row: 0, column: 0), Tile(value: 4, row: 0, column: 0)]).isValid)
    }
}
