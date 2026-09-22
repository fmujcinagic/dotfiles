# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions (no-op on Ubuntu)
[[ -n "${OMARCHY_PATH:-}" && -r "$OMARCHY_PATH/default/bash/rc" ]] && source "$OMARCHY_PATH/default/bash/rc"

# ---- Non-Omarchy fallbacks (Ubuntu) ----
if [[ -z "${OMARCHY_PATH:-}" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
  PS1='[\u@\h \W]\$ '
  [[ -r /etc/bash_completion ]] && source /etc/bash_completion
  command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
fi

# ---- Debian/Ubuntu tool-name compatibility ----
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then alias fd='fdfind'; fi
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then alias bat='batcat'; fi

# ---- Productivity aliases ----

# Listing (eza-based, layered on Omarchy's ls)
if command -v eza >/dev/null 2>&1; then
  alias l='eza -lha --group-directories-first --icons=auto --git'
  alias ll='eza -lh --group-directories-first --icons=auto --git'
fi

# History search with fzf on Ctrl+R (Arch and Ubuntu use different paths)
for f in /usr/share/fzf/shell/key-bindings.bash /usr/share/fzf/key-bindings.bash /etc/bash_completion.d/fzf; do
  [[ -r $f ]] && source $f
done

# Bigger, deduped history
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# fzf in terminal, fd-driven (fast, respects .gitignore)
if command -v fd >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1; then
  alias f='fd --type f --hidden --exclude .git | fzf --preview "bat --style=numbers --color=always {}"'
fi

# Quick edits
alias n="nvim"
alias nn="nvim ~/.config/nvim"
alias bashrc="nvim ~/.bashrc && source ~/.bashrc"

# Safety nets for destructive ops
alias rm='rm -I'
alias mkdir='mkdir -pv'

# Grep goes through ripgrep when typing plain "grep"
command -v rg >/dev/null 2>&1 && alias grep='rg'

# cd straight back to earlier dirs: `cd 2` goes back two
alias cd-='cd -'
cdh() { local d; d=$(fc -inr | awk '/^cd /{print $2; if (++n==10) exit}' | fzf) && cd "$d"; }

# mkcd: create dir and cd into it
mkcd() { mkdir -p "$1" && builtin cd "$1"; }

# extract: unzip whatever archive
extract() { case "$1" in *.tar.bz2|*.tbz2) tar xvjf "$1";; *.tar.gz|*.tgz) tar xvzf "$1";; *.tar.xz) tar xJf "$1";; *.tar) tar xvf "$1";; *.zip) unzip "$1";; *.rar) unrar x "$1";; *.7z) 7z x "$1";; *.gz) gunzip "$1";; *) echo "Unknown archive: $1";; esac; }
