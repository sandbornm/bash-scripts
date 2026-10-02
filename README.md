# Mac mini setup

Bootstrap a fresh Mac mini development environment with `setup.sh`.

## Included

| Tool | Installation / purpose |
| --- | --- |
| Homebrew | Native Apple Silicon or Intel installation |
| Tailscale | Homebrew CLI and system daemon for remote access |
| GitHub CLI (`gh`) | GitHub authentication and repository workflows |
| OpenJDK 21 | Existing Java baseline |
| Python 3.12 | Existing Python baseline; use `uv` for other project versions |
| `uv` / `uvx` | Python environments, dependencies, and isolated CLI tools |
| Node.js 24 / npm | Existing Node baseline |
| Rust / Cargo | Stable toolchain through `rustup`, plus rustfmt and clippy |
| `ripgrep` | Fast source search (`rg`) |
| `tmux` | Persistent terminal sessions for remote work |
| `jq` | JSON processing for APIs and cloud CLIs |
| ShellCheck | Static checks for shell scripts |
| Colima + Docker CLI | Local container runtime and client |
| Google Cloud CLI | Homebrew `gcloud-cli` cask |
| Oh My Pi (`omp`) | Upstream Homebrew formula `can1357/tap/omp` |
| Codex | Homebrew cask |
| Claude Code | Official native installer |
| Oh My Zsh | Default theme on a fresh install; existing shell settings preserved |
| Grok Bot | Separate desktop app; manual download and sign-in described below |

Cursor's old install step has been removed. Existing Cursor installations are not uninstalled.

## Run on the new Mac

1. Complete macOS setup using your development Apple Account and install available macOS updates. Run the script from the local macOS account you will use for development; it needs administrator access. The Apple Account does not sign you into GitHub, Google Cloud, Tailscale, or the coding tools.
2. Run `xcode-select --install` and finish the Command Line Tools installer. The setup script checks for these tools and exits with instructions if they are missing.
3. If you changed these scripts on another Mac, commit and push those changes first. Then clone this public repository and run as your normal user:

```bash
mkdir -p "$HOME/Github" && \
  cd "$HOME/Github" && \
  git clone https://github.com/sandbornm/bash-scripts.git && \
  cd bash-scripts && \
  caffeinate -i /bin/bash setup.sh
```

`caffeinate` prevents idle system sleep while setup runs. The script requests `sudo` for system settings and the Tailscale daemon; enter your local Mac login password. On Apple Silicon, use a native terminal, not a terminal running under Rosetta.

By default, the Mac stays awake, its display sleeps after 10 minutes, and Wake on LAN is enabled. To leave power settings alone:

```bash
CONFIGURE_POWER=0 bash setup.sh
```

Rerunning reuses installations, updates Homebrew metadata and the stable Rust toolchain, and keeps the generated shell source lines from duplicating. Homebrew may upgrade formulae during installation; this is a bootstrap script, not a version lockfile or a complete update manager. It preserves the existing Node 24, Python 3.12, and Java 21 major versions.

Shell paths live in `~/.config/mac-mini-setup/env.sh`, sourced from `.zprofile` and `.zshrc` (respecting `ZDOTDIR`). This adds `~/.local/bin` for Claude and uv tools, the Cargo bin directory, the Google Cloud component directory, and the selected runtime paths. The generated file is replaced on reruns; keep personal configuration in your shell files. If you already had a custom `.zshrc`, enable Oh My Zsh there yourself if desired.

## After running

```bash
exec zsh -l
sudo "$(brew --prefix)/bin/tailscale" up
gh auth login
gcloud init
# For local programs that use Google Cloud client libraries:
gcloud auth application-default login

# Open each tool and complete its sign-in/provider setup:
codex
claude
omp

# Check the installation:
node --version
python3 --version
java -version
rustc --version
cargo --version
uv --version
gcloud version
omp --version
tmux -V
jq --version
shellcheck --version
colima version
docker --version
```

Google Cloud CLI manages its own Python dependency through Homebrew. It can coexist with the Python 3.12 project baseline. Install other project runtimes with `uv python install <version>` and select them in the project with `uv python pin <version>`.

The Tailscale CLI daemon can start at boot, but its macOS behavior differs from the GUI app, including DNS setup. Check [Tailscale's macOS variants](https://tailscale.com/docs/concepts/macos-variants) if you need MagicDNS.

### Containers with Colima

The script installs Colima and the Docker CLI together, following [Colima's installation guide](https://colima.run/docs/installation/). Start the virtual machine when you need containers:

```bash
colima start
docker info
```

Use `colima stop` to stop the virtual machine. To start Colima automatically at login, run `brew services start colima` as your normal user. The setup script leaves that choice to you.

### Grok Bot and Cursor

Grok Bot has its own desktop app. Its [official setup guide](https://cursor.com/docs/grok-bot/get-started) directs you to **Download Grok Bot** in the [Cursor dashboard](https://cursor.com/dashboard/bot), then to sign in with your Cursor account. The documented setup does not require installing the Cursor editor.

Install Grok Bot manually on the new Mac using that dashboard. Its download is supplied through your account, so this script prints the dashboard URL instead of assuming a public installer or Homebrew package. The app handles its own updates. Access depends on your account's eligible plan or linked SuperGrok access, as described in the setup guide.

## Useful additions to consider

These are optional and are not installed automatically. The media, frontend, cloud, and Python workflows need some setup beyond installing the base CLIs:

| Addition | Why add it? |
| --- | --- |
| [`shfmt`](https://formulae.brew.sh/formula/shfmt) | Format shell scripts alongside the included ShellCheck |
| [`pnpm`](https://formulae.brew.sh/formula/pnpm) | Install dependencies for projects with `pnpm-lock.yaml` |
| [`docker-compose`](https://formulae.brew.sh/formula/docker-compose) and [`docker-buildx`](https://formulae.brew.sh/formula/docker-buildx) | Compose projects and BuildKit builds; follow [Colima's plugin setup instructions](https://colima.run/docs/installation/#docker-cli) after installing |
| [`ffmpeg`](https://formulae.brew.sh/formula/ffmpeg) | Supplies `ffmpeg` and `ffprobe` for video clipping, metadata, audio extraction, and playback conversion |
| [Google Chrome](https://formulae.brew.sh/cask/google-chrome) | Required by render scripts that explicitly reference `/Applications/Google Chrome.app` |

For the optional media and frontend tools:

```bash
brew install ffmpeg pnpm shfmt
brew install --cask google-chrome
```

Finish these steps inside the projects that need them:

- **Python versions:** some projects pin Python 3.11 or 3.13. Run `uv python install 3.11 3.13`, then follow each project's dependency setup instructions (typically `uv sync --locked` for a committed `uv.lock`). The baseline Python 3.12 can remain installed. See [uv's Python guide](https://docs.astral.sh/uv/guides/install-python/).
- **JavaScript versions:** follow the repository's lockfile, `packageManager`, `.nvmrc`, and `.node-version`. Node 24 is the base runtime; use a Node version manager when a project requires a different version. Follow the project's lifecycle-script policy when installing dependencies.
- **Browser tests:** after installing the project's Playwright dependency, download its matching browser with `npx playwright install chromium` (or `pnpm exec playwright install chromium` in a pnpm project). A regular Chrome installation does not replace these [Playwright browser downloads](https://playwright.dev/docs/browsers).
- **Cloudflare:** use the project's installed Wrangler version and run `npx wrangler login` from that project, or `pnpm exec wrangler login` for pnpm projects. See [Wrangler setup](https://developers.cloudflare.com/workers/wrangler/install-and-update/).
- **Agent tooling:** restore the custom skills and MCP server definitions you use. Update absolute paths for the new Mac and follow each server's setup instructions. Installing the agent CLIs does not migrate this configuration or sign you into the providers.

Also finish the setup that packages cannot provide: Git author name/email, GitHub SSH keys or credential setup, Time Machine backups, and FileVault recovery-key storage. If this is a headless machine, enable Remote Login in macOS settings and test connecting through Tailscale. Plan how you will unlock FileVault after a reboot before relying on unattended access.

## Updating later

```bash
brew update
brew outdated
# Upgrade the packages you choose, for example:
brew upgrade uv can1357/tap/omp tmux jq shellcheck colima docker
brew upgrade --cask codex gcloud-cli
rustup update stable
claude update
```

Because `uv` is installed with Homebrew, update it with Homebrew rather than `uv self update`.

Installation references: [Homebrew](https://docs.brew.sh/Installation), [Rust](https://rust-lang.org/tools/install/), [Google Cloud CLI cask](https://formulae.brew.sh/cask/gcloud-cli), [Oh My Pi](https://github.com/can1357/oh-my-pi#install), [uv](https://docs.astral.sh/uv/getting-started/installation/), [Claude Code](https://code.claude.com/docs/en/setup).

## Check script changes locally

These checks do not run the installer or change your machine's settings:

```bash
/bin/bash -n setup.sh
/bin/bash -n tests/setup-smoke.sh
shellcheck -x setup.sh tests/setup-smoke.sh
/bin/bash tests/setup-smoke.sh
```

The smoke tests use temporary files and mocked system commands to check shell settings, reruns, path quoting, and preflight failures. A complete installation still needs to be verified on the new Mac.
