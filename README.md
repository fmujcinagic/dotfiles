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

```sh
git clone git@github.com:fmujcinagic/dotfiles.git ~/dotfiles
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
