#!/bin/bash

encryption_passphrase="test"
root_password="test"
user_password="test"
hostname="dylantaylor-vm"
user_name="dylan"
continent_city="America/New_York"
cpu_vendor="intel"
swap_size="8" # Needs to match RAM for hibernation

echo "Updating system clock"
timedatectl set-ntp true
timedatectl set-timezone $continent_city

echo "Refreshing PGP keys"
pacman-key --init
pacman-key --populate archlinux
pacman -Sc --noconfirm
pacman -Sy --noconfirm gnupg archlinux-keyring

echo "Syncing packages database"
pacman -Sy --noconfirm

echo "Creating partition tables"
printf "n\n1\n4096\n+512M\nef00\nw\ny\n" | gdisk /dev/nvme0n1
printf "n\n2\n\n\n8e00\nw\ny\n" | gdisk /dev/nvme0n1

# echo "Zeroing partitions"
# cat /dev/zero > /dev/nvme0n1p1
# cat /dev/zero > /dev/nvme0n1p2

echo "Setting up cryptographic volume"
printf "%s" "$encryption_passphrase" | cryptsetup -h sha512 -s 512 --use-random --type luks2 luksFormat /dev/nvme0n1p2
printf "%s" "$encryption_passphrase" | cryptsetup luksOpen /dev/nvme0n1p2 cryptlvm

echo "Creating physical volume"
pvcreate /dev/mapper/cryptlvm

echo "Creating volume volume"
vgcreate vg0 /dev/mapper/cryptlvm

echo "Creating logical volumes"
lvcreate -L +"$swap_size"GB vg0 -n swap
lvcreate -l +100%FREE vg0 -n root

echo "Setting up / partition"
yes | mkfs.ext4 /dev/vg0/root
mount /dev/vg0/root /mnt

echo "Setting up /boot partition"
yes | mkfs.fat -F32 /dev/nvme0n1p1
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

echo "Setting up swap"
yes | mkswap /dev/vg0/swap
swapon /dev/vg0/swap

echo "Installing Arch Linux"
yes '' | pacstrap /mnt base base-devel linux linux-headers linux-lts linux-lts-headers linux-firmware lvm2 device-mapper e2fsprogs $cpu_vendor-ucode cryptsetup mesa networkmanager wget man-db man-pages nano vi diffutils

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

echo "Configuring new system"
arch-chroot /mnt /bin/bash <<EOF
echo "Setting system clock"
ln -sf /usr/share/zoneinfo/$continent_city /etc/localtime
hwclock --systohc --localtime

echo "Setting locales"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen

echo "Adding persistent keymap"
echo "KEYMAP=us" > /etc/vconsole.conf

echo "Setting hostname"
echo $hostname > /etc/hostname

echo "Setting root password"
echo -en "$root_password\n$root_password" | passwd

echo "Creating new user"
useradd -m -G wheel -s /bin/bash $user_name
usermod -a -G video $user_name
echo -en "$user_password\n$user_password" | passwd $user_name

echo "Generating initramfs"
sed -i 's/^HOOKS.*/HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
sed -i 's/^MODULES.*/MODULES=(ext4 intel_agp i915)/' /etc/mkinitcpio.conf
mkinitcpio -p linux
mkinitcpio -p linux-lts

echo "Setting up systemd-boot"
bootctl --path=/boot install

mkdir -p /boot/loader/
touch /boot/loader/loader.conf
tee -a /boot/loader/loader.conf << END
default arch
timeout 1
editor 0
END

mkdir -p /boot/loader/entries/
touch /boot/loader/entries/arch.conf
tee -a /boot/loader/entries/arch.conf << END
title Arch Linux
linux /vmlinuz-linux
initrd /$cpu_vendor-ucode.img
initrd /initramfs-linux.img
options rd.luks.name=$(blkid -s UUID -o value /dev/nvme0n1p2)=cryptlvm root=/dev/vg0/root resume=/dev/vg0/swap rd.luks.options=discard i915.fastboot=1 quiet rw
END

touch /boot/loader/entries/archlts.conf
tee -a /boot/loader/entries/archlts.conf << END
title Arch Linux LTS
linux /vmlinuz-linux-lts
initrd /$cpu_vendor-ucode.img
initrd /initramfs-linux-lts.img
options rd.luks.name=$(blkid -s UUID -o value /dev/nvme0n1p2)=cryptlvm root=/dev/vg0/root resume=/dev/vg0/swap rd.luks.options=discard i915.fastboot=1 quiet rw
END

echo "Enabling multilib"
cat <<EOG > /etc/pacman.conf
[options]
HoldPkg     = pacman glibc
Architecture = auto
CheckSpace
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOG

echo "Setting up Pacman hook for automatic systemd-boot updates"
mkdir -p /etc/pacman.d/hooks/
touch /etc/pacman.d/hooks/systemd-boot.hook
tee -a /etc/pacman.d/hooks/systemd-boot.hook << END
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot
When = PostTransaction
Exec = /usr/bin/bootctl update
END

echo "Enabling periodic TRIM"
systemctl enable fstrim.timer

echo "Enabling NetworkManager"
systemctl enable NetworkManager

echo "Adding user as a sudoer"
echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo
EOF

umount -R /mnt
swapoff -a

echo "Arch Linux is ready. You can reboot now!"
