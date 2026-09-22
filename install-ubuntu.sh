#!/usr/bin/env bash
# One-shot productivity setup for a fresh Ubuntu (24.04+, tested on 26.04 LTS, x86_64).
# Idempotent — safe to re-run to pick up new tool versions.
# Usage: ./install-ubuntu.sh [--server] [--docker]
#   --server  skips desktop/VM extras
#   --docker  installs Docker Engine from the official repo + adds you to the docker group
set -u
cd "$(dirname "$(readlink -f "$0")")"

SERVER=0
WITH_DOCKER=0
for arg in "$@"; do
  case $arg in
    --server) SERVER=1 ;;
    --docker) WITH_DOCKER=1 ;;
  esac
done

export PATH="$HOME/.local/bin:$PATH"
mkdir -p ~/.local/bin
SUDO=; [[ $EUID != 0 ]] && SUDO=sudo
FAILED=""
NEED_REBOOT=0

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

log "[1/12] Apt packages (system-level tools where apt is fine)"
$SUDO apt-get update || fail "apt update"
$SUDO apt-get install -y \
  git curl wget unzip xz-utils zstd \
  tmux fzf ripgrep bat fd-find ncurses-term jq btop \
  build-essential cmake pkg-config ccache ninja-build \
  clang clangd clang-tools gdb lldb valgrind cppcheck \
  python3-dev python3-venv ubuntu-drivers-common \
  fonts-noto-color-emoji || fail "apt core batch"
if [[ $SERVER == 0 ]]; then
  $SUDO apt-get install -y \
    gnome-tweaks gnome-shell-extension-manager copyq timeshift \
    qemu-kvm libvirt-daemon-system libvirt-clients virt-manager \
    cpu-checker wl-clipboard \
    ghostty || fail "apt desktop batch"
  $SUDO usermod -aG libvirt "$USER" 2>/dev/null || true
  # Make Ghostty the default terminal (GNOME + x-terminal-emulator)
  if command -v ghostty >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.default-app terminal.exec 'ghostty' 2>/dev/null \
      && ok "GNOME default terminal -> ghostty" || true
    $SUDO update-alternatives --set x-terminal-emulator "$(command -v ghostty)" 2>/dev/null \
      || $SUDO update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$(command -v ghostty)" 50 2>/dev/null \
      || true
    ok "x-terminal-emulator -> ghostty"
  fi
fi

log "[2/12] GitHub CLI (official apt repo)"
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

log "[3/12] Official installer scripts (they pin their own latest releases)"
command -v starship >/dev/null 2>&1 || curl -sS https://starship.rs/install.sh | sh -s -- -y || fail starship
command -v zoxide   >/dev/null 2>&1 || curl -Ss https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash || fail zoxide
command -v uv       >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh || fail uv
command -v mise     >/dev/null 2>&1 || curl https://mise.run | sh || fail mise

log "[4/12] Latest GitHub release binaries into ~/.local/bin"
fetch_bin tldr-pages/tlrc        'x86_64.*linux-musl.*\.tar\.gz$'                tldr
fetch_bin atuinsh/atuin          'atuin-x86_64.*linux-musl.*\.tar\.gz$'          atuin
fetch_bin eza-community/eza      'eza_x86_64-unknown-linux-musl\.tar\.gz$'       eza
fetch_bin dandavison/delta       "git-delta_.*x86_64\.deb$|git-delta_.*amd64\.deb$" delta
fetch_bin neovim/neovim          'nvim-linux-x86_64\.tar\.gz$'                   nvim nvim_runtime
fetch_bin jesseduffield/lazygit  'lazygit_.*linux_x86_64\.tar\.gz$'              lazygit
fetch_bin mikefarah/yq           'yq_linux_amd64$'                               yq
# container / k8s / devsecops tooling
fetch_bin jesseduffield/lazydocker 'lazydocker_.*Linux_x86_64\.tar\.gz$'         lazydocker
fetch_bin wagoodman/dive         'dive_.*linux_amd64\.tar\.gz$'                  dive
fetch_bin bcicen/ctop            'ctop-.*-linux-amd64$'                          ctop
fetch_bin derailed/k9s           'k9s_Linux_amd64\.tar\.gz$'                     k9s
fetch_bin casey/just             'just-.*x86_64-unknown-linux-musl\.tar\.gz$'    just
fetch_bin hadolint/hadolint      'hadolint-linux-x86_64$'                        hadolint
fetch_bin aquasecurity/trivy     'trivy_.*Linux-64bit\.tar\.gz$'                 trivy
fetch_bin gitleaks/gitleaks      'gitleaks_.*linux_x64\.tar\.gz$'                gitleaks
fetch_bin anchore/grype          'grype_.*linux_amd64\.tar\.gz$'                 grype
fetch_bin anchore/syft           'syft_.*linux_amd64\.tar\.gz$'                  syft
fetch_bin sigstore/cosign        'cosign-linux-amd64$'                           cosign
fetch_bin anomalyco/opencode     'opencode-linux-x64\.tar\.gz$'                  opencode

log "[5/12] Python-based security tooling (isolated envs via uv)"
command -v checkov    >/dev/null 2>&1 || uv tool install --quiet checkov    && ok checkov    || fail checkov
command -v pre-commit >/dev/null 2>&1 || uv tool install --quiet pre-commit && ok pre-commit || fail pre-commit

log "[6/12] Java toolchain via mise (JDK LTS + Maven + Gradle)"
if command -v mise >/dev/null 2>&1; then
  command -v java   >/dev/null 2>&1 || mise use -g java@lts && ok "java (LTS)"  || fail "java"
  command -v mvn    >/dev/null 2>&1 || mise use -g maven    && ok "maven"      || fail maven
  command -v gradle >/dev/null 2>&1 || mise use -g gradle   && ok "gradle"     || fail gradle
else
  fail "java stack (mise not installed)"
fi

log "[7/12] ML/data-science venv (~/.venvs/ml, managed by uv)"
if [[ ! -d ~/.venvs/ml ]]; then
  uv venv ~/.venvs/ml --python 3.13 && ok "created ~/.venvs/ml" || fail "ml venv"
fi
uv pip install --quiet --python ~/.venvs/ml/bin/python \
  numpy pandas scipy scikit-learn matplotlib seaborn plotly polars pyarrow \
  jupyterlab ipykernel || fail "ml packages"
ok "~/.venvs/ml ready (activate with: ml)"

log "[8/12] NVIDIA drivers (auto-detected; needed for GPU-accelerated Ollama)"
if lspci 2>/dev/null | grep -qi nvidia; then
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    $SUDO ubuntu-drivers install || $SUDO ubuntu-drivers autoinstall \
      && ok "nvidia drivers (REBOOT required)" || fail "nvidia drivers"
    NEED_REBOOT=1
  else
    ok "nvidia drivers (already active: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1))"
  fi
else
  echo "  - no NVIDIA GPU detected, skipping"
fi

log "[9/12] Ollama (local LLM runtime; uses NVIDIA GPU when present)"
if ! command -v ollama >/dev/null 2>&1; then
  curl -fsSL https://ollama.com/install.sh | $SUDO sh \
    && ok "ollama (systemd service installed; try: ollama pull llama3.2 && ollama run llama3.2)" \
    || fail ollama
else
  ok "ollama (already installed)"
fi

log "[10/12] Docker Engine (opt-in: --docker)"
if [[ $WITH_DOCKER == 1 ]] && ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | $SUDO sh -s \
    && $SUDO usermod -aG docker "$USER" \
    && ok "docker (log out/in once for group membership)" || fail docker
elif command -v docker >/dev/null 2>&1; then
  ok "docker (already installed)"
else
  echo "  - skipped (re-run with: ./install-ubuntu.sh --docker)"
fi

log "[11/12] Nerd font (starship/eza icons) and shell hooks"
if [[ $SERVER == 0 ]] && ! fc-list | grep -qi 'JetBrainsMono.*[Nn]erd'; then
  if curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o /tmp/jbm.zip; then
    mkdir -p ~/.local/share/fonts && unzip -oq /tmp/jbm.zip -d ~/.local/share/fonts/ \
      && fc-cache -f >/dev/null && rm /tmp/jbm.zip && ok "JetBrainsMono Nerd Font"
  else
    fail "nerd font download"
  fi
fi

log "[12/12] Dotfiles (backup + symlink bash/tmux/starship configs)"
./install-shell.sh --no-deps

echo
if [[ -n $FAILED ]]; then
  echo "Finished with failures:$FAILED"
  echo "Re-run ./install-ubuntu.sh after fixing network/GitHub rate limits."
else
  echo "All done. Log out and back in (or: source ~/.bashrc), then:"
  echo "  gh auth login        # GitHub CLI"
  echo "  atuin import bash    # import existing history, once"
  echo "  ml                   # activate the ML venv, then: python -c 'import numpy'"
  [[ $NEED_REBOOT == 1 ]] && echo "  REBOOT now — NVIDIA drivers were just installed, Ollama GPU needs it."
  [[ $SERVER == 0 ]] && echo "  See docs/UBUNTU-SETUP.md for the manual post-install steps."
fi
