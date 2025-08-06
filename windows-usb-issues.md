# Windows USB Input Issues with Secure Boot

## Overview
This document addresses a common issue where keyboard and mouse devices stop working on the Windows login screen when Secure Boot is enabled in a dual-boot setup with Arch Linux. This is a Windows-specific driver issue, not a Linux problem.

## Root Cause
Secure Boot ensures only digitally signed and trusted drivers load during boot. If a USB HID (keyboard/mouse) driver or filter driver is:

- Unsigned
- Modified
- Incompatible with UEFI/Secure Boot
- Conflicting with third-party software (e.g., antivirus, RGB control, USB hubs)

...then Windows may fail to load it under Secure Boot enforcement, leaving USB input devices non-functional at the login screen.

## Solutions

### 1. Boot into Windows (Temporarily Disable Secure Boot)
1. Enter UEFI/BIOS
2. Disable Secure Boot
3. Boot into Windows normally (your keyboard/mouse should work)
4. Re-enable Secure Boot only after fixing the issue

### 2. Check for Problematic USB Drivers (Code 52)
1. Once in Windows:
   - Press Win + X → Device Manager
   - Expand "Human Interface Devices" and "Universal Serial Bus controllers"
   - Look for any device with a yellow warning icon and Error Code 52 ("Windows cannot verify the digital signature")
   - Right-click and uninstall those devices. Check “Delete the driver software” if prompted
   - Reboot with Secure Boot enabled to let Windows reinstall clean, signed drivers

### 3. Remove Corrupted Driver Registry Keys
**Warning: Edit the registry at your own risk.**

1. Press Win + R, type regedit, and run as administrator
2. Navigate to:
   ```
   HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{36fc9e60-c465-11cf-8056-444553540000}
   ```
3. In the right pane, look for UpperFilters or LowerFilters
4. Delete these entries if present
5. Reboot with Secure Boot enabled

This key controls HID class drivers. Third-party software (e.g., Razer Synapse, Logitech G Hub) sometimes adds unsigned filters that break under Secure Boot.

### 4. Update Motherboard Firmware (UEFI/BIOS)
1. Visit your motherboard manufacturer’s website
2. Download and install the latest BIOS update
3. Ensure "Legacy USB Support" or "XHCI Hand-off" is enabled in BIOS (even with Secure Boot on)

### 5. Use Remote Desktop (If You Can't Log In)
1. If you can’t access Windows locally:
   - Enable Remote Desktop before disabling Secure Boot (if possible)
   - From another device, connect via mstsc and perform the fixes above

### 6. Clean Boot & Disable Startup Software
1. Perform a clean boot:
   ```
   msconfig → Selective startup → disable all non-Microsoft services
   ```
2. Uninstall software like:
   - Corsair iCUE
   - ASUS Armoury Crate
   - MSI Dragon Center
   - Old antivirus tools

## Why It Works in Arch but Not Windows
- Arch Linux uses a minimal initramfs and standard open-source drivers that are not subject to Secure Boot driver signing in the same way
- Windows strictly enforces driver signature verification when Secure Boot is on—especially for HID and storage filters

## Final Recommendation
1. Disable Secure Boot → Boot to Windows
2. Uninstall problematic drivers
3. Delete UpperFilters/LowerFilters in registry
4. Update BIOS and Windows
5. Re-enable Secure Boot and test

This resolves the issue in most dual-boot setups.