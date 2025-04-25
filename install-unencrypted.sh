#!/bin/bash
set -e

DISK="/dev/nvme0n1"
HOSTNAME="archbook"
USERNAME="anon"
PASSWORD="anon"
LOCALE="en_US.UTF-8"
TIMEZONE="Europe/Kyiv"


sgdisk --zap-all $DISK
sgdisk -n1:0:+512M -t1:ef00 -c1:EFI $DISK
sgdisk -n2:0:0     -t2:8300 -c2:ROOT $DISK


mkfs.fat -F32 ${DISK}p1
mkfs.btrfs ${DISK}p2


mount ${DISK}p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
umount /mnt


mount -o noatime,compress=zstd,subvol=@ ${DISK}p2 /mnt
mkdir -p /mnt/{boot/efi,home,.snapshots,var/log,var/cache}
mount -o noatime,compress=zstd,subvol=@home ${DISK}p2 /mnt/home
mount -o noatime,compress=zstd,subvol=@snapshots ${DISK}p2 /mnt/.snapshots
mount -o noatime,compress=zstd,subvol=@log ${DISK}p2 /mnt/var/log
mount -o noatime,compress=zstd,subvol=@cache ${DISK}p2 /mnt/var/cache
mount ${DISK}p1 /mnt/boot/efi


pacstrap -K /mnt base linux linux-firmware btrfs-progs sudo nano vim networkmanager grub efibootmgr zsh \
         hyprland wayland xorg xdg-desktop-portal-hyprland mesa wl-clipboard foot \
         network-manager-applet thunar pavucontrol xdg-utils xdg-user-dirs noto-fonts ttf-dejavu \
         lightdm lightdm-gtk-greeter rofi dunst kitty neofetch

genfstab -U /mnt >> /mnt/etc/fstab


arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "$HOSTNAME" > /etc/hostname
cat >> /etc/hosts <<HOSTS
127.0.0.1 localhost
::1       localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
HOSTS

# mkinitcpio (без encrypt)
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect keyboard keymap modconf block filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Користувач
echo "root:$PASSWORD" | chpasswd
useradd -m -G wheel -s /bin/zsh $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# LightDM
systemctl enable lightdm
systemctl enable NetworkManager
EOF


umount -R /mnt
echo "✅ Installing end. Reboot!"
