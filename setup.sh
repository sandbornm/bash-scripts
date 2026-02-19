#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Mac Mini Setup Script
# Run on a fresh macOS install to configure dev environment
# =============================================================================

info()    { echo "[INFO]  $*"; }
success() { echo "[OK]    $*"; }
warn()    { echo "[WARN]  $*"; }
die()     { echo "[ERROR] $*" >&2; exit 1; }

# -----------------------------------------------------------------------------
# 1. Power / display settings
# -----------------------------------------------------------------------------
info "Applying power management settings..."
sudo pmset -a sleep 0
sudo pmset -a disksleep 0
sudo pmset -a displaysleep 0
sudo pmset -a womp 1
success "Power settings applied (no sleep, wake-on-LAN enabled)"

# -----------------------------------------------------------------------------
# 2. Homebrew
# -----------------------------------------------------------------------------
if command -v brew &>/dev/null; then
  info "Homebrew already installed, updating..."
  brew update
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to PATH for Apple Silicon
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    # Persist for future shells
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  fi
fi
success "Homebrew ready"

# -----------------------------------------------------------------------------
# 3. Homebrew packages
# -----------------------------------------------------------------------------
BREW_PACKAGES=(
  tailscale
  gh
  openjdk@21
  python@3.12
  uv
  ripgrep
  node@24
  codex
)

info "Installing Homebrew packages: ${BREW_PACKAGES[*]}"
brew install "${BREW_PACKAGES[@]}"

# node@24 and openjdk@21 are keg-only; link them
brew link --force --overwrite node@24    || true
brew link --force --overwrite openjdk@21 || true

success "Homebrew packages installed"

# Tailscale service
info "Starting Tailscale service..."
sudo brew services start tailscale || warn "Could not start Tailscale service automatically"
info "Run 'sudo tailscale up' to authenticate Tailscale"

# -----------------------------------------------------------------------------
# 4. Oh My Zsh
# -----------------------------------------------------------------------------
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  info "Oh My Zsh already installed"
else
  info "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Set theme to 'robbyrussell' (default, clean and minimal)
ZSHRC="$HOME/.zshrc"
if grep -q '^ZSH_THEME=' "$ZSHRC" 2>/dev/null; then
  sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="robbyrussell"/' "$ZSHRC"
else
  echo 'ZSH_THEME="robbyrussell"' >> "$ZSHRC"
fi
success "Oh My Zsh configured with robbyrussell theme"

# Ensure brew PATH is in .zshrc as well
if ! grep -q 'homebrew/bin/brew shellenv' "$ZSHRC" 2>/dev/null; then
  cat >> "$ZSHRC" <<'EOF'

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# node@24 (keg-only)
export PATH="/opt/homebrew/opt/node@24/bin:$PATH"

# openjdk@21 (keg-only)
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
EOF
fi

# -----------------------------------------------------------------------------
# 5. Claude Code
# -----------------------------------------------------------------------------
if command -v claude &>/dev/null; then
  info "Claude Code already installed"
else
  info "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
fi
success "Claude Code ready"

# -----------------------------------------------------------------------------
# 6. Cursor
# -----------------------------------------------------------------------------
if [[ -d "/Applications/Cursor.app" ]]; then
  info "Cursor already installed"
else
  info "Installing Cursor..."
  curl https://cursor.com/install -fsS | bash
fi
success "Cursor ready"

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo ""
echo "=============================================="
echo " Setup complete!"
echo "=============================================="
echo ""
echo "Next steps:"
echo "  1. Authenticate Tailscale:   sudo tailscale up"
echo "  2. Reload your shell:        exec zsh"
echo "  3. Verify Java:              java -version"
echo "  4. Verify Node:              node --version"
echo "  5. Verify Python:            python3 --version"
echo "  6. Sign in to Cursor:        open /Applications/Cursor.app"
echo ""
