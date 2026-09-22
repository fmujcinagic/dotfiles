# dotfiles

## Current setup (Omarchy/Arch + portable to Ubuntu)

Shell (bash), tmux, and starship. Everything is Ubuntu-compatible: Omarchy-only
pieces are guarded and silently skipped elsewhere.

| Repo file                | Symlinked to                 |
| ------------------------ | ---------------------------- |
| `.bashrc`                | `~/.bashrc`                  |
| `.bash_profile`          | `~/.bash_profile`            |
| `.config/tmux/tmux.conf` | `~/.config/tmux/tmux.conf`   |
| `.config/starship.toml`  | `~/.config/starship.toml`    |

### Replicate on a new machine

**Fresh Ubuntu — one-shot** (dotfiles + tmux/fzf/eza/etc. + zoxide, atuin,
mise, uv, nvim, lazygit, delta, gh, yq, tlrc, fonts, desktop extras):

```sh
git clone git@github.com:fmujcinagic/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install-ubuntu.sh          # add --server for headless
```

See [docs/UBUNTU-SETUP.md](docs/UBUNTU-SETUP.md) for what/where/why and the
manual post-install steps (gnome tiling, copyq, timeshift, ssh key, delta).

**Just the shell configs** (any Linux, incl. Arch/Omarchy — symlinks only):

```sh
cd ~/dotfiles && ./install-shell.sh        # add --no-deps to skip apt/starship installs
```

The installer backs up any existing non-symlinked file before linking.
Ubuntu 24.04+ is assumed (tmux >= 3.4 for `extended-keys-format`).

Installed deps: tmux, fzf, ripgrep, bat, fd, ncurses-term, eza (from the
eza-community GitHub release), starship. Debian/Ubuntu `fd`/`bat` are aliased
back to their usual names in `.bashrc`.

## Legacy i3 setup

`install-new.sh` and `.config/{i3,alacritty,picom}` are from an older
i3-on-Ubuntu setup, kept for reference.
