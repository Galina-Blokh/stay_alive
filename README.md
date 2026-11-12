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

- While green, every 60 s the app nudges the mouse 1 px and clicks at the cursor position, but
  only if you haven't touched the keyboard or mouse for 50 s. This keeps chat apps such as
  Teams showing you as available. It needs **Accessibility** permission (System Settings →
  Privacy & Security → Accessibility); the app asks the first time you turn it on. Without it,
  only the screen-awake part works.
- Park the cursor somewhere harmless (e.g. an empty desktop area) since it will click there. It never clicks on its own window, so leaving the cursor on the
  power button is safe.
- Closing the window keeps the app (and its current state) running; click the Dock icon to
  bring it back.
- Quitting the app (**⌘Q**) always turns it off, so your Mac goes back to normal sleep.
- It does **not** stop sleep when you close the lid, and it doesn't block a manual lock or sleep.

## How it works

While it's on, the app holds a macOS power assertion of type
`PreventUserIdleDisplaySleep` (IOKit), the same mechanism video players use. Turning it off or
quitting releases the assertion. Nothing is changed in System Settings and nothing runs in the
background once the app quits.

A power assertion alone doesn't count as user activity, so chat apps like Teams still go
"Away" after a few minutes. To prevent that, a 60 s timer posts synthetic mouse events through
Quartz (`CGEvent`): a 1 px move and back, then a left click at the cursor. It skips the tick if
you were active in the last 50 s and does nothing without Accessibility permission. The timer
stops when you switch the button to grey or quit.

To see the assertion while it's on:

```sh
pmset -g assertions | grep "Stay Alive"
```

## Keep the Accessibility permission across rebuilds

By default `build.sh` signs the app ad hoc, and macOS ties the Accessibility permission to that
exact build: after every rebuild the switch in System Settings still looks on but no longer
applies. Create a local signing certificate once and `build.sh` will use it automatically:

```sh
# Runs in a temporary folder inside a subshell, so your current directory is unchanged.
# Uses macOS's built-in /usr/bin/openssl, whose .p12 format Keychain imports directly.
(
cd "$(mktemp -d)" || exit 1
cat > stayalive-cert.cnf <<'CNF'
[req]
distinguished_name=dn
x509_extensions=ext
prompt=no
[dn]
CN=Stay Alive Local Signing
[ext]
basicConstraints=critical,CA:false
keyUsage=critical,digitalSignature
extendedKeyUsage=critical,codeSigning
CNF
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -keyout k.pem -out c.pem -days 3650 -config stayalive-cert.cnf &&
/usr/bin/openssl pkcs12 -export -inkey k.pem -in c.pem -out id.p12 -passout pass:stayalive &&
security import id.p12 -k ~/Library/Keychains/login.keychain-db -P stayalive -T /usr/bin/codesign
rm -f k.pem c.pem id.p12 stayalive-cert.cnf
)
```

Then run `./build.sh`, remove every "Stay Alive" entry under Privacy & Security →
Accessibility, add `~/Applications/Stay Alive.app` again and switch it on. (The **+** picker
opens the main Applications folder; press ⌘⇧G and paste `~/Applications/Stay Alive.app`.)
The first build asks to let `codesign` use the key; choose **Always Allow**. From then on
rebuilds keep the permission.

## Uninstall

Quit the app and delete `~/Applications/Stay Alive.app`.

## Project files

| File | Purpose |
|---|---|
| `StayAlive.swift` | The whole app (SwiftUI window, power assertion, mouse nudge + click) |
| `make_icon.swift` | Draws the 1024 px app icon |
| `build.sh` | Builds, signs and installs the app |
