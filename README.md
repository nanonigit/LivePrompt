# LivePrompt

[English](README.md) | [日本語](README.ja.md)

LivePrompt is a macOS app that turns audio playing on your Mac into live English captions, Japanese translations, and suggested English questions and replies. A translucent floating prompt stays visible over meeting apps.

## Requirements

- Apple silicon Mac running macOS 26 or later
- System Audio Recording permission
- Apple Intelligence for suggested questions and replies
- An internet connection for Apple's initial language asset downloads

## Install

The Homebrew formula builds the app from source on your Mac. It does not download an unsigned app binary.

```sh
brew install nanonigit/liveprompt/liveprompt
liveprompt
```

The formula keeps `LivePrompt.app` in Homebrew's managed directory. To also show it in **Applications**, create a link to Homebrew's stable app path:

```sh
ln -s "$(brew --prefix nanonigit/liveprompt/liveprompt)/libexec/LivePrompt.app" /Applications/LivePrompt.app
```

The command refuses to overwrite an existing `/Applications/LivePrompt.app`. Homebrew upgrades continue to update the app behind this link. The link is separate from Homebrew, so remove it yourself if you uninstall LivePrompt.

To build manually with Swift 6.4 and the Xcode Command Line Tools:

```sh
./script/package_app.sh --release
open dist/LivePrompt.app
```

During development, `./script/build_and_run.sh --verify` builds a debug app, launches it, and checks that the process is running. Close LivePrompt before rebuilding it.

## Use

1. Open LivePrompt and click **Start** in the main window or from its menu bar icon.
2. On first use, allow **System Audio Recording** if macOS asks. Wait for the English speech and translation assets to finish preparing.
3. Play English audio in Zoom, Meet, Teams, a browser, or another app. English captions appear first; Japanese translations follow. Suggested English questions and replies update as the conversation progresses.
4. Drag or resize the floating prompt as needed. Click **Stop** in the main window, floating prompt, or menu bar when finished. The menu bar icon can reopen the main window after you close it.

In **Display and startup**, use the slider to set the floating prompt background transparency from 0% to 80%. Captions remain fully opaque. Turn on **Launch at login** if you want the app to open when you sign in; macOS may ask you to approve it in Login Items. Audio capture does not start automatically at login. You can also show or hide the menu bar and Dock icons separately. At least one icon must remain visible so you can reopen the control window. These display choices are saved between launches.

**Usage history (last 30 days)** shows when a recording session started and ended. Sessions are recorded only after capture starts successfully. The app stores timestamps only, automatically removes entries older than 30 days, and never saves audio, captions, or suggestions in this history. A session interrupted by a crash may have no end time.

The permission is listed in **System Settings → Privacy & Security → Screen & System Audio Recording → System Audio Recording Only**. LivePrompt uses the audio-only permission and does not capture your screen. If you granted screen recording to an earlier prototype, you may remove that old permission in System Settings.

## Privacy and limitations

- Processing uses Apple's on-device Speech, Translation, and Foundation Models. LivePrompt saves recording start and end timestamps for 30 days, but does not save recordings or transcripts to disk or send them to its own server. macOS may download language assets on first use.
- Microphone input, protected audio such as DRM content, speaker separation, and automatic meeting replies are outside the current scope.
- Suggestions are drafts. When the conversation does not support a factual answer, the app suggests a clarification instead of inventing facts or commitments. It never speaks or sends a message for you.
- On first launch after a local build, **Preparing audio and language models** can take several minutes on macOS 27 while Core Audio registers the tap. If it does not finish, quit the app, confirm its System Audio Recording permission, and reopen it. Subsequent starts were fast in local tests.

## Development and verification

The project uses SwiftPM and Apple's Core Audio taps, SpeechAnalyzer, Translation, Foundation Models, SwiftUI, and AppKit. The local test Mac is an Apple M2 running macOS 27. The release build produced captions, Japanese translations, suggestions, and successful stop/restart cycles from synthesized English playback. The initial Core Audio setup sometimes took several minutes. Real Zoom, Meet, and Teams meetings have not yet been tested.

See [requirements](requirements.md), [design](design.md), and [tasks](tasks.md) for the original app plan, and [release requirements](release-requirements.md) for distribution gates.

## License

MIT. See [LICENSE](LICENSE).
