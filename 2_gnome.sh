#!/bin/bash

echo "Downloading and running base script"
wget https://raw.githubusercontent.com/dylanmtaylor/minimal-arch-linux/master/2_base.sh
chmod +x 2_base.sh
sh ./2_base.sh

echo "Installing Gnome"
sudo pacman -S --noconfirm gnome gnome-tweaks gvfs-goa 

echo "Enabling GDM"
sudo systemctl enable gdm.service

echo "Installing yay"
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ..
rm -rf yay-bin

echo "Installing various application packages"
yay -S --noconfirm google-chrome discord atom gitkraken evolution libreoffice-fresh gimp krita virtualbox steam lutris vlc hexchat transmission-gtk inkscape blender etcher-bin cheese code handbrake kdenlive dosbox wine filezilla docker remmina teamviewer google-earth meld"

echo "Your setup is ready. You can reboot now!"
