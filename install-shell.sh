#!/usr/bin/env bash
# Install the shell/tmux/starship dotfiles. Idempotent; run on any machine.
# Usage: ./install-shell.sh [--no-deps]
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

DEPS=1
[[ "${1:-}" == "--no-deps" ]] && DEPS=0

if [[ $DEPS == 1 ]] && command -v apt-get >/dev/null 2>&1; then
  echo "==> Installing Ubuntu dependencies..."
  sudo apt-get update
  sudo apt-get install -y tmux fzf ripgrep bat fd-find ncurses-term curl git

  if ! command -v eza >/dev/null 2>&1; then
    echo "==> Installing eza (not in Ubuntu repos)..."
    arch=$(dpkg --print-architecture)
    ver=$(curl -fsSL https://api.github.com/repos/eza-community/eza/releases/latest \
      | grep -oP '"tag_name":\s*"v\K[0-9.]+')
    if curl -fL "https://github.com/eza-community/eza/releases/download/v${ver}/eza_${ver}_${arch}.deb" -o /tmp/eza.deb; then
      sudo dpkg -i /tmp/eza.deb && rm /tmp/eza.deb
    else
      echo "!! eza install failed; l/ll aliases will be skipped."
    fi
  fi

  if ! command -v starship >/dev/null 2>&1; then
    echo "==> Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
fi

link() {
  local src=$PWD/$1 dst=$HOME/$1
  [[ -e $src ]] || { echo "!! $1 not in repo, skipping"; return; }
  mkdir -p "$(dirname "$dst")"
  if [[ -e $dst && ! -L $dst ]]; then
    cp -a "$dst" "$dst.bak-$(date +%Y%m%d%H%M%S)"
    echo "   backed up existing $1"
  fi
  ln -sfn "$src" "$dst"
  echo "==> linked ~/$1 -> dotfiles/$1"
}

link .bashrc
link .bash_profile
link .config/tmux/tmux.conf
link .config/starship.toml

echo "Done. Reload your shell (or log out/in) and restart tmux."
