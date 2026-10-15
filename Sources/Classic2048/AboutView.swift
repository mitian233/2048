import SwiftUI
import AppKit

struct AboutCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About 2048") {
                openWindow(id: "about")
            }
        }
    }
}

struct AboutView: View {
    private var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)

            VStack(spacing: 5) {
                Text("2048")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text(version)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Text("A classic number puzzle, made for Mac.")
                .font(.system(size: 13))
                .multilineTextAlignment(.center)

            Divider()

            Text("Inspired by Gabriele Cirulli’s 2048.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(width: 320)
        .foregroundStyle(Palette.ink)
        .background(Palette.paper)
        .preferredColorScheme(.light)
    }
}
