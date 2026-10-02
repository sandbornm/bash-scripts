#!/usr/bin/env bash
set -euo pipefail

# Exercises shell configuration and preflight without running any installers.
TEST_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../setup.sh
source "$TEST_REPO_DIR/setup.sh"
TEST_TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mac-mini-tests.XXXXXX")"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

test_shell_configuration() {
  local fixture="$TEST_TMP_DIR/shell configuration"
  local user_dir="$fixture/user" shell_dir="$fixture/zsh"
  local prefix="$fixture/brew prefix"
  mkdir -p "$shell_dir" "$prefix/bin"
  printf 'alias keepme="echo personal setting"\n' >"$shell_dir/.zshrc"
  cat >"$prefix/bin/brew" <<'EOF'
#!/bin/sh
[ "$1" = shellenv ] || exit 1
# Emit nothing: tests only need a successful, harmless shellenv command.
EOF
  chmod +x "$prefix/bin/brew"

  configure_shell "$user_dir" "$shell_dir" "$prefix/bin/brew" "$prefix"
  cp "$shell_dir/.zshrc" "$fixture/first.zshrc"
  cp "$shell_dir/.zprofile" "$fixture/first.zprofile"
  cp "$user_dir/.config/mac-mini-setup/env.sh" "$fixture/first.env"
  configure_shell "$user_dir" "$shell_dir" "$prefix/bin/brew" "$prefix"

  cmp "$fixture/first.zshrc" "$shell_dir/.zshrc" || fail "Rerun duplicated .zshrc configuration"
  cmp "$fixture/first.zprofile" "$shell_dir/.zprofile" || fail "Rerun duplicated .zprofile configuration"
  cmp "$fixture/first.env" "$user_dir/.config/mac-mini-setup/env.sh" || fail "Generated environment changed on rerun"
  grep -Fqx 'alias keepme="echo personal setting"' "$shell_dir/.zshrc" || fail "Personal setting was changed"
  [[ ! -e "$user_dir/.zshrc" ]] || fail "Custom shell directory was ignored"

  /bin/bash -n "$user_dir/.config/mac-mini-setup/env.sh"
  /bin/zsh -n "$user_dir/.config/mac-mini-setup/env.sh"
  local test_shell
  for test_shell in /bin/bash /bin/zsh; do
    # Expand inside the child shell, not while constructing its program.
    # shellcheck disable=SC2016
    "$test_shell" -f -c '
      set -eu
      . "$1"
      [ "$JAVA_HOME" = "$2/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home" ]
      case ":$PATH:" in *":$JAVA_HOME/bin:"*) ;; *) exit 1 ;; esac
      case ":$PATH:" in *":$2/opt/node@24/bin:"*) ;; *) exit 1 ;; esac
      case ":$PATH:" in *":$2/opt/python@3.12/libexec/bin:"*) ;; *) exit 1 ;; esac
      case ":$PATH:" in *":$2/share/google-cloud-sdk/bin:"*) ;; *) exit 1 ;; esac
      case ":$PATH:" in *":${CARGO_HOME:-$HOME/.cargo}/bin:"*) ;; *) exit 1 ;; esac
      case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) exit 1 ;; esac
    ' test "$user_dir/.config/mac-mini-setup/env.sh" "$prefix" || fail "Environment failed in $test_shell"
  done
  printf 'PASS: existing settings, custom shell directory, reruns, and Bash/zsh paths\n'
}

# These command overrides are called indirectly by setup.sh's preflight.
# shellcheck disable=SC2329
test_preflight() {
  local output="$TEST_TMP_DIR/preflight.log"
  if (
    uname() { printf 'Linux\n'; }
    preflight
  ) >"$output" 2>&1; then
    fail "Accepted a non-macOS host"
  fi
  grep -q 'requires macOS' "$output" || fail "Missing macOS error"

  # EUID is readonly; these tests should run as a normal macOS user.
  if [[ "$EUID" -eq 0 ]]; then
    printf 'SKIP: normal-user preflight tests (running as root)\n'
    return
  fi

  if (
    uname() { printf 'Darwin\n'; }
    sysctl() { printf '1\n'; }
    preflight
  ) >"$output" 2>&1; then
    fail "Accepted a Rosetta shell"
  fi
  grep -q 'Rosetta' "$output" || fail "Missing Rosetta error"

  if (
    uname() { printf 'Darwin\n'; }
    sysctl() { printf '0\n'; }
    CONFIGURE_POWER=invalid
    preflight
  ) >"$output" 2>&1; then
    fail "Accepted an invalid power option"
  fi
  grep -q 'CONFIGURE_POWER must be' "$output" || fail "Missing option error"

  if (
    uname() { printf 'Darwin\n'; }
    sysctl() { printf '0\n'; }
    CONFIGURE_POWER=0
    xcode-select() { [[ "$1" == --install ]] && printf 'Mock installer requested\n'; }
    xcrun() { return 1; }
    preflight
  ) >"$output" 2>&1; then
    fail "Accepted missing developer tools"
  fi
  grep -q 'Mock installer requested' "$output" || fail "Developer tools installer was not requested"
  grep -q 'Finish installing' "$output" || fail "Missing developer tools guidance"

  (
    uname() { printf 'Darwin\n'; }
    sysctl() { printf '0\n'; }
    CONFIGURE_POWER=0
    xcode-select() { [[ "$1" == -p ]]; }
    xcrun() { return 0; }
    preflight
  ) || fail "Rejected a supported host"
  printf 'PASS: platform, Rosetta, power option, and developer tools preflight\n'
}

test_shell_configuration
test_preflight
