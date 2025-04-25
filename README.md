# Arch Linux Automated Installation Scripts

This repository contains two bash scripts to automate Arch Linux installation:

---

## 1. install-arch.sh

🛡️ Full system installation with **LUKS encryption** and **BTRFS**:

- Full disk wipe
- LUKS disk encryption
- BTRFS subvolumes (@, @home, @snapshots, @log, @cache)
- Base Arch Linux system installation
- Hyprland Wayland compositor setup
- LightDM display manager enabled
- User creation (default user: `anon`)
- Sudo enabled for the `wheel` group
- Full auto-configuration: timezone, locale, hostname, GRUB with encryption support

---

## 2. install-unencrypted.sh

⚡ Fast and clean installation **without encryption**:

- Full disk wipe
- Pure BTRFS setup (no encryption)
- Base Arch Linux system installation
- Hyprland Wayland compositor setup
- LightDM display manager enabled
- User creation (default user: `anon`)
- Sudo enabled for the `wheel` group
- Full auto-configuration: timezone, locale, hostname, GRUB standard boot

---

## ⚠️ Warning

Both scripts will **completely erase** the target disk (`/dev/nvme0n1`)  
Make sure to back up all important data before running them!

---

## 🚀 Usage Example

In Live Arch environment:

```bash
# For encrypted installation:
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install-encrypted.sh
chmod +x install-encrypted.sh
./install-encrypted.sh

# For unencrypted installation:
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install-unencrypted.sh
chmod +x install-unencrypted.sh
./install-unencrypted.sh


// badasya
