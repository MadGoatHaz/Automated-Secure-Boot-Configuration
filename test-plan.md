# Secure Boot Test Plan

## Purpose
This test plan provides a comprehensive approach to verifying the Secure Boot implementation on Arch Linux with systemd-boot configuration.

## Scope
- Test systemd-boot configuration
- Verify Secure Boot key management
- Ensure proper bootloader signing
- Validate dual-boot functionality with Windows

## Test Environment
- Arch Linux with UEFI firmware
- Systemd-boot as the primary bootloader
- Optional: Windows installation for dual-boot testing

## Test Cases

### 1. System Discovery
**Objective**: Verify that system discovery correctly identifies components.

**Test Steps**:
1. Run the setup script in SYSTEM_DISCOVERY state
2. Verify output includes:
   - Kernel version
   - Machine ID
   - UEFI boot mode
   - Bootloader type (systemd-boot/UKI)
   - Windows installation status
   - Secure Boot status
   - EFI partition information

### 2. Bootloader Configuration
**Objective**: Verify that systemd-boot is properly configured.

**Test Steps**:
- Verify `/etc/cmdline.d/default.conf` contains correct kernel parameters
- Check that UKI is generated at `/efi/EFI/Linux/arch.efi`
- Verify systemd-boot binary is signed

### 3. Secure Boot Key Management
**Objective**: Verify that Secure Boot keys are properly managed.

**Test Steps**:
1. Verify key creation: `sudo sbctl status`
2. Check that keys are enrolled with Microsoft: `sudo sbctl enroll-keys -m`
3. Verify key backup functionality

### 4. File Signing Verification
**Objective**: Ensure all required files are properly signed.

**Test Steps**:
1. Verify bootloader files are signed: `sudo sbctl verify /usr/lib/systemd/boot/efi/systemd-bootx64.efi`
2. Verify UKI is signed: `sudo sbctl verify /efi/EFI/Linux/arch.efi`
3. Verify Windows bootloader is signed (if dual-boot): `sudo sbctl verify /efi/EFI/Microsoft/Boot/bootmgfw.efi`

### 5. Pacman Hook Functionality
**Objective**: Verify that pacman hooks automatically re-sign updated components.

**Test Steps**:
1. Update kernel package: `sudo pacman -S linux`
2. Verify that UKI is automatically regenerated
3. Verify that new UKI is automatically signed

### 6. Boot Functionality
**Objective**: Ensure the system boots properly with Secure Boot enabled.

**Test Steps**:
1. Reboot into UEFI firmware settings
2. Enable Secure Boot
3. Verify system boots successfully to Arch Linux
4. Verify boot menu displays correctly

### 7. Dual-Boot Testing
**Objective**: Verify Windows bootloader is properly signed and functional.

**Test Steps**:
1. Reboot and select Windows from boot menu
2. Verify Windows boots successfully
3. Verify keyboard/mouse functionality in Windows

## Test Tools
- sbctl command-line tool
- systemd-boot utilities
- UEFI firmware interface
- Pacman package manager

## Test Schedule
- Initial testing: After implementation
- Regression testing: After system updates
- Maintenance testing: Quarterly

## Test Results Documentation
- Store test results in `/var/log/secureboot-test-results.log`
- Include timestamp, test case, expected result, and actual result
- Document any failures and remediation steps