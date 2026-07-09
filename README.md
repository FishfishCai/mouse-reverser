# reverser

A minimal macOS tool that reverses **mouse** scroll direction while leaving
the trackpad untouched.

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
./reverser
```

The first run fails because Accessibility permission hasn't been granted.
Open **System Settings → Privacy & Security → Accessibility**, add
`./reverser`, toggle it on, then re-run. `reverser` then runs in the
foreground and reverses mouse scroll until you quit it (Ctrl-C); background
it with `./reverser &` if you want it to keep running.

## Uninstall

Quit the process, then remove the entry from
System Settings → Privacy & Security → Accessibility.

## License

[Apache 2.0](./LICENSE). See [NOTICE](./NOTICE) for attribution.
