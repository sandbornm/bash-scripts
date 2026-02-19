# mac-mini-scripts

Setup scripts for a fresh Mac Mini dev environment.

## What `setup.sh` does

1. **Power settings** — disables sleep, enables Wake on LAN (`womp`)
2. **Homebrew** — installs and updates
3. **Packages** — Tailscale, OpenJDK 21, Python 3.12, uv, ripgrep, Node 24, Codex
4. **Oh My Zsh** — installs with `robbyrussell` theme
5. **Claude Code** — installs via official installer
6. **Cursor** — installs via official installer

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/<your-username>/mac-mini-scripts/main/setup.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/<your-username>/mac-mini-scripts.git
cd mac-mini-scripts
bash setup.sh
```

## After running

```bash
sudo tailscale up   # authenticate Tailscale
exec zsh            # reload shell
```
