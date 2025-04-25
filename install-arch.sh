#!/bin/bash
set -e


DISK="/dev/nvme0n1"
CRYPT_NAME="cryptroot"
HOSTNAME="archbook"
USERNAME="anon"
PASSWORD="anon"   
LOCALE="en_US.UTF-8"
TIMEZONE="Europe/Kyiv"


sgdisk --zap-all $DISK
sgdisk -n1:0:+512M -t1:ef00 -c1:EFI $DISK
sgdisk -n2:0:0     -t2:8300 -c2:ROOT $DISK


cryptsetup luksFormat ${DISK}p2
cryptsetup open ${DISK}p2 $CRYPT_NAME

mkfs.fat -F32 ${DISK}p1
mkfs.btrfs /dev/mapper/$CRYPT_NAME


mount /dev/mapper/$CRYPT_NAME /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
umount /mnt


mount -o noatime,compress=zstd,subvol=@ /dev/mapper/$CRYPT_NAME /mnt
mkdir -p /mnt/{boot/efi,home,.snapshots,var/log,var/cache}
mount -o noatime,compress=zstd,subvol=@home /dev/mapper/$CRYPT_NAME /mnt/home
mount -o noatime,compress=zstd,subvol=@snapshots /dev/mapper/$CRYPT_NAME /mnt/.snapshots
mount -o noatime,compress=zstd,subvol=@log /dev/mapper/$CRYPT_NAME /mnt/var/log
mount -o noatime,compress=zstd,subvol=@cache /dev/mapper/$CRYPT_NAME /mnt/var/cache
mount ${DISK}p1 /mnt/boot/efi


pacstrap -K /mnt base linux linux-firmware btrfs-progs sudo nano vim networkmanager grub efibootmgr zsh \
          hyprland wayland xorg xdg-desktop-portal-hyprland mesa wl-clipboard foot \
          network-manager-applet thunar pavucontrol xdg-utils xdg-user-dirs noto-fonts ttf-dejavu \
          lightdm lightdm-gtk-greeter rofi dunst kitty neofetch


genfstab -U /mnt >> /mnt/etc/fstab


arch-chroot /mnt /bin/bash <<EOF

# Час і локаль
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

# mkinitcpio
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect keyboard keymap modconf block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# GRUB
UUID=\$(blkid -s UUID -o value ${DISK}p2)
sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=\$UUID:cryptroot root=/dev/mapper/cryptroot\"|" /etc/default/grub
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
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

# Готово
umount -R /mnt
cryptsetup close $CRYPT_NAME
echo "✅ Installing ends. Reboot."
