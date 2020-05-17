#!/bin/bash

echo "Downloading and running base script"
wget https://raw.githubusercontent.com/dylanmtaylor/minimal-arch-linux/master/2_base.sh
chmod +x 2_base.sh
sh ./2_base.sh

echo "Installing Gnome"
sudo pacman -S --noconfirm gnome gnome-tweaks gvfs-goa fwupd

echo "Enabling GDM"
sudo systemctl enable gdm.service

echo "Installing yay"
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ..
rm -rf yay-bin

echo "Installing Papirus icon theme"
yay -S --noconfirm papirus-icon-theme-git

echo "Installing Numix GTK theme"
yay -S --noconfirm numix-gtk-theme-git

echo "Installing Dash to Dock"
yay -S --noconfirm gnome-shell-extension-dash-to-dock-git

echo "Installing various application packages that I like (you can safely skip this)"
yay -S --needed google-chrome discord atom gitkraken evolution libreoffice-fresh gimp krita virtualbox steam lutris vlc hexchat transmission-gtk inkscape blender etcher-bin cheese visual-studio-code-bin handbrake kdenlive dosbox wine filezilla docker remmina teamviewer google-earth-pro meld brasero authy-snap prusa-slicer

echo "Your setup is ready. You can reboot now!"
