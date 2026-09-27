#!/usr/bin/env bash
# Install the shell/tmux/starship dotfiles. Idempotent; run on any machine.
# Usage: ./install-shell.sh [--no-deps] [--no-tmux]
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

DEPS=1
WITH_TMUX=1
for arg in "$@"; do
  case $arg in
    --no-deps) DEPS=0 ;;
    --no-tmux) WITH_TMUX=0 ;;
  esac
done

if [[ $DEPS == 1 ]] && command -v apt-get >/dev/null 2>&1; then
  echo "==> Installing Ubuntu dependencies..."
  deps=(tmux fzf ripgrep bat fd-find ncurses-term curl git)
  [[ $WITH_TMUX == 0 ]] && deps=(fzf ripgrep bat fd-find ncurses-term curl git)
  sudo apt-get update
  sudo apt-get install -y "${deps[@]}"

  if ! command -v eza >/dev/null 2>&1; then
    echo "==> Installing eza (not in Ubuntu repos)..."
    url=$(curl -fsSL https://api.github.com/repos/eza-community/eza/releases/latest \
      | grep -oP '"browser_download_url":\s*"\K[^"]+' \
      | grep -i "eza_$(uname -m)-unknown-linux-musl\.tar\.gz$" | head -1)
    if [[ -n $url ]] && curl -fL "$url" -o /tmp/eza.tgz; then
      mkdir -p ~/.local/bin && tar xzf /tmp/eza.tgz -C /tmp eza \
        && install -m 0755 /tmp/eza ~/.local/bin/eza && rm /tmp/eza /tmp/eza.tgz
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
[[ $WITH_TMUX == 1 ]] && link .config/tmux/tmux.conf
link .config/starship.toml
link .config/nvim
link .config/ghostty
link .config/xdg-terminals.list

echo "Done. Reload your shell (or log out/in) and restart tmux."
