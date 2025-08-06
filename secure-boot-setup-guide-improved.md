# Secure Boot Setup Guide for Arch Linux with systemd-boot, systemd-boot, and sbctl

This guide provides step-by-step instructions for setting up Secure Boot on Arch Linux using either systemd-boot or systemd-boot with sbctl. This setup allows you to boot both Arch Linux and Windows with Secure Boot enabled.

**Note**: The improved automation script (`secure-boot-setup-improved.sh`) supports both bootloader configurations and handles most of the setup process.

## Prerequisites

- Arch Linux (or Arch-based distribution like EndeavourOS) with UEFI support
- Dual-boot setup with Windows (recommended)
- UEFI firmware support
- Administrative privileges (sudo access)

## Step-by-Step Instructions

### 1. Install Required Packages

First, install the necessary packages:

```bash
sudo pacman -S sbctl refind systemd-ukify
yay -S shim-signed
```

Note: shim-signed is available in the AUR, so you'll need an AUR helper like yay or paru.

### 2. Create Secure Boot Keys

Generate your own Secure Boot keys:

```bash
sudo sbctl create-keys
```

### 3. Enroll Keys with Microsoft Vendor Keys

Enroll your keys along with Microsoft's vendor keys:

```bash
sudo sbctl enroll-keys -m
```

### 4. Choose Your Bootloader Path

This guide supports two bootloader configurations:

1. **systemd-boot (recommended for multi-boot setups)**
2. **systemd-boot with Unified Kernel Images (UKI, recommended for modern systems)**

#### Option A: Install systemd-boot Bootloader

Install systemd-boot:

```bash
sudo refind-install --yes
```

#### Option B: Configure systemd-boot for UKI

If you prefer to use systemd-boot with UKIs, proceed to the systemd-boot configuration section.

### 5. Configure Bootloader with shim

Backup the original bootloader binary and replace it with shim:

```bash
# For systemd-boot
sudo cp /efi/EFI/refind/refind_x64.efi /efi/EFI/refind/refind_original.efi
sudo cp /usr/share/shim-signed/shimx64.efi /efi/EFI/refind/refind_x64.efi

# For systemd-boot
sudo cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed
```

### 6. Sign Required Files

#### For systemd-boot

Sign the kernel and systemd-boot driver files:

```bash
sudo sbctl sign -s /efi/$(cat /etc/machine-id)/$(uname -r)/linux
sudo sbctl sign -s /efi/EFI/refind/drivers_x64/btrfs_x64.efi
```

#### For systemd-boot (UKI)

Configure systemd-boot for UKI generation using the improved sbctl bundle method:

```bash
# Create kernel command line config
sudo mkdir -p /etc/cmdline.d
# Get the root filesystem UUID
ROOT_UUID=$(findmnt -no UUID /)
echo "rw rootflags=subvol=/@ root=UUID=$ROOT_UUID" | sudo tee /etc/cmdline.d/default.conf

# Generate Unified Kernel Image using sbctl bundle
sudo sbctl bundle -i /boot/amd-ucode.img -k /boot/vmlinuz-linux -f /boot/initramfs-linux.img -c /etc/cmdline.d/default.conf /efi/EFI/Linux/arch.efi

# Sign systemd-boot and UKI
sudo sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
sudo sbctl sign -s /efi/EFI/Linux/arch.efi
```

### 7. Configure Bootloader

#### For systemd-boot

Edit `/efi/EFI/refind/refind.conf` to include:

```ini
scanfor internal,external,optical,manual

# Manual boot stanza for Arch Linux with custom kernel location
menuentry "Arch Linux" {
    icon /EFI/refind/icons/os_arch.png
    volume [machine-id]
    loader /[kernel-version]/linux
    initrd /[kernel-version]/initrd
    options "[boot-options]"
}
```

#### For systemd-boot

systemd-boot with UKI doesn't require manual configuration as it automatically detects the UKI.

### 8. Create Pacman Hook for Automatic Re-signing

Create `/etc/pacman.d/hooks/99-sbctl.hook`:

```ini
[Trigger]
Type = Package
Operation = Upgrade
Target = linux*
Target = systemd
Target = refind
Target = shim-signed
Target = systemd-boot
Target = efibootmgr

[Action]
Description = Signing EFI binaries...
When = PostTransaction
Exec = /usr/bin/sbctl sign-all
Depends = sbctl
```

### 9. Enable Secure Boot in Firmware

Reboot your system and enter the UEFI firmware settings (usually by pressing F2, F12, DEL, or ESC during boot). Enable Secure Boot and save the settings.

### 10. Verify Setup

After rebooting, verify that Secure Boot is working:

```bash
sudo sbctl status
```

You should see "Secure Boot: ✓ Enabled".

## Troubleshooting

### If Linux Won't Boot

1. Check that all required files are signed:
   ```bash
   sudo sbctl verify
   ```

2. For systemd-boot with UKI, ensure the UKI (`/efi/EFI/Linux/arch.efi`) is properly signed. Note that the separate initramfs file is no longer needed since it's included in the UKI.

3. Verify that your bootloader configuration is correct. For systemd-boot, check that the UKI is properly detected and listed in the boot menu.

4. If you see "invalid PE header" errors for the initramfs, this is expected with UKI and can be ignored as long as the UKI itself is properly signed.

### If Windows Won't Boot or Keyboard/Mouse Don't Work

1. This can happen if Secure Boot is enabled but Windows bootloader isn't properly trusted.

2. Try selecting the Windows boot entry in your bootloader menu.

3. If keyboard/mouse don't work in Windows, you may need to disable Secure Boot temporarily and reinstall Windows drivers.

### If You Need to Reset Secure Boot

1. Enter UEFI firmware settings and clear Secure Boot keys.

2. Reboot and follow the setup process again.

### UKI-Specific Troubleshooting

1. **Verify UKI integrity**: Check that the UKI has a valid PE header:
   ```bash
   objdump -f /efi/EFI/Linux/arch.efi
   ```
   You should see "pe" or "pe+" in the output.

2. **Check UKI generation**: Ensure your mkinitcpio preset files are correctly configured:
   ```bash
   cat /etc/mkinitcpio.d/linux.preset
   ```
   Make sure it includes the correct preset names and that `UKI` is enabled.

3. **Regenerate UKI**: If needed, regenerate the UKI:
   ```bash
   sudo mkinitcpio -P
   sudo sbctl sign -s /efi/EFI/Linux/arch.efi
   ```

## How It Works

This setup creates a chain of trust:

1. UEFI Firmware verifies shim (signed by Microsoft)
2. shim verifies bootloader (signed by your keys)
3. bootloader loads the Unified Kernel Image (UKI) (signed by your keys)
4. UKI contains the kernel, initrd, microcode, and kernel command line in a single, verifiable package

### About Unified Kernel Images (UKI)

A Unified Kernel Image (UKI) is a single EFI executable that combines:
- The Linux kernel
- The initramfs (initial RAM filesystem)
- CPU microcode updates
- Kernel command line parameters

UKIs provide several advantages:
- **Simplified Secure Boot**: The entire boot payload is signed as a single unit
- **Improved Security**: Reduces attack surface by eliminating separate file loading
- **Modern Standard**: Recommended by systemd and Arch Linux for Secure Boot

The `sbctl bundle` command automates UKI generation by combining all components into a single EFI file that can be verified by the bootloader.

### The sbctl Bundle Process

The improved setup uses `sbctl bundle` to create UKIs:

```bash
sudo sbctl bundle -i /boot/amd-ucode.img -k /boot/vmlinuz-linux -f /boot/initramfs-linux.img -c /etc/cmdline.d/default.conf /efi/EFI/Linux/arch.efi
```

This command:
1. Combines the AMD microcode, kernel, initramfs, and command line into a single UKI
2. Creates the UKI at `/efi/EFI/Linux/arch.efi`
3. The UKI is then signed with your Secure Boot keys for verification

This approach is more reliable than the traditional kernel+initrd method and is the recommended practice for modern Arch Linux systems.

## Important Notes

- **UKI Advantage**: With the UKI approach, the entire boot payload (kernel + initrd + microcode + command line) is signed as a single unit, providing enhanced security
- Always backup your keys in a secure location
- After kernel updates, the pacman hook will automatically re-generate and re-sign the UKI
- This setup works with both Arch Linux and Windows bootloaders
- The microcode file (amd-ucode.img or intel-ucode.img) is automatically included in the UKI for CPU-specific optimizations

## Conclusion

With this setup, you can now boot both Arch Linux and Windows with Secure Boot enabled. The improved automation script handles most of the setup process, and the pacman hook ensures your system remains Secure Boot compatible after updates.