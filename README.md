# mouse-reverser

A minimal macOS background service that reverses **mouse** scroll direction
while leaving the trackpad untouched.

Derived from [Scroll Reverser](https://github.com/pilotmoon/Scroll-Reverser)
by Nicholas Moore, same license.

## Requirements

macOS with Xcode Command Line Tools (`swift --version` to check;
`xcode-select --install` if missing). No third-party dependencies.

## Install

```sh
git clone https://github.com/FishfishCai/mouse-reverser.git
cd mouse-reverser
./build.sh
./mouse-reverser
```

The first run fails because Accessibility permission hasn't been granted.
Open **System Settings → Privacy & Security → Accessibility**, add
`./mouse-reverser`, toggle it on, then re-run. The binary self-installs a
LaunchAgent plist; from the next login onward `launchd` starts the service
automatically. To start it under `launchd` immediately:

```sh
launchctl load ~/Library/LaunchAgents/local.mouse-reverser.plist
```

## Uninstall

```sh
launchctl unload ~/Library/LaunchAgents/local.mouse-reverser.plist
rm ~/Library/LaunchAgents/local.mouse-reverser.plist
```

Remove the entry from System Settings → Privacy & Security → Accessibility.

## License

[Apache 2.0](./LICENSE). See [NOTICE](./NOTICE) for attribution.
