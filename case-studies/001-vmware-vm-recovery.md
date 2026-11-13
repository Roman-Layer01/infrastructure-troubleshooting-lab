# Case Study 001 — VMware ESXi Linux VM Recovery

**Category:** Virtualization / Infrastructure Troubleshooting  
**Platform:** VMware ESXi / vSphere Host Client  
**Guest Operating System:** Ubuntu Linux  
**Environment:** Remote, non-production technical assessment  
**Assessment Date:** November 4, 2026  
**Outcome:** VM registered, virtual disk configuration repaired, and Ubuntu successfully booted

---

## 1. Executive Summary

During a remote infrastructure technical assessment, I was tasked with registering an existing Linux virtual machine in VMware ESXi and ensuring it could power on successfully.

The virtual machine's files already existed on an ESXi datastore, but the VM was not registered in the hypervisor inventory.

After locating and registering its existing `.vmx` configuration, I attempted to power on the machine. The startup failed because the configuration referenced a virtual disk filename that did not exist.

The recovery was complicated by the ESXi web client's disk attachment controls, which appeared blank and abnormally small when attempting to attach the correct existing disk.

Rather than rebuilding the VM or modifying its virtual disk contents, I used SSH through PuTTY to inspect the datastore, validate the VMDK disk chain, back up the VM configuration, and restore the correct disk attachment.

After reloading the configuration, the VM powered on successfully and Ubuntu reached its login prompt.

This case study documents the investigation, underlying configuration issue, recovery commands, and verified outcome.

## 2. Environment Overview

| Component | Description |
|---|---|
| Hypervisor | VMware ESXi |
| Management interface | ESXi Host Client |
| Guest OS | Ubuntu Linux |
| VM identifier | `ubuntu1804` |
| Datastore | `datastore1` |
| Virtual disk | VMDK |
| Virtual SCSI controller | SCSI 0:0 |
| Administrative access | Windows RDP session and PuTTY SSH |
| Environment | Non-production technical assessment |

The administrative workflow involved remotely accessing a Windows management machine, opening the ESXi web interface, and subsequently establishing SSH access directly to the ESXi host.

Original hostnames, IP addresses, organization identifiers, and credentials have been omitted.

## 3. Assessment Objective

The assigned task was to:

1. Locate an existing Linux virtual machine stored alongside an already registered Windows VM.
2. Register the Linux VM with ESXi.
3. Power on the VM.
4. Verify successful startup.

The goal was recovery of the existing virtual machine, not installation of a new operating system.

Preserving the existing virtual disk was therefore an important consideration.

## 4. Discovering the Virtual Machine

The Linux VM was initially absent from the ESXi virtual machine inventory.

Using the ESXi Host Client datastore browser, I navigated to the datastore containing the existing virtual machine files.

The relevant directory was:

```text
/vmfs/volumes/datastore1/ubuntu1804/
```

The directory contained the VM configuration file:

```text
ubuntu1804.vmx
```

The existing VM configuration was registered through the ESXi interface.

Registration succeeded.

However, attempting to power on the machine produced an error involving a missing virtual disk.

## 5. Finding 1 — Invalid Virtual Disk Reference

The registered VM configuration referenced:

```text
ubuntu1804-file.vmdk
```

However, the existing virtual disk was named:

```text
ubuntu1804.vmdk
```

This mismatch prevented ESXi from opening the configured virtual disk during startup.

### Technical Interpretation

A VMware `.vmx` file defines the virtual machine's hardware configuration, including the virtual disks associated with its controllers.

For example:

```ini
scsi0:0.present = "TRUE"
scsi0:0.fileName = "ubuntu1804-file.vmdk"
scsi0:0.deviceType = "scsi-hardDisk"
```

The filename in the original configuration did not match the existing disk.

The appropriate recovery was to restore the correct association, not to create a replacement disk.

## 6. Attempted Recovery Through the ESXi Web Client

The initial approach was to correct the disk attachment through the graphical management interface.

The intended workflow was:

1. Open the VM's hardware configuration.
2. Remove the invalid virtual disk reference.
3. Preserve the underlying datastore files.
4. Select **Add hard disk → Existing hard disk**.
5. Choose the existing `ubuntu1804.vmdk`.
6. Attach it to SCSI controller 0 at SCSI 0:0.

However, the disk attachment editor exhibited unexpected behavior.

Several controls were blank or abnormally narrow, and the interface did not reliably display the selected disk's controller and capacity information.

Browser zoom adjustment, refreshing the interface, and retrying the attachment did not resolve the behavior.

The invalid disk attachment was removed without deleting datastore files, but the existing disk could not be reliably reattached through the web editor.

This prompted a command-line investigation.

## 7. Investigating the Existing VMDK

The existing disk descriptor was examined.

It referenced a backing file:

```text
RW 33554432 VMFS "ubuntu1804-flat.vmdk"
```

This describes a virtual disk with 33,554,432 sectors.

Assuming 512-byte sectors, the provisioned capacity is 16 GiB.

The datastore also contained the corresponding backing file.

### Why This Mattered

VMware virtual disks may consist of a small descriptor and a larger backing extent.

The descriptor contains information about the disk's layout and associated data files.

Finding a valid descriptor is useful, but it does not independently guarantee that the full disk chain is intact.

Additional validation was required before modifying the VM configuration.

## 8. Switching to ESXi SSH

Because the web client was not reliably populating the disk attachment controls, I used PuTTY from the remote Windows management environment to establish an SSH session with the ESXi host.

This provided direct access to the hypervisor's filesystem and management utilities.

### Inspect Datastore Contents

```bash
ls -lh /vmfs/volumes/datastore1/ubuntu1804/
```

The inspection confirmed that the existing virtual disk and its backing file were present.

### Inspect the VM Configuration

```bash
cat /vmfs/volumes/datastore1/ubuntu1804/ubuntu1804.vmx
```

The configuration inspection showed that the VM retained its SCSI controller configuration but no longer had an attached hard disk after the unsuccessful graphical editing attempts.

The next objective was to verify the existing disk before restoring its reference.

## 9. Finding 2 — Existing Virtual Disk Was Consistent

The VMDK chain was checked using ESXi's `vmkfstools` utility:

```bash
vmkfstools -e /vmfs/volumes/datastore1/ubuntu1804/ubuntu1804.vmdk
```

Result:

```text
Disk chain is consistent.
```

This was a critical finding.

It indicated that VMware could validate the existing virtual disk chain, reducing the likelihood that rebuilding or replacing the disk was necessary.

The problem was therefore narrowed to the VM's virtual disk association rather than a demonstrated disk-chain inconsistency.

## 10. Identifying the VM and Verifying Its State

The registered virtual machines were listed:

```bash
vim-cmd vmsvc/getallvms
```

The recovered transcript identified the Ubuntu VM with numeric ID:

```text
9
```

The VM's power state was then checked:

```bash
vim-cmd vmsvc/power.getstate 9
```

This was part of the preparation for safely correcting the VM configuration while the machine was powered off.

The confirmed repair sequence included creating a backup before making the targeted change.

## 11. Correcting the VMX Configuration

The recovery was performed directly through the ESXi command line.

### Step 1 — Navigate to the VM Directory

```bash
cd /vmfs/volumes/datastore1/ubuntu1804
```

### Step 2 — Back Up the Existing Configuration

```bash
cp -p ubuntu1804.vmx ubuntu1804.vmx.before-disk-fix
```

This preserved a copy of the current configuration before the disk attachment was restored.

### Step 3 — Restore the Existing Disk Reference

The following configuration entries were appended to the VMX file:

```bash
cat >> ubuntu1804.vmx <<'EOF'
scsi0:0.present = "TRUE"
scsi0:0.fileName = "ubuntu1804.vmdk"
scsi0:0.deviceType = "scsi-hardDisk"
EOF
```

These entries associated the existing virtual disk with the VM at SCSI 0:0.

The `>>` operator appended text to the configuration file rather than overwriting its existing contents.

This operation was appropriate to the observed state of this specific VM configuration. It is not intended as a universal repair procedure for all VMware disk attachment problems.

### Step 4 — Reload the VM Configuration

```bash
vim-cmd vmsvc/reload 9
```

Reloading instructed ESXi to reread the modified virtual machine configuration.

### Step 5 — Power On the VM

```bash
vim-cmd vmsvc/power.on 9
```

The power-on operation returned without an error in the documented session.

## 12. Recovery Verification

After the configuration repair, the VM's operational state was checked.

```bash
vim-cmd vmsvc/power.getstate 9
```

The VM was also inspected through the ESXi Host Client console.

### Confirmed Results

- The VM remained registered in ESXi.
- The existing VMDK was correctly associated with the VM.
- The VM powered on successfully.
- Ubuntu reached its login prompt.
- Cloud-init completed.
- The ESXi web client subsequently displayed the attached disk as a 16 GB, thin-provisioned VMDK on SCSI 0:0.

The guest operating system was successfully booted without rebuilding the VM or replacing its disk contents.

## 13. Additional Finding — Web Client Behavior

The ESXi web client initially displayed blank, abnormally small disk-attachment controls.

The exact technical cause was not established during the assessment.

After the VMX configuration was corrected and reloaded, the web client displayed the existing virtual disk information normally.

The interviewer later confirmed that the unusual interface behavior was intentional as part of the exercise.

However, this confirmation does not establish the specific mechanism used to produce the interface behavior.

The important troubleshooting lesson was that an unreliable management interface should not be confused with evidence of damaged virtual disk contents.

## 14. Root Cause Analysis

### Primary Fault

The VM configuration referenced a nonexistent virtual disk:

```text
ubuntu1804-file.vmdk
```

The existing disk was:

```text
ubuntu1804.vmdk
```

This prevented the VM from booting successfully after registration.

### Additional Complication

The graphical disk-attachment workflow did not reliably populate the necessary controls.

After unsuccessful attempts through the web interface, SSH-based inspection and configuration recovery provided an alternative management path.

### Resolution

The existing virtual disk was validated, its reference restored in the VMX configuration, and the virtual machine configuration reloaded.

The VM subsequently powered on and booted successfully.

## 15. Troubleshooting Summary

| Stage | Action | Result |
|---|---|---|
| Discovery | Located `ubuntu1804.vmx` | Existing VM found |
| Registration | Registered VM in ESXi | Successful |
| Initial startup | Attempted power-on | Failed |
| Error investigation | Inspected disk reference | Incorrect VMDK filename |
| GUI remediation | Attempted existing-disk attachment | Controls failed to populate |
| Disk inspection | Examined VMDK descriptor and backing file | Existing disk identified |
| ESXi SSH | Inspected datastore and VMX | Disk association absent |
| Disk validation | Executed `vmkfstools -e` | Disk chain consistent |
| Configuration backup | Copied VMX file | Backup created |
| Repair | Restored SCSI 0:0 VMDK reference | Configuration corrected |
| Reload | Executed `vim-cmd vmsvc/reload` | Configuration reloaded |
| Recovery | Powered on VM | Successful |
| Validation | Inspected VM console | Ubuntu login prompt displayed |

## 16. Technical Lessons Learned

### Registration Is Not the Same as Recovery

Registering an existing VM adds it to ESXi's inventory, but does not guarantee that its referenced disks and hardware configurations are valid.

### Validate Existing Storage Before Replacing It

The VMDK descriptor and backing file existed, and the disk-chain validation passed.

This supported a targeted configuration repair rather than unnecessary disk reconstruction.

### Management Interface Failures Can Obscure Simple Problems

The graphical editor introduced an additional troubleshooting obstacle.

SSH access allowed the underlying VM configuration to be examined independently.

### Back Up Configuration Before Editing

Creating a VMX backup provided a recovery point before modifying virtual hardware references.

### Verify the Operating System Actually Boots

A successful registration or power-on command alone does not establish that the guest OS is operational.

The final Ubuntu console verification was necessary to confirm the assigned recovery objective.

### Troubleshooting Is About Isolating Faults

The underlying repair required only restoring the correct virtual disk association.

The difficult part was identifying the mismatch, proving the existing disk was intact, and working around an unreliable management interface.

## 17. Outcome

The assessment objective was completed.

The existing Linux VM was registered, its incorrect virtual disk reference was repaired, and the guest successfully booted.

The recovery preserved the original virtual disk contents and avoided reinstalling the operating system.

This exercise demonstrated practical VMware administration involving datastore investigation, VMX configuration, virtual disk validation, SSH management, and recovery verification.

## 18. Future Lab Reproduction

A similar scenario can be reproduced in a personally controlled VMware environment.

Potential exercises include:

- Unregistering and re-registering an existing VM
- Simulating an invalid virtual disk reference
- Inspecting VMX configuration files
- Validating virtual disk chains
- Restoring disk associations
- Confirming successful guest startup

Independent reproduction would provide additional screenshots and command output without relying on the original assessment infrastructure.

---

**Case Study Status:** Completed. Root cause, remediation, and successful guest boot documented from the recovered assessment transcript.
