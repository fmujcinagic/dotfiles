# Ubuntu productivity setup — guidance

Companion to `install-ubuntu.sh`. Target: Ubuntu 24.04+ on x86_64 (Wayland
default session). The script is idempotent — re-run it any time to pull new
versions of the GitHub-installed tools.

## Quick start (fresh machine)

```sh
sudo apt-get update && sudo apt-get install -y git   # minimum to clone
git clone git@github.com:fmujcinagic/dotfiles.git ~/dotfiles   # or https:// URL
cd ~/dotfiles && ./install-ubuntu.sh
```

Headless box (no GNOME/desktop bits, skips fonts/copyq/timeshift):

```sh
./install-ubuntu.sh --server
```

Then log out/in and finish the two one-time steps:

```sh
gh auth login         # GitHub CLI
atuin import bash     # fold pre-existing history into atuin, once
```

## Where things get installed — and why

| Source                | Land in                | Tools                                    |
| --------------------- | ---------------------- | ---------------------------------------- |
| apt                   | `/usr/bin`             | tmux, fzf, ripgrep, bat, fd-find, btop, jq, ncurses-term, gnome-tweaks, copyq, timeshift, gh (own repo) |
| Official installers   | `~/.local/bin`         | starship\*, zoxide, uv, mise, atuin\*    |
| GitHub release assets | `~/.local/bin`         | eza, delta, tlrc (command `tldr`), neovim, lazygit, yq |
| Dotfiles symlinks     | `~/`                   | `.bashrc`, `.bash_profile`, `.config/tmux/tmux.conf`, `.config/starship.toml` |

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

1. **Terminal + font.** Pick one: `sudo apt install alacritty kitty`, or
   Ghostty's official apt repo (`https://packagist.ghostty.dev` — see their
   docs). Set `JetBrainsMono Nerd Font` as terminal font (on Omarchy the
   terminal themes are managed; on Ubuntu do it per terminal).
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

To bring **more** config into the repo later (nvim, mise, alacritty):
`mkdir -p ~/dotfiles/.config/nvim`, move the real dir there, and symlink it
back — same pattern `install-shell.sh` already uses.

## Cheat sheet for the new tools

| Tool     | What it does                       | Try                                                    |
| -------- | ---------------------------------- | ------------------------------------------------------ |
| zoxide   | `cd` that learns from history      | `z proj`, `z <tab>`, `at` for fzf-pick                  |
| atuin    | SQLite history, replaces Ctrl+R    | Ctrl+R, then search across *all* machines' history      |
| tldr     | practical man pages (tlrc)         | `tldr tar`, `tldr git rebase`             |
| delta    | pretty git diffs                   | not auto-wired — enable once per machine (snippet below) |
| mise     | version-manager for dev runtimes   | `mise use -g node@22`, `mise ls`                        |
| uv       | fast python                        | `uv run --with requests script.py`, `uv init`           |
| lazygit  | TUI git client                     | type `g` (alias it yourself in `.bashrc` if wanted)     |
| eza/bat/fd/rg | already in your muscle memory  | `l`, `ll`, `f`, plain `grep` = rg                       |

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
