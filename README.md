# 2048 for macOS

A native SwiftUI app with a compact calculator-inspired window and the classic 2048 palette. Requires macOS 14 or later and Xcode 15 or later.

## Open in Xcode

Open **Classic2048.xcodeproj**, select the **Classic2048** scheme and **My Mac**, then press **Command-R**. Press **Command-U** to run unit tests.

The checked-in Xcode project is ready to use; XcodeGen is not required to open or build it.

## Project structure

- `Classic2048.xcodeproj`: standard Xcode project with a shared application scheme.
- `Sources/Classic2048`: SwiftUI macOS application target.
- `Sources/GameCore`: framework target containing independent game rules.
- `Tests/GameCoreTests`: XCTest target for game rules and save validation.
- `Info.plist`: application metadata, using Xcode build settings for identifiers and versions.
- `project.yml`: reproducible XcodeGen project specification.
- `build-app.sh`: Release build through xcodebuild, exporting `build/2048.app`.
- `Package.swift`: optional Swift Package entry point for `swift test` and `swift run`; uses the same source files.

Debug and Release configurations are included. The app embeds GameCore.framework. The bundle identifier remains `local.classic2048.mac`, preserving existing native saves.

## Command-line build

```sh
cd macOS
bash build-app.sh
open build/2048.app
```

## Command-line tests

```sh
xcodebuild test \
  -project Classic2048.xcodeproj \
  -scheme Classic2048 \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData
```

Alternatively, run `swift test` for the rules without the Xcode app build.

## Project maintenance

Add ordinary source files through Xcode. If maintaining the project through `project.yml` instead, regenerate it with XcodeGen:

```sh
xcodegen generate
```

The generated `.xcodeproj` and shared scheme belong in source control. Build products, DerivedData, Swift Package caches and personal Xcode state are ignored.

## Controls and persistence

- Arrow keys or WASD: move tiles.
- Mouse or trackpad drag: move tiles.
- New Game or Command-N: restart.
- Keep Playing: continue after reaching 2048.

Progress and the best score save in UserDefaults. Web and native saves are separate. Closing the single game window quits the app.

Local builds use ad-hoc signing without an Apple Developer account. For distribution, select your development team and configure Developer ID signing and notarization.
