# Ubuntu productivity setup — guidance

Companion to `install-ubuntu.sh`. Target: **Ubuntu 26.04 LTS** on x86_64
(24.04 also works; Wayland default session). The script is idempotent —
re-run it any time to pull new versions of the GitHub-installed tools.

## Quick start (fresh machine)

```sh
sudo apt-get update && sudo apt-get install -y git   # minimum to clone
git clone git@github.com:fmujcinagic/dotfiles.git ~/dotfiles   # or https:// URL
cd ~/dotfiles && ./install-ubuntu.sh
```

Headless box (no GNOME/desktop/VM bits, skips fonts/copyq/timeshift/virt-manager):

```sh
./install-ubuntu.sh --server
```

Want Docker Engine + Compose (official repo, adds you to the `docker` group):

```sh
./install-ubuntu.sh --docker
```

Then log out/in (twice if `--docker`: group membership needs a fresh login) and finish the one-time steps:

```sh
gh auth login         # GitHub CLI
atuin import bash     # fold pre-existing history into atuin, once
```

## Where things get installed — and why

| Source                | Land in                | Tools                                    |
| --------------------- | ---------------------- | ---------------------------------------- |
| apt (core)            | `/usr/bin`             | tmux, fzf, ripgrep, bat, fd-find, btop, jq, ncurses-term, build-essential, cmake, ninja, pkg-config, ccache, **clang/clangd/clang-tools, gdb, lldb, valgrind, cppcheck** (C/C++), python3-dev, ubuntu-drivers-common, gh (own repo) |
| apt (desktop only)    | `/usr/bin`             | **ghostty** (Ubuntu 26.04 universe — made the one-and-only default terminal via `~/.config/xdg-terminals.list`, which GNOME's Ctrl+Alt+T reads through `xdg-terminal-exec`), gnome-tweaks, copyq, timeshift, qemu-kvm, libvirt, virt-manager, wl-clipboard |
| Official installers   | `~/.local/bin`         | starship\*, zoxide, uv, mise, atuin\*, **opencode** |
| GitHub release assets | `~/.local/bin`         | eza, delta, tlrc (command `tldr`), neovim, lazygit, yq, lazydocker, dive, ctop, k9s, just, hadolint, trivy, gitleaks, grype, syft, cosign |
| uv tool (isolated envs) | `~/.local/bin`       | checkov, pre-commit                      |
| mise global tools       | mise shims         | **java (OpenJDK LTS), maven, gradle**    |
| uv venv               | `~/.venvs/ml`          | numpy, pandas, scipy, scikit-learn, matplotlib, seaborn, plotly, polars, pyarrow, jupyterlab, ipykernel |
| ubuntu-drivers (if NVIDIA GPU present) | kernel module + `nvidia-smi` | proprietary NVIDIA driver stack |
| ollama.com installer  | `/usr/local/bin` + systemd service | **ollama** (uses the NVIDIA GPU after reboot) |
| Docker official script (opt-in `--docker`) | `/usr/bin` | docker, docker compose      |
| Dotfiles symlinks     | `~/`                   | `.bashrc`, `.bash_profile`, `.config/tmux/tmux.conf`, `.config/starship.toml`, `.config/nvim`, `.config/ghostty`, `.config/xdg-terminals.list` |

\* starship goes to `/usr/local/bin` via sudo; atuin's binary also lives in
`~/.atuin/bin` (on PATH via `~/.local/bin`).

Rule of thumb: **apt only for system-level things** (tmux, fzf, ripgrep are
fine and slow-moving). Anything a developer touches — neovim, lazygit, delta,
python, node, go — comes from upstream releases or `mise`, because apt's
copies are 1–3 years stale. `nvim` via apt would break lazygit's diff view
and LSP support, so the script deliberately ignores it.

## Gotchas baked into the setup

- **`fd`/`bat` are renamed on Debian/Ubuntu** (`fd-find`, `batcat`).
  `.bashrc` aliases them back, so `fd`, `bat`, and the `f` file-picker alias
  behave exactly like on Arch.
- **Deb packaging (deb12 vs deb16):** Ubuntu 24.04's dpkg can't install
  debs built with dpkg ≥ 1.22, which many "latest" GitHub `.deb` assets now
  are. The script therefore *extracts* debs with `ar`/`tar` into
  `~/.local/bin` instead of `dpkg -i` — immune to that breakage.
- **`ncurses-term`** is required for tmux `default-terminal tmux-256color`;
  without it, tmux starts with broken colors on Ubuntu.
- **tmux 3.4** (24.04) is the minimum for `extended-keys-format csi-u` in
  your config. On 22.04 (tmux 3.2a) those lines would error — don't use
  22.04 with these configs.
- **Icons/Nerd font:** starship + `eza --icons` need a Nerd Font. The script
  installs JetBrainsMono Nerd Font to `~/.local/share/fonts`; set it in your
  terminal profile afterwards (see below).
- **PATH:** `~/.local/bin` is added by `~/.bashrc` (tty) and Ubuntu's default
  `~/.profile` (GUI session). If a GUI app can't find `mise`/`uv`, you logged
  in before the first reboot — log out once.

## Manual steps after the script (desktop only)

1. **Terminal.** Ghostty is installed (Ubuntu 26.04's own apt package — no
   PPA needed), set as the one-and-only default terminal, and its config is
   symlinked from `.config/ghostty` (same as on Omarchy; the dynamic theme
   `config-file = ?"..."` include is guarded and simply skipped without
   Omarchy). GNOME's terminal shortcut is set to win+enter (Super+Return,
   replacing Ctrl+Alt+T) and launches `xdg-terminal-exec`, which reads the
   first entry of `~/.config/xdg-terminals.list` (symlinked from the repo, so
   only Ghostty is listed) — the legacy `x-terminal-emulator` alternative is
   also pointed at Ghostty. The JetBrainsMono Nerd Font installed by the
   script is referenced by that config, and every new Ghostty surface starts
   a fresh tmux session (`command = tmux new-session`).
   Log out/in after a `--docker` install
   or an NVIDIA driver install (the latter needs a reboot for
   `nvidia-smi`/Ollama GPU to come up — check with `ollama ps`, model should
   list "100% GPU").
2. **Tiling.** Vanilla GNOME won't feel like Hyprland. Open
   *Extension Manager* (installed by the script) → search **gtile** (or
   **Pop Shell**, or **Forge**) → enable. Suggested keybinds in gtile
   settings: super+H/L/V/B to split, super+Enter terminal. `gnome-tweaks`
   covers keyboard repeat rate, hot corner, etc.
3. **Clipboard history.** Launch *CopyQ* once, enable "Start at login",
   bind `super+V` to its history window (Settings → Shortcuts → show/hide).
   GNOME has no clipboard history at all otherwise.
4. **Timeshift.** First run → wizard → choose RSYNC, exclude `/home` if you
   only want system rollback. Note: snapshots need free space on the *system*
   partition (or a separate drive); take a manual snapshot after setup and
   weekly after.
5. **SSH key for GitHub** (needed before pushing dotfiles):
   `ssh-keygen -t ed25519 -C faris1306@hotmail.com && cat ~/.ssh/id_ed25519.pub`
   → add to GitHub → `ssh -T git@github.com` to verify. Or skip SSH and use
   `gh auth login` + `git config --global credential.helper "gh auth git-credential"`.
6. **atuin config (optional).** `~/.config/atuin/config.toml`:
   `style = "compact"`, `enter_accept = true`, and `sync` if you'll use it on
   more than one machine.

## Day-2 workflow: config lives in the repo

Your `~/.bashrc`, `~/.bash_profile`, `~/.config/tmux/tmux.conf` and
`~/.config/starship.toml` are **symlinks into `~/dotfiles`** — editing them
in place edits the repo. So:

```sh
cd ~/dotfiles
git diff                     # see what you changed
git commit -am "tmux: ..." && git push
```

…repeats the same change on every other machine with
`cd ~/dotfiles && git pull`. `alias nn` / the `bashrc` alias open the right
files either way.

To bring **more** config into the repo later (mise, alacritty):
`mkdir -p ~/dotfiles/.config/foo`, move the real dir there, and symlink it
back — same pattern `install-shell.sh` already uses (that's how `.config/nvim`
and `.config/tmux` are wired).

## Cheat sheet for the new tools

| Tool     | What it does                       | Try                                                    |
| -------- | ---------------------------------- | ------------------------------------------------------ |
| zoxide   | `cd` that learns from history      | `z proj`, `z <tab>`, `at` for fzf-pick                  |
| fzf (shell keys) | fuzzy file/dir/history pickers | `Ctrl+T` pick files, `Alt+C` cd into a dir, `Ctrl+R` history |
| bash completion | case-insensitive, `-`≡`_` | type `cd doc<Tab>` → `Documents/` (no exact caps needed) |
| atuin    | SQLite history, replaces Ctrl+R    | Ctrl+R, then search across *all* machines' history      |
| tldr     | practical man pages (tlrc)         | `tldr tar`, `tldr git rebase`             |
| delta    | pretty git diffs                   | not auto-wired — enable once per machine (snippet below) |
| mise     | version-manager for dev runtimes   | `mise use -g node@22`, `mise ls`                        |
| uv       | fast python                        | `uv run --with requests script.py`, `uv init`           |
| lazygit  | TUI git client                     | type `g` (alias it yourself in `.bashrc` if wanted)     |
| lazydocker | TUI for docker ps/logs/exec      | `lazydocker`, then j/k/enter to drill, `l` for logs     |
| ctop     | `top` for container metrics        | `ctop` (live CPU/mem/net per container)                 |
| dive     | inspect image layers for bloat     | `dive myimage:latest`                                   |
| k9s      | TUI for Kubernetes clusters        | `k9s`, `:pod /app`, `l` logs, `s` shell, `:ctx` switch  |
| just     | modern task runner (Make-style)    | `just` in a repo with a `justfile`; `just <task>`       |
| hadolint | Dockerfile linter                  | `hadolint Dockerfile` (or in CI/pre-commit)             |
| trivy    | all-in-one scanner                 | `trivy image foo:latest`, `trivy fs .`, `trivy config infra/` |
| gitleaks | secret scanner                     | `gitleaks protect --staging` (pre-commit hook)          |
| grype/syft | CVE scan / SBOM                  | `syft . -o spdx-json > sbom.json` ; `grype sbom:sbom.json` |
| checkov  | IaC scanner (TF/K8s/Helm/Dockerfile) | `checkov -d infra/`                                   |
| cosign   | sign/verify OCI artifacts          | `cosign verify image:tag`                               |
| pre-commit | git hook manager                 | `pre-commit install` in a repo, edit `.pre-commit-config.yaml` |
| virt-manager | GUI for KVM/libvirt VMs         | launch from app grid; `--server` skips it               |
| opencode   | AI coding agent in the terminal | `opencode` in a project → `/connect` to add a provider  |
| ollama     | local LLMs on your RTX          | `ollama pull llama3.2`, `ollama run llama3.2`, `ollama ps` shows GPU/CPU split |
| ghostty    | default terminal (26.04 apt)    | config is symlinked from dotfiles; `shift+insert` paste |
| `ml`       | activate the ML venv            | `ml && python -c "import pandas"` ; `uv pip install torch --python ~/.venvs/ml/bin/python` for GPU torch |
| java/mvn/gradle | JDK LTS + build tools (via mise) | `java -version`, `mvn -version`, `gradle --version`; per-project: `mise use -g java@21` to pin an older JDK |
| eza/bat/fd/rg | already in your muscle memory  | `l`, `ll`, `f`, plain `grep` = rg                       |

## Neovim — exact replica of the Omarchy setup

`.config/nvim` is a copy of the current Omarchy config: **LazyVim** (starter,
lockfile-pinned via `lazy-lock.json`) with the Omarchy extras — everforest
theme, theme hot-reload, all-themes registry, transparency, OSC52 remote
clipboard, neo-tree + clangd/python/rust language extras, plus a `java.lua`
enabling LazyVim's Java extra (jdtls via Mason — needs the mise JDK >= 21).
Autocomplete
(blink.cmp), LSP, treesitter, and Mason tooling all come from LazyVim itself.

On first `nvim` launch lazy.nvim bootstraps everything and installs the pinned
plugin set; Mason then auto-installs LSP servers/formatters per file type you
open. Node-based servers need node — `mise use -g node@22` before first launch
(or run `:Mason` and install on demand). `wl-clipboard` (installed by the
script) backs the OSC52 clipboard integration; inside tmux it works over SSH too.

The Omarchy-only pieces degrade gracefully: theme hot-reload only reacts to
`LazyReload`, and remote clipboard falls back to OSC52 query when no
`wl-copy` is present — nothing on Ubuntu will error with these files present.

Keybindings are the standard LazyVim ones (leader = Space), e.g.:

| Keys              | What                                        |
| ----------------- | ------------------------------------------- |
| `<leader>ff`      | Find files (telescope, fd+ripgrep-backed)    |
| `<leader>fg`      | Live grep                                    |
| `<leader>fr`      | Resume last picker                           |
| `<leader>e` / `-` | neo-tree / oil-style parent-dir browsing     |
| `gr` / `gd` / `K` | LSP references / definition / hover          |
| `<leader>ca` / `<leader>rn` | Code action / rename             |
| `<leader>xx` / `<leader>xX` | Buffer / all diagnostics         |
| `<leader>qq`      | Quit all                                     |

On top of that, `lua/plugins/harpoon.lua` adds **Harpoon v2** (auto-imported
by LazyVim): `<leader>a` add file to shelf, `<C-e>` or `<leader>hh` quick
menu, `<leader>h1..4` jump to slots 1–4, `<leader>hp/hn` prev/next.

Enable delta as git's pager once per machine:

```sh
git config --global core.pager "delta"
git config --global delta.side-by-side true
```

## Updating

- Re-run `./install-ubuntu.sh` — GitHub tools self-update to latest.
- `mise upgrade`, `uv self update`, `atuin --version`-check via script,
  apt tools follow `sudo apt upgrade`.
- Ubuntu release upgrade (24.04 → 26.04): re-run the installer afterwards;
  the apt layer re-creates anything the distro removed.
