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
foreground and reverses mouse scroll until you quit it (Ctrl-C).

## Start/stop toggle command

The compiled binary lives in the repo; the convenient way to run it is a small
toggle — run `reverser` to start the background process, run `reverser` again
to stop it. Save the script below into **any directory on your `$PATH`** (e.g.
`~/.local/bin`, `/usr/local/bin`, or your own bin dir), name it `reverser`,
`chmod +x` it, and point `DIR` at wherever you built the binary:

```sh
#!/bin/sh
# reverser toggle: running -> stop, stopped -> start.
DIR="$HOME/Documents/app/reverser"      # adjust to your build directory
PIDFILE="$DIR/.reverser.pid"

running() {
    [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null && return 0
    pgrep -x reverser >/dev/null 2>&1
}

if running; then
    [ -f "$PIDFILE" ] && { kill -9 "$(cat "$PIDFILE")" 2>/dev/null; rm -f "$PIDFILE"; }
    pkill -9 -x reverser 2>/dev/null
    echo "reverser stopped"
    exit 0
fi

# stopped -> start: clear any stale state first
if [ -f "$PIDFILE" ]; then
    kill -9 "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
fi
pkill -9 -x reverser 2>/dev/null
sleep 1

"$DIR/reverser" > /tmp/reverser.log 2>&1 &
echo $! > "$PIDFILE"

sleep 1
if ! kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "reverser failed to start (see /tmp/reverser.log)"
    exit 1
fi
echo "reverser started (PID $(cat "$PIDFILE"))"
```

If that bin dir isn't on your `PATH` yet (zsh is the default macOS shell):

```sh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

## Uninstall

Quit the process, then remove the entry from
System Settings → Privacy & Security → Accessibility.

## License

[Apache 2.0](./LICENSE). See [NOTICE](./NOTICE) for attribution.
