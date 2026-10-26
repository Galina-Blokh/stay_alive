# Stay Alive

A tiny macOS app that keeps your screen awake. Click the big power button: green means the
screen stays on, grey means your Mac sleeps as usual.

Handy for long video calls, presentations, downloads or anything else where the screen
shouldn't dim or lock while you're not touching the keyboard.

## Requirements

- macOS 13 (Ventura) or later
- Swift compiler: Xcode or the Command Line Tools (`xcode-select --install`)

## Installation

```sh
git clone https://github.com/Galina-Blokh/stay_alive.git
cd stay_alive
./build.sh
```

`build.sh` compiles the app, generates its icon, signs it locally and installs it to
`~/Applications/Stay Alive.app`.

Open it from Finder (`~/Applications`), Spotlight or Launchpad. To keep it handy, right-click
its Dock icon while it runs and choose **Options → Keep in Dock**. Re-running `build.sh` updates
the app in place, so the Dock pin keeps working.

## Usage

| Button | Status text | What happens |
|---|---|---|
| Green | Screen stays on | The display won't dim or sleep from inactivity |
| Grey | Off — normal sleep | Your normal Energy / Lock Screen settings apply |

- Closing the window keeps the app (and its current state) running; click the Dock icon to
  bring it back.
- Quitting the app (**⌘Q**) always turns it off, so your Mac goes back to normal sleep.
- It does **not** stop sleep when you close the lid, and it doesn't block a manual lock or sleep.

## How it works

While it's on, the app holds a macOS power assertion of type
`PreventUserIdleDisplaySleep` (IOKit), the same mechanism video players use. Turning it off or
quitting releases the assertion. Nothing is changed in System Settings and nothing runs in the
background once the app quits.

To see the assertion while it's on:

```sh
pmset -g assertions | grep "Stay Alive"
```

## Uninstall

Quit the app and delete `~/Applications/Stay Alive.app`.

## Project files

| File | Purpose |
|---|---|
| `StayAlive.swift` | The whole app (SwiftUI window + power assertion) |
| `make_icon.swift` | Draws the 1024 px app icon |
| `build.sh` | Builds, signs and installs the app |
