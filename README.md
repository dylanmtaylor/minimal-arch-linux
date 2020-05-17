# Minimal Arch Linux setup - Install scripts

This is a forked version of exah-io's repository. I changed this up as it's more minimal and closer to how I like my system. Really, this is mostly for myself but if you want to use it that's fine too. README is probably not up to date.

|                                                 Clean                                                 |                                               Busy                                                |
| :---------------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------------: |
| ![clean](https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/clean.png) | ![busy](https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/busy.png) |

## Gnome only
- Only Gnome is supported now. To see alternative DE/WM setups refer to the repository at [this commit](https://github.com/exah-io/minimal-arch-linux/tree/660ea7e57cfb3f89879dd3bfb47b3d4dd1f569f5)

## Install script

- LVM on LUKS
- LUKS2
- systemd-boot (with Pacman hook for automatic updates)
- systemd init hooks (instead of busybox)
- SSD Periodic TRIM
- Intel microcode
- Standard Kernel + LTS kernel as fallback

### Requirements

- UEFI mode
- NVMe SSD
- TRIM compatible SSD
- Intel CPU (recommended: Skylake or newer due to fastboot)

### Partitions

| Name                                                  | Type  | Mountpoint |
| ----------------------------------------------------- | :---: | :--------: |
| nvme0n1                                               | disk  |            |
| ├─nvme0n1p1                                           | part  |   /boot    |
| ├─nvme0n1p2                                           | part  |            |
| &nbsp;&nbsp;&nbsp;└─cryptlvm                        | crypt |            |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├─Arch-swap |  lvm  |   [SWAP]   |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─Arch-root |  lvm  |     /      |

## Post install script

- Gnome (2_gnome.sh)
- UFW (deny incoming, allow outgoing)
- Automatic login
- Kali themes and icon themes
- Automatic login

## Installation guide

1. Download and boot into the latest [Arch Linux iso](https://www.archlinux.org/download/)
2. Connect to the internet. If using wifi, you can use `wifi-menu` to connect to a network
3. Clear all existing partitions (see below: MISC - How to clear all partitions)
4. (optional) Give highest priority to the closest mirror to you on /etc/pacman.d/mirrorlist by moving it to the top
5. `wget https://raw.githubusercontent.com/dylanmtaylor/minimal-arch-linux/master/1_install.sh`
6. Change the variables at the top of the file (lines 3 through 9)
   - continent_country must have the following format: Zone/SubZone . e.g. Europe/Berlin
   - run `timedatectl list-timezones` to see full list of zones and subzones
7. Make the script executable: `chmod +x 1_install.sh`
8. Run the script: `./1_install.sh`
9. Reboot into Arch Linux
10. Connect to wifi with `nmtui`
11. `wget https://raw.githubusercontent.com/dylanmtaylor/minimal-arch-linux/master/2_gnome.sh`
12. Make the script executable: `chmod +x 2_gnome.sh`
13. Run the script: `./2_gnome.sh`

## Misc guides

### How to clear all partitions

```
gdisk /dev/nvme0n1
x
z
y
y
```

### Recommended Gnome extensions

- [Dash to Dock](https://extensions.gnome.org/extension/307/dash-to-dock/)

### How to setup Github with SSH Key

```
git config --global user.email "Github external email"
git config --global user.name "Github username"
ssh-keygen -t rsa -b 4096 -C "Github email"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
copy SSH key and add to Github (eg. nvim ~/.ssh/id_rsa.pub and copy content)
```

### How to chroot

```
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
cryptsetup luksOpen /dev/nvme0n1p2 cryptlvm
mount /dev/vg0/Arch-root /mnt
arch-chroot /mnt
```

### VSCode - Settings

- Check the following settings:
  - editor.formatOnSave
  - Prettier: Use Tabs
  - enablePreview
  - @tag:usesOnlineServices

### Recommended Firefox add-ons

- [uBlock Origin](https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/)
- [HTTPS Everywhere](https://addons.mozilla.org/en-US/firefox/addon/https-everywhere/)
- [Multi-touch Zoom](https://addons.mozilla.org/en-US/firefox/addon/multi-touch-zoom/)
- [Privacy Badger](https://addons.mozilla.org/en-US/firefox/addon/privacy-badger17/)

### How to install yay
```
echo "Installing yay"
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ..
rm -rf yay-bin
```

### Secure Boot with Linux Foundation Preloader
```
yay -S preloader-signed
sudo cp /usr/share/preloader-signed/{PreLoader,HashTool}.efi /boot/EFI/systemd
sudo cp /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/systemd/loader.efi
sudo efibootmgr --verbose --disk /dev/nvme0n1 --part 1 --create --label "PreLoader" --loader /EFI/systemd/PreLoader.efi
```

### Plymouth
```
echo "Installing and configuring Plymouth"
yay -S --noconfirm plymouth
sudo sed -i 's/base systemd autodetect/base systemd sd-plymouth autodetect/g' /etc/mkinitcpio.conf
sudo sed -i 's/quiet rw/quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0 rw/g' /boot/loader/entries/arch.conf
# Arch LTS left out on purpose, in case there's an issue with Plymouth

echo "Installing and setting plymouth theme"
yay -S --noconfirm plymouth-theme-arch-breeze-git
sudo plymouth-set-default-theme -R arch-breeze
```
