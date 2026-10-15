import SwiftUI
import AppKit
import GameCore

@main
struct Classic2048App: App {
    @State private var model = GameModel()

    var body: some Scene {
        Window("2048", id: "game") {
            GameView(model: model)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button { model.restart() } label: {
                            Label("New Game", systemImage: "arrow.counterclockwise")
                        }
                        .help("New Game (⌘N)")
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commands {
            AboutCommands()
            CommandGroup(replacing: .newItem) {
                Button("New Game") { model.restart() }
                    .keyboardShortcut("n", modifiers: .command)
            }
            CommandMenu("Game") {
                Button("Move Left") { model.move(.left) }.keyboardShortcut(.leftArrow, modifiers: [])
                Button("Move Right") { model.move(.right) }.keyboardShortcut(.rightArrow, modifiers: [])
                Button("Move Up") { model.move(.up) }.keyboardShortcut(.upArrow, modifiers: [])
                Button("Move Down") { model.move(.down) }.keyboardShortcut(.downArrow, modifiers: [])
            }
        }

        Window("About 2048", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

@MainActor @Observable
final class GameModel {
    private(set) var game: Game
    private(set) var best: Int
    private(set) var busy = false
    private(set) var spawnedID: UUID?
    private(set) var feedback: MoveFeedback?
    private(set) var animationStart = Date()
    private var pending: Direction?
    private var generation = UUID()
    private let defaults: UserDefaults
    var reduceMotion = false

    var ended: Bool { game.won || !game.canMove }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        best = max(0, defaults.integer(forKey: "bestScore"))
        if let data = defaults.data(forKey: "savedGame"),
           let saved = try? JSONDecoder().decode(Game.self, from: data), saved.isValid, !saved.tiles.isEmpty {
            game = saved
        } else {
            game = Game()
            game.spawn()
            game.spawn()
        }
        best = max(best, game.score)
    }

    func move(_ direction: Direction) {
        guard !ended else { return }
        guard !busy else { pending = direction; return }
        var next = game
        guard let movement = next.moveWithFeedback(direction) else { return }
        var completed = next
        spawnedID = completed.spawn()
        game = completed
        best = max(best, completed.score)
        persist(completed)
        guard !reduceMotion else { feedback = nil; return }
        busy = true
        feedback = movement
        animationStart = Date()
        let token = generation
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(240))
            guard token == generation else { return }
            feedback = nil
            busy = false
            let nextDirection = pending
            pending = nil
            if let nextDirection { move(nextDirection) }
        }
    }

    func restart() {
        generation = UUID()
        pending = nil
        busy = false
        spawnedID = nil
        feedback = nil
        game = Game()
        game.spawn()
        game.spawn()
        persist(game)
    }

    func keepPlaying() {
        game.continued = true
        persist(game)
    }

    private func persist(_ state: Game) {
        defaults.set(best, forKey: "bestScore")
        if let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: "savedGame") }
    }
}

extension Color {
    init(rgb: UInt32) {
        self.init(.sRGB, red: Double((rgb >> 16) & 255) / 255,
                  green: Double((rgb >> 8) & 255) / 255, blue: Double(rgb & 255) / 255, opacity: 1)
    }
}

enum Palette {
    static let paper = Color(rgb: 0xfaf8ef)
    static let ink = Color(rgb: 0x776e65)
    static let board = Color(rgb: 0xbbada0)
    static let empty = Color(rgb: 0xcdc1b4)
    static let button = Color(rgb: 0x8f7a66)
    static func tile(_ value: Int) -> Color {
        let colors: [Int: UInt32] = [2:0xeee4da,4:0xede0c8,8:0xf2b179,16:0xf59563,
            32:0xf67c5f,64:0xf65e3b,128:0xedcf72,256:0xedcc61,512:0xedc850,
            1024:0xedc53f,2048:0xedc22e]
        return Color(rgb: colors[value] ?? 0x3c3a32)
    }
}

struct GameView: View {
    let model: GameModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // A quiet, right-aligned display above a compact keypad-like board.
            VStack(alignment: .trailing, spacing: 5) {
                HStack {
                    Text("2048").font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("BEST  \(model.best)").font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Palette.ink)
                Text(model.game.score.formatted(.number.grouping(.never)))
                    .font(.system(size: 52, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityLabel("Score \(model.game.score)")
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 14)

            HStack {
                Text("↑ ↓ ← →  /  WASD")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Palette.ink.opacity(0.8))
                    .accessibilityLabel("Use arrow keys, W A S D, or swipe to move")
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)

            BoardView(model: model)
                .padding(8)
                .background(Palette.board)
        }
        .background(Palette.paper)
        .frame(width: 344)
        .preferredColorScheme(.light)
        .onAppear { model.reduceMotion = reduceMotion }
        .onChange(of: reduceMotion) { _, value in model.reduceMotion = value }
        .onKeyPress(characters: CharacterSet(charactersIn: "wasdWASD")) { key in
            switch key.characters.lowercased() {
            case "a": model.move(.left)
            case "d": model.move(.right)
            case "w": model.move(.up)
            case "s": model.move(.down)
            default: return .ignored
            }
            return .handled
        }
    }
}

struct CalculatorButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 12)
            .frame(height: 28)
            .foregroundStyle(Color.white)
            .background(Palette.button.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 5))
            .contentShape(RoundedRectangle(cornerRadius: 5))
    }
}

struct BoardView: View {
    let model: GameModel
    @FocusState private var focused: Bool
    private let cell: CGFloat = 76
    private let gap: CGFloat = 8

    private func tileScale(_ tile: Tile, elapsed: Double) -> Double {
        guard let feedback = model.feedback else { return 1 }
        if tile.id == model.spawnedID { return TileAnimation.spawnScale(at: elapsed) }
        if feedback.mergedIDs.contains(tile.id) { return TileAnimation.mergeScale(at: elapsed) }
        return 1
    }

    private func tileFace(_ tile: Tile) -> some View {
        Text(String(tile.value))
            .font(.system(size: tile.value < 100 ? 32 : tile.value < 1000 ? 27 : 22, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(tile.value <= 4 ? Palette.ink : Color(rgb: 0xf9f6f2))
            .frame(width: cell, height: cell)
            .background(Palette.tile(tile.value), in: RoundedRectangle(cornerRadius: 6))
            .accessibilityLabel("\(tile.value), row \(tile.row + 1), column \(tile.column + 1)")
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<16, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6)
                    .fill(Palette.empty)
                    .frame(width: cell, height: cell)
                    .offset(x: CGFloat(index % 4) * (cell + gap), y: CGFloat(index / 4) * (cell + gap))
                    .accessibilityHidden(true)
            }
            TimelineView(.animation(paused: !model.busy)) { context in
                let elapsed = max(0, context.date.timeIntervalSince(model.animationStart))
                ZStack(alignment: .topLeading) {
                    if let feedback = model.feedback, elapsed < TileAnimation.slideDuration {
                        ForEach(feedback.motions) { motion in
                            let progress = TileAnimation.slideProgress(at: elapsed)
                            tileFace(motion.tile)
                                .offset(
                                    x: (Double(motion.tile.column) + Double(motion.column - motion.tile.column) * progress) * (cell + gap),
                                    y: (Double(motion.tile.row) + Double(motion.row - motion.tile.row) * progress) * (cell + gap))
                        }
                    } else {
                        ForEach(model.game.tiles) { tile in
                            tileFace(tile)
                                .scaleEffect(tileScale(tile, elapsed: elapsed))
                                .offset(x: CGFloat(tile.column) * (cell + gap), y: CGFloat(tile.row) * (cell + gap))
                                .zIndex(model.feedback?.mergedIDs.contains(tile.id) == true ? 1 : 0)
                        }
                    }
                }
                .frame(width: 328, height: 328, alignment: .topLeading)
            }
            if model.ended && !model.busy {
                VStack(spacing: 12) {
                    Text(model.game.won ? "You win!" : "Game over")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                    if model.game.won {
                        Button("Keep Playing") { model.keepPlaying(); focused = true }
                            .buttonStyle(CalculatorButtonStyle())
                    }
                    Button("Try Again") { model.restart(); focused = true }
                        .buttonStyle(CalculatorButtonStyle())
                }
                .frame(width: 328, height: 328)
                .foregroundStyle(Palette.ink)
                .background(Palette.paper.opacity(0.94), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        // Offset changes rendering, not layout size. Anchor the stack's
        // intrinsic cell-sized bounds to the board origin instead of centering them.
        .frame(width: 328, height: 328, alignment: .topLeading)
        .contentShape(Rectangle())
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onAppear { focused = true }
        .onTapGesture { focused = true }
        .gesture(DragGesture(minimumDistance: 20).onEnded { drag in
            let horizontal = drag.translation.width
            let vertical = drag.translation.height
            model.move(abs(horizontal) > abs(vertical)
                       ? (horizontal > 0 ? .right : .left)
                       : (vertical > 0 ? .down : .up))
        })
    }
}
