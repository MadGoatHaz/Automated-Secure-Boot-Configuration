#!/bin/bash

# Secure Boot Setup Script with State Machine Architecture
# This script implements the workflow described in Section 5.1
# States: System Discovery → Plan Generation → User Confirmation → Execution → Verification

set -e  # Exit on any error
trap 'log "Error on line $LINENO. Exiting."' ERR

# Logging infrastructure
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}
# Error handling: trap to log errors with line number and message
trap 'log "Error on line $LINENO: ${BASH_COMMAND}. Exiting."' ERR

# State machine control
current_state="SYSTEM_DISCOVERY"

log "Secure Boot Setup - State Machine Workflow"
log "========================================="
echo

# State transitions and error handling
if [[ $EUID -eq 0 ]]; then
    log "Error: Script must not be run as root"
    exit 1
fi

log "Starting in SYSTEM_DISCOVERY state"

# Check required tools
if ! command -v yay &> /dev/null; then
    log "Error: AUR helper (yay/paru) not found"
    exit 1
fi

# Check firmware type
if [ ! -d "/sys/firmware/efi" ]; then
    log "Error: System not in UEFI mode"
    exit 1
fi

current_state="PLAN_GENERATION"
log "Transitioning to PLAN_GENERATION state"

# State: PLAN_GENERATION
# ------------------------
# Generate implementation plan based on system state
# Verify all required paths and components exist

# Capture critical system metrics for later use
KERNEL_VERSION=$(uname -r)
MACHINE_ID=$(cat /etc/machine-id)
UEFI_BOOT_MODE=$(cat /sys/firmware/efi/fw_platform_size 2>/dev/null || echo "Legacy")
BOOTLOADER=$(find /efi/EFI -type f -name "grub*.efi" 2>/dev/null && echo "GRUB" || echo "systemd-boot/UKI")
WINDOWS_INSTALLATION=$(if [ -f "/efi/EFI/Microsoft/Boot/bootmgfw.efi" ]; then echo "Yes"; else echo "No"; fi)
SECURE_BOOT_STATUS=$(sudo sbctl status --quiet | grep -A1 "Secure Boot" | grep -v "Secure Boot" | tr -d ' ')
EFI_MOUNTED=$(if mountpoint -q /efi; then echo "Yes"; else echo "No"; fi)
EFI_SPACE=$(df -h /efi | tail -n1 | awk '{print $4}')
ROOT_FILESYSTEM=$(df -Th | grep '/dev/root' | awk '{print $2}')

# Log discovery results
log "System Discovery Results:"
log "--------------------------"
log "Kernel Version: $KERNEL_VERSION"
log "Machine ID: $MACHINE_ID"
log "UEFI Boot Mode: $UEFI_BOOT_MODE"
log "Bootloader: $BOOTLOADER"
log "Windows Installation: $WINDOWS_INSTALLATION"
log "Secure Boot Status: $SECURE_BOOT_STATUS"
log "EFI Partition Mounted: $EFI_MOUNTED"
log "EFI Partition Space: $EFI_SPACE"
log "Filesystem: $ROOT_FILESYSTEM"
log "Available Space: $EFI_SPACE"

log "Proposed Implementation Plan:"
log "-------------------------------"
if [ "$SECURE_BOOT_STATUS" = "enabled" ]; then
    log "⚠️  Secure Boot already enabled - key enrollment will be optional"
else
    if [ "$BOOTLOADER" = "GRUB" ]; then
        log "1. Install required packages: sbctl, grub, efibootmgr"
    else
        log "1. Install required packages: sbctl"
    fi
    log "2. Create Microsoft-enrolled Secure Boot keys"
    log "3. Configure $BOOTLOADER bootloader"
fi
if [ "$WINDOWS_INSTALLATION" = "Yes" ]; then
    log "4. Sign Windows bootloader (bootmgfw.efi)"
fi

current_state="USER_CONFIRMATION"
log "Transitioning to USER_CONFIRMATION state"

log "⚠️  CRITICAL CONFIRMATION REQUIRED ⚠️"
log "Current System Status:"
log " - Secure Boot: $SECURE_BOOT_STATUS"
log " - Windows Installation Detected: $WINDOWS_INSTALLATION"
log " - EFI Partition Mounted: $EFI_MOUNTED"
log " - Available EFI Space: $EFI_SPACE"
log "--------------------------------------------------"
log "This operation will:"
log "1. Modify Secure Boot keys (if not already enabled)"
log "2. Sign bootloaders and kernels"
log "3. Create persistent pacman hooks"
log "4. Require firmware setup mode password (if configured)"

# Explicit confirmation to prevent accidental execution
while true; do
    read -p "Type 'SECURE_BOOT' to confirm and continue: " CONFIRMATION
    if [ "$CONFIRMATION" = "SECURE_BOOT" ]; then
        break
    elif [ "$CONFIRMATION" = "exit" ]; then
        log "Operation cancelled by user"
        exit 0
    else
        log "Invalid confirmation - please type 'SECURE_BOOT' or 'exit'"
    fi
done

current_state="EXECUTION"
log "Transitioning to EXECUTION state"

# State: EXECUTION
# -------------------
# Execute the core implementation steps

if [ "$SECURE_BOOT_STATUS" = "disabled" ]; then
    log "Creating Secure Boot keys..."
    sudo sbctl create-keys
else
    log "Secure Boot already enabled - skipping key creation"
fi

log "Enrolling keys with Microsoft vendor keys..."
sudo sbctl enroll-keys -m

if [ "$BOOTLOADER" = "GRUB" ]; then
    log "Configuring GRUB for Secure Boot..."
    # Determine filesystem types
    ROOT_FS=$(df -Th / | awk 'NR==2 {print $2}')
    BOOT_FS=$(df -Th /boot | awk 'NR==2 {print $2}' 2>/dev/null || echo "$ROOT_FS")
    
    # Build module string based on system configuration
    GRUB_MODULES="part_gpt part_msdos ext2 fat"
    [ "$ROOT_FS" = "btrfs" ] && GRUB_MODULES+=" btrfs"
    [ "$ROOT_FS" = "xfs" ] && GRUB_MODULES+=" xfs"
    [ "$BOOT_FS" = "btrfs" ] && ! [[ "$GRUB_MODULES" =~ "btrfs" ]] && GRUB_MODULES+=" btrfs"
    [ "$BOOT_FS" = "xfs" ] && ! [[ "$GRUB_MODULES" =~ "xfs" ]] && GRUB_MODULES+=" xfs"
    
    # Check for LVM volumes
    if lsblk -f | grep -q 'lvm'; then
        GRUB_MODULES+=" lvm"
    fi
    
    # Check for LUKS encryption
    if cryptsetup status /dev/mapper/$(lsblk -o NAME / | tail -n1) &>/dev/null; then
        GRUB_MODULES+=" cryptodisk luks gcry_rijndael gcry_sha256"
        log "Detected LUKS encryption - adding required GRUB modules"
    fi
    
    # Install GRUB with detected modules
    log "Installing GRUB with modules: $GRUB_MODULES"
    sudo grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --modules="$GRUB_MODULES" --sbat=/usr/share/grub/sbat.csv --removable
    
    # Sign GRUB EFI binary
    log "Signing GRUB bootloader..."
    sudo sbctl sign -s /efi/EFI/GRUB/grubx64.efi
    
    # Sign kernel for GRUB
    log "Signing kernel for GRUB..."
    sudo sbctl sign -s /boot/vmlinuz-linux
else
    log "Configuring systemd-boot for Secure Boot..."
    # Create kernel command line config
    sudo mkdir -p /etc/cmdline.d
    # Get the root filesystem UUID
    ROOT_UUID=$(findmnt -no UUID /)
    echo "rw rootflags=subvol=/@ root=UUID=$ROOT_UUID" | sudo tee /etc/cmdline.d/default.conf

    # Generate Unified Kernel Image using sbctl bundle
    log "Generating Unified Kernel Image (UKI)..."
    sudo sbctl bundle -i /boot/amd-ucode.img -k /boot/vmlinuz-linux -f /boot/initramfs-linux.img -c /etc/cmdline.d/default.conf /efi/EFI/Linux/arch.efi

    # Sign systemd-boot
    log "Signing systemd-boot..."
    sudo sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi

    # Sign Unified Kernel Image
    log "Signing Unified Kernel Image..."
    sudo sbctl sign -s /efi/EFI/Linux/arch.efi
fi

# Sign Windows bootloader if detected
if [ "$WINDOWS_INSTALLATION" = "Yes" ]; then
    log "Signing Windows bootloader..."
    sudo sbctl sign -s /efi/EFI/Microsoft/Boot/bootmgfw.efi
fi

# Ensure bootloader installation succeeded (if applicable)
if [ "$BOOTLOADER" = "GRUB" ]; then
    if ! command -v grub-install &>/dev/null; then
        log "Error: GRUB installation failed or grub-install not found."
        exit 1
    fi
elif [ "$BOOTLOADER" = "systemd-boot/UKI" ]; then
    if [ ! -f "/usr/lib/systemd/boot/efi/systemd-bootx64.efi" ]; then
        log "Error: systemd-boot binary not found."
        exit 1
    fi
fi

# Kernel signing handled within bootloader-specific configuration blocks

# No rEFInd-specific configuration needed - using detected bootloader
# No rEFInd-specific configuration needed - using detected bootloader

log "Creating dynamic pacman hooks for automatic re-signing..."
sudo mkdir -p /etc/pacman.d/hooks

# Build hook content based on detected bootloader
HOOK_CONTENT="[Trigger]
Type = Package
Operation = Upgrade
Target = linux*"

if [ "$BOOTLOADER" = "GRUB" ]; then
    HOOK_CONTENT+=$'\n'"Target = grub"
    HOOK_CONTENT+=$'\n'"Target = grub-install"
else
    HOOK_CONTENT+=$'\n'"Target = systemd"
    HOOK_CONTENT+=$'\n'"Target = mkinitcpio"
fi

if [ "$WINDOWS_INSTALLATION" = "Yes" ]; then
    HOOK_CONTENT+=$'\n'"Target = efibootmgr"
fi

HOOK_CONTENT+=$'\n\n'"[Action]
Description = Signing EFI binaries for $BOOTLOADER with Secure Boot...
When = PostTransaction
Exec = /usr/bin/sbctl sign-all
Depends = sbctl"

echo -e "$HOOK_CONTENT" | sudo tee /etc/pacman.d/hooks/99-sbctl.hook >/dev/null

echo
current_state="VERIFICATION"
log "Transitioning to VERIFICATION state"

# State: VERIFICATION
# --------------------
# Final verification and reporting

log "Final status verification:"
sudo sbctl status

log "File signing verification:"
sudo sbctl verify
if [ "$WINDOWS_INSTALLATION" = "Yes" ]; then
    log "Windows bootloader verification:"
    sudo sbctl verify /efi/EFI/Microsoft/Boot/bootmgfw.efi
fi

log "Secure Boot implementation complete and verified."
log "Review secure-boot-setup-guide.md for post-installation requirements."
echo
echo "Next steps:"
echo "1. Reboot and enable Secure Boot in UEFI settings"
echo "2. Verify functionality with: sudo sbctl status"
# End of script