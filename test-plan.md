# Secure Boot Implementation Test Plan

## Purpose
This test plan provides a comprehensive approach to verifying the Secure Boot implementation on Arch Linux with both rEFInd and systemd-boot configurations.

## Scope
- Test both rEFInd and systemd-boot configurations
- Verify Secure Boot key management
- Test bootloader functionality
- Validate kernel and driver signing
- Test Windows dual-boot compatibility
- Verify automatic re-signing after updates

## Test Environment
- Arch Linux (EndeavourOS or similar)
- UEFI firmware with Secure Boot capability
- Dual-boot configuration with Windows
- EFI System Partition (ESP) mounted at /efi

## Test Cases

### 1. Secure Boot Key Management
**Objective**: Verify that Secure Boot keys are properly created and enrolled.

**Test Steps**:
1. Run `sudo sbctl status` and verify:
   - Setup Mode: Enabled (before enrollment)
   - Secure Boot: Enabled (after enrollment)
   - Vendor Keys: microsoft
2. Verify key files exist in `/etc/sbkeys/`
3. Check key enrollment with `sudo sbctl list-keys`

**Expected Results**:
- Keys are successfully created and enrolled
- sbctl status shows correct Secure Boot status

### 2. Bootloader Configuration
**Objective**: Verify that both rEFInd and systemd-boot are properly configured.

**Test Steps**:
- For rEFInd:
  1. Verify `/efi/EFI/refind/refind.conf` contains correct scanfor directive
  2. Check that shim is properly installed as `/efi/EFI/refind/refind_x64.efi`
  3. Verify rEFInd menu displays correctly

- For systemd-boot:
  1. Verify systemd-boot is installed at `/efi/EFI/systemd/systemd-bootx64.efi`
  2. Check UKI generation with `ls /efi/EFI/Linux/arch.efi`
  3. Verify boot entries with `bootctl list`

**Expected Results**:
- Bootloaders are properly installed and configured
- No errors in bootloader configuration files

### 3. File Signing
**Objective**: Verify that all required files are signed.

**Test Steps**:
1. Run `sudo sbctl verify` and check:
   - Kernel files are signed
   - Bootloader files are signed
   - rEFInd drivers are signed (for rEFInd configuration)
   - Windows bootloader is signed (if dual-boot)

**Expected Results**:
- All required files show as signed (✓)
- No unsigned files reported

### 4. Boot Functionality
**Objective**: Verify that the system boots correctly with Secure Boot enabled.

**Test Steps**:
1. Reboot the system
2. Enter UEFI firmware settings
3. Enable Secure Boot
4. Save settings and exit
5. Verify system boots to Arch Linux
6. Check boot process with `journalctl -b`

**Expected Results**:
- System boots successfully with Secure Boot enabled
- No boot errors or Secure Boot violations

### 5. Windows Dual-Boot
**Objective**: Verify that Windows remains bootable with Secure Boot enabled.

**Test Steps**:
1. Reboot and select Windows from boot menu
2. Verify Windows boots successfully
3. Check Windows boot with Secure Boot enabled

**Expected Results**:
- Windows boots without issues
- No boot errors or Secure Boot violations

### 6. Automatic Re-signing
**Objective**: Verify that the pacman hook automatically re-signs files after updates.

**Test Steps**:
1. Update kernel with `sudo pacman -Syu linux`
2. Verify new kernel is signed: `ls /efi/[machine-id]/[new-kernel-version]/`
3. Run `sudo sbctl verify` to check new files
4. Update systemd with `sudo pacman -Syu systemd`
5. Verify systemd-boot is still signed

**Expected Results**:
- New kernel is automatically signed
- systemd-boot remains signed after systemd update
- No unsigned files after updates

### 7. Error Handling
**Objective**: Verify that the system handles errors gracefully.

**Test Steps**:
1. Run script with missing dependencies
2. Test script with incorrect paths
3. Verify error messages are clear and helpful

**Expected Results**:
- Script provides clear error messages
- Graceful degradation without data loss

### 8. Documentation Accuracy
**Objective**: Verify that all documentation matches the implementation.

**Test Steps**:
1. Compare setup guide with actual implementation
2. Verify all commands in documentation work
3. Check that all referenced files exist

**Expected Results**:
- Documentation accurately reflects implementation
- All commands execute successfully

## Test Schedule
| Test Case | Estimated Duration | Priority |
|-----------|--------------------|----------|
| Secure Boot Key Management | 30 minutes | High |
| Bootloader Configuration | 45 minutes | High |
| File Signing | 30 minutes | High |
| Boot Functionality | 60 minutes | Critical |
| Windows Dual-Boot | 45 minutes | Medium |
| Automatic Re-signing | 30 minutes | High |
| Error Handling | 30 minutes | Medium |
| Documentation Accuracy | 30 minutes | Medium |

## Test Tools
- sbctl
- refind-install
- bootctl
- journalctl
- pacman
- UEFI firmware interface

## Test Results Documentation
All test results will be documented in a separate `test-results.md` file, including:
- Test case ID
- Test date
- Actual results
- Pass/Fail status
- Any observed issues

## Test Completion Criteria
- All critical tests pass
- No boot errors with Secure Boot enabled
- Both Linux and Windows boot successfully
- Automatic re-signing works correctly
- Documentation is accurate and complete

## Maintenance and Update Plan
- Retest after major system updates (kernel, bootloader, systemd)
- Verify Secure Boot functionality after firmware updates
- Periodically check for unsigned files with `sudo sbctl verify`

This test plan ensures comprehensive verification of the Secure Boot implementation, covering all critical aspects of the setup and providing a robust foundation for maintaining system security.