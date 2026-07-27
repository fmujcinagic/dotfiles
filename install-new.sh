#!/bin/bash

set -e # Exit immediately if a command fails

echo "==> Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "==> Installing core tools, dependencies, and desktop components..."
sudo apt-get install -y \
  wget curl git thunar arandr flameshot arc-theme feh \
  i3blocks i3status i3 i3-wm lxappearance python3-pip pipx rofi unclutter \
  cargo picom papirus-icon-theme imagemagick alacritty spice-vdagent i3lock \
  libxcb-shape0-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev \
  libxcb1-dev libxcb-icccm4-dev libyajl-dev libev-dev libxcb-xkb-dev \
  libxcb-cursor-dev libxkbcommon-dev libxcb-xinerama0-dev libxkbcommon-x11-dev \
  libstartup-notification0-dev libxcb-randr0-dev libxcb-xrm0 libxcb-xrm-dev \
  autoconf meson libxcb-render-util0-dev libxcb-xfixes0-dev

echo "==> Setting up fonts..."
mkdir -p ~/.local/share/fonts/

wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Iosevka.zip
wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/RobotoMono.zip

unzip -o Iosevka.zip -d ~/.local/share/fonts/
unzip -o RobotoMono.zip -d ~/.local/share/fonts/
rm Iosevka.zip RobotoMono.zip

fc-cache -fv

echo "==> Installing pywal..."
pipx install pywal --force

echo "==> Setting up configuration directories..."
mkdir -p ~/.config/i3
mkdir -p ~/.config/picom
mkdir -p ~/.config/rofi
mkdir -p ~/.config/alacritty

echo "==> Copying dotfiles..."
[ -f .tmux.conf ] && cp .tmux.conf ~/.tmux.conf
[ -f .config/i3/config ] && cp .config/i3/config ~/.config/i3/config
[ -f .config/alacritty/alacritty.toml ] && cp .config/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml
[ -f .config/i3/i3blocks.conf ] && cp .config/i3/i3blocks.conf ~/.config/i3/i3blocks.conf
[ -f .config/compton/compton.conf ] && cp .config/compton/compton.conf ~/.config/picom/picom.conf
[ -f .config/rofi/config ] && cp .config/rofi/config ~/.config/rofi/config
[ -f .fehbg ] && cp .fehbg ~/.fehbg
[ -f .config/i3/clipboard_fix.sh ] && cp .config/i3/clipboard_fix.sh ~/.config/i3/clipboard_fix.sh
[ -f .config/i3/powermenu.sh ] && cp .config/i3/powermenu.sh ~/.config/i3/powermenu.sh
[ -d .wallpaper ] && cp -r .wallpaper ~/.wallpaper 

# Ensure SPICE daemon is set to run automatically in i3 config for VM clipboard sharing
if ! grep -q "spice-vdagent" ~/.config/i3/config 2>/dev/null; then
    echo "exec --no-startup-id spice-vdagent" >> ~/.config/i3/config
fi

echo "==> Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "=========================================================================="
echo "Done! Grab a wallpaper and run 'wal -i <path_to_image>' to set your color scheme."
echo "After reboot: Select i3 on login, run lxappearance and select arc-dark."
echo "=========================================================================="
