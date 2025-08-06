# Secure Boot DBX Key Investigation Plan

## Objective
Investigate the missing DBX key issue in our Secure Boot setup that causes Windows USB input devices to fail when Secure Boot is enabled.

## Investigation Plan

### Phase 1: Understanding the Problem

1. **Review Secure Boot Key Hierarchy**:
   - Study PK, KEK, DB, and DBX key roles
   - Understand how DBX keys relate to driver signing policies

2. **Compare Key Configurations**:
   - Document current key enrollment process using `sbctl enroll-keys -m`
   - Compare with basic Windows UEFI key installation
   - Identify differences in key types and enrollment order

3. **Research Windows Driver Requirements**:
   - Study Windows Secure Boot driver signing policies
   - Understand why DBX keys might be required for USB HID drivers

### Phase 2: Technical Investigation

1. **Analyze sbctl Command Output**:
   - Run `sbctl status` before and after key enrollment
   - Check for presence/absence of DBX keys
   - Examine key enrollment logs

2. **Test Different Key Configurations**:
   - Create test environments with:
     a. Current key enrollment process
     b. Manual DBX key creation and enrollment
   - Test Windows USB functionality in both scenarios

3. **Examine UEFI Variable Storage**:
   - Use `efibootmgr` to inspect UEFI variables
   - Look for DB, DBX, and other key variables
   - Compare with working Windows UEFI installations

### Phase 3: Develop Fix Strategy

1. **Identify Optimal Key Enrollment Process**:
   - Determine the correct order for PK, KEK, DB, and DBX keys
   - Find the appropriate sbctl commands for DBX key management

2. **Create Test Implementation**:
   - Modify the setup script to include DBX key creation
   - Test in a controlled environment

3. **Validate with Windows**:
   - Test the updated script in a dual-boot setup
   - Verify USB input functionality

## Fix Plan

### Step 1: Update Key Enrollment Process

1. **Modify secure-boot-setup-improved.sh**:
   - Add DBX key creation using `sbctl create-dbx`
   - Update enrollment order to include DBX
   - Ensure proper key signing relationships

2. **Test Changes**:
   - Run the modified script in test environment
   - Verify key enrollment with `sbctl status`

### Step 2: Documentation Updates

1. **Update Setup Guide**:
   - Add section explaining DBX key importance
   - Document the updated enrollment process

2. **Enhance Troubleshooting Guide**:
   - Add DBX-related troubleshooting steps
   - Include common issues and resolutions

### Step 3: Community Engagement

1. **Gather Feedback**:
   - Test with community members having dual-boot setups
   - Collect reports on Windows USB functionality

2. **Iterate and Improve**:
   - Refine the script based on real-world testing
   - Address any edge cases or compatibility issues

## Timeline

- **Week 1**: Complete Phase 1 investigation
- **Week 2**: Conduct Phase 2 technical tests
- **Week 3**: Develop and test fix implementation
- **Week 4**: Update documentation and gather feedback

## Success Criteria

- ✅ Windows USB input devices work with Secure Boot enabled
- ✅ Secure Boot functionality remains intact for Linux
- ✅ Key enrollment process is robust and well-documented
- ✅ Community testing shows improved compatibility

## Tools Required

- sbctl command-line tool
- efibootmgr for UEFI variable inspection
- Virtual test environments (QEMU/VirtualBox)
- Dual-boot test systems (Arch Linux + Windows)

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| DBX key creation fails | Fall back to basic Windows key installation |
| Windows USB issues persist | Provide detailed troubleshooting guide |
| Linux boot problems | Maintain backup of original keys |
| Key signing conflicts | Test enrollment order thoroughly |

## Next Steps

1. Begin Phase 1 investigation immediately
2. Set up test environments for Phase 2
3. Schedule regular progress reviews
4. Prepare documentation templates for Phase 3