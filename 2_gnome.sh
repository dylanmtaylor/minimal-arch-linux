#!/bin/bash

echo "Downloading and running base script"
wget https://raw.githubusercontent.com/dylanmtaylor/minimal-arch-linux/master/2_base.sh
chmod +x 2_base.sh
sh ./2_base.sh

echo "Installing Gnome"
sudo pacman -S --noconfirm gnome gnome-tweaks gvfs-goa fwupd gst-libav

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

echo "Installing and configuring Plymouth"
yay -S --noconfirm plymouth
sudo sed -i 's/base systemd autodetect/base systemd sd-plymouth autodetect/g' /etc/mkinitcpio.conf
sudo sed -i 's/quiet rw/quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0 rw/g' /boot/loader/entries/arch.conf
# Arch LTS left out on purpose, in case there's an issue with Plymouth

echo "Installing and setting plymouth theme"
yay -S --noconfirm plymouth-theme-arch-breeze-git
sudo plymouth-set-default-theme -R arch-breeze

echo "Installing various application packages that I like (you can safely skip this)"
yay -S --needed google-chrome discord atom gitkraken evolution libreoffice-fresh gimp krita virtualbox steam lutris vlc hexchat transmission-gtk inkscape blender etcher-bin cheese visual-studio-code-bin handbrake kdenlive dosbox wine filezilla docker remmina teamviewer google-earth-pro meld brasero authy-snap prusa-slicer darktable vagrant terraform ansible obs-studio wireshark zenmap lastpass dbeaver intellij-idea-ce pycharm-community-edition phoronix-test-suite zoom piavpn pamac-aur crossover unetbootin

echo "Your setup is ready. You can reboot now!"
