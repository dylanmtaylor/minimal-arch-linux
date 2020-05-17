#!/bin/bash

echo "Downloading and running base script"
wget https://raw.githubusercontent.com/dylanmtaylor/minimal-arch-linux/master/2_base.sh
chmod +x 2_base.sh
sh ./2_base.sh

echo "Installing Gnome and a few extra apps"
sudo pacman -S --noconfirm gnome gnome-tweaks gvfs-goa libreoffice-fresh

echo "Enabling GDM"
sudo systemctl enable gdm.service

echo "Installing yay"
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ..
rm -rf yay-bin

echo "Your setup is ready. You can reboot now!"
