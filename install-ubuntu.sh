#!/usr/bin/env bash
# One-shot productivity setup for a fresh Ubuntu (24.04+, x86_64).
# Idempotent — safe to re-run to pick up new tool versions.
# Usage: ./install-ubuntu.sh [--server]   (--server skips desktop extras)
set -u
cd "$(dirname "$(readlink -f "$0")")"

SERVER=0
[[ "${1:-}" == "--server" ]] && SERVER=1

export PATH="$HOME/.local/bin:$PATH"
mkdir -p ~/.local/bin
SUDO=; [[ $EUID != 0 ]] && SUDO=sudo
FAILED=""

log()  { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
ok()   { echo "  + $1"; }
fail() { echo "  ! $1 — install it manually"; FAILED="$FAILED $1"; }

# Resolve the download URL of the newest release asset matching a regex.
asset_url() { # owner/repo regex [latest|tag]
  curl -fsSL "https://api.github.com/repos/$1/releases/$3" \
    | grep -oP '"browser_download_url":\s*"\K[^"]+' | grep -iP "$2" | head -1
}
latest_tag() { curl -fsSL "https://api.github.com/repos/$1/releases/latest" | grep -oP '"tag_name":\s*"\K[^"]+'; }

# Download an asset (deb/tar.gz/tar.xz/raw binary) and drop the named
# executable into ~/.local/bin. Deb files are extracted, never dpkg'd,
# so deb12 vs deb16 packaging can't break the script.
fetch_bin() { # owner/repo regex name [post-hook]
  local url tmp bin
  url=$(asset_url "$1" "$2" latest)
  [[ -z $url ]] && { fail "$3 ($1 has no match for '$2')"; return; }
  tmp=$(mktemp -d)
  if ! curl -sfL "$url" -o "$tmp/pkg"; then fail "$3 (download)"; rm -rf "$tmp"; return; fi
  case $url in
    *.deb)    (cd "$tmp" && ar x pkg) && tar -f "$tmp"/data.tar.* -C "$tmp" -x ;;
    *.tar.gz|*.tgz) tar xf "$tmp/pkg" -C "$tmp" ;;
    *.tar.xz) tar xf "$tmp/pkg" -C "$tmp" ;;
    *)        mv "$tmp/pkg" "$tmp/$3" ;;
  esac
  bin=$(find "$tmp" -type f -name "$3" ! -name '*.deb' ! -path '*/man/*' | head -1)
  if [[ -n $bin ]]; then
    install -m 0755 "$bin" ~/.local/bin/"$3"
    [[ -n ${4:-} ]] && "$4" "$tmp"
    ok "$3 ($(basename "$url"))"
  else
    fail "$3 (binary not found in archive)"
  fi
  rm -rf "$tmp"
}

nvim_runtime() { # post-hook: ship the runtime dir alongside the binary
  local tree
  tree=$(find "$1" -maxdepth 2 -type d -name 'nvim-*' | head -1)
  [[ -d $tree/share/nvim ]] && { mkdir -p ~/.local/share; cp -a "$tree/share/nvim" ~/.local/share/; cp -a "$tree/share/man" ~/.local/share/ 2>/dev/null; }
}

log "[1/6] Apt packages (system-level tools where apt is fine)"
$SUDO apt-get update || fail "apt update"
$SUDO apt-get install -y \
  git curl wget unzip xz-utils zstd \
  tmux fzf ripgrep bat fd-find ncurses-term jq btop \
  fonts-noto-color-emoji || fail "apt core batch"
if [[ $SERVER == 0 ]]; then
  $SUDO apt-get install -y \
    gnome-tweaks gnome-shell-extension-manager copyq timeshift || fail "apt desktop batch"
fi

log "[2/6] GitHub CLI (official apt repo)"
if command -v gh >/dev/null 2>&1; then
  ok "gh (already installed)"
else
  $SUDO install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | $SUDO tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | $SUDO tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
    && $SUDO apt-get update -qq && $SUDO apt-get install -y gh && ok "gh" || fail "gh"
fi

log "[3/6] Official installer scripts (they pin their own latest releases)"
command -v starship >/dev/null 2>&1 || curl -sS https://starship.rs/install.sh | sh -s -- -y || fail starship
command -v zoxide   >/dev/null 2>&1 || curl -Ss https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash || fail zoxide
command -v uv       >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh || fail uv
command -v mise     >/dev/null 2>&1 || curl https://mise.run | sh || fail mise

log "[4/6] Latest GitHub release binaries into ~/.local/bin"
fetch_bin tldr-pages/tlrc        'x86_64.*linux-musl.*\.tar\.gz$'                tldr
fetch_bin atuinsh/atuin          'atuin-x86_64.*linux-musl.*\.tar\.gz$'          atuin
fetch_bin eza-community/eza      'eza_x86_64-unknown-linux-musl\.tar\.gz$'       eza
fetch_bin dandavison/delta       "git-delta_.*x86_64\.deb$|git-delta_.*amd64\.deb$" delta
fetch_bin neovim/neovim          'nvim-linux-x86_64\.tar\.gz$'                   nvim nvim_runtime
fetch_bin jesseduffield/lazygit  'lazygit_.*linux_x86_64\.tar\.gz$'              lazygit
fetch_bin mikefarah/yq           'yq_linux_amd64$'                               yq

log "[5/6] Nerd font (starship/eza icons) and shell hooks"
if [[ $SERVER == 0 ]] && ! fc-list | grep -qi 'JetBrainsMono.*[Nn]erd'; then
  if curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o /tmp/jbm.zip; then
    mkdir -p ~/.local/share/fonts && unzip -oq /tmp/jbm.zip -d ~/.local/share/fonts/ \
      && fc-cache -f >/dev/null && rm /tmp/jbm.zip && ok "JetBrainsMono Nerd Font"
  else
    fail "nerd font download"
  fi
fi

log "[6/6] Dotfiles (backup + symlink bash/tmux/starship configs)"
./install-shell.sh --no-deps

echo
if [[ -n $FAILED ]]; then
  echo "Finished with failures:$FAILED"
  echo "Re-run ./install-ubuntu.sh after fixing network/GitHub rate limits."
else
  echo "All done. Log out and back in (or: source ~/.bashrc), then:"
  echo "  gh auth login        # GitHub CLI"
  echo "  atuin import bash    # import existing history, once"
  [[ $SERVER == 0 ]] && echo "  See docs/UBUNTU-SETUP.md for the manual post-install steps."
fi
