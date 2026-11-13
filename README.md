# Infrastructure Troubleshooting Lab

### VMware ESXi | Ubuntu Linux | Apache | Infrastructure Recovery

A hands-on technical portfolio documenting real infrastructure troubleshooting, Linux server administration, VMware virtualization, and systematic fault isolation.

This repository features two case studies based on a remote, non-production infrastructure technical assessment completed in November 2026.

Both exercises involved investigating existing systems, identifying configuration problems, applying targeted corrections, and validating the results.

## Technical Highlights

- Diagnosed multiple independent Apache web-server configuration issues.
- Identified and corrected an incorrect HTTP listening port.
- Investigated active and persistent Linux firewall rules.
- Diagnosed HTTP 403 errors through Apache logs and filesystem permissions.
- Recovered an unregistered VMware Linux virtual machine.
- Identified an invalid VMDK filename reference.
- Verified virtual disk consistency using `vmkfstools`.
- Repaired VMX configuration through ESXi SSH.
- Successfully booted the recovered Ubuntu virtual machine.

## Case Study 001 — VMware ESXi Linux VM Recovery

**Status: Completed — VM successfully recovered**

An existing Ubuntu virtual machine needed to be registered with VMware ESXi and powered on.

Registration succeeded, but the initial startup failed because the VM configuration referenced a nonexistent virtual disk.

The ESXi web client's disk attachment controls also behaved unexpectedly, making graphical remediation unreliable.

### Investigation and Resolution

1. Located the existing VMX configuration in the ESXi datastore.
2. Registered the Linux VM with ESXi.
3. Identified an incorrect VMDK filename reference.
4. Investigated the disk descriptor and backing file.
5. Used PuTTY and SSH to inspect the datastore and VM configuration.
6. Validated the existing virtual disk chain.
7. Backed up the VMX configuration.
8. Restored the correct disk attachment at SCSI 0:0.
9. Reloaded the configuration and powered on the VM.
10. Confirmed Ubuntu successfully booted to its login prompt.

### Key Technical Commands

```bash
vmkfstools -e /vmfs/volumes/datastore1/ubuntu1804/ubuntu1804.vmdk
vim-cmd vmsvc/getallvms
vim-cmd vmsvc/reload 9
vim-cmd vmsvc/power.on 9
```

**Outcome:** Successfully recovered the existing virtual machine without rebuilding the operating system or modifying the virtual disk contents.

[Read the full VMware recovery case study](case-studies/001-vmware-vm-recovery.md)

---

## Case Study 002 — Ubuntu Apache Web Server Recovery

**Status: Local HTTP recovery confirmed**

An Ubuntu 22.04.4 LTS virtual machine hosted a website that was initially inaccessible.

The investigation revealed multiple independent configuration problems affecting web-service availability.

### Identified Issues

| Issue | Finding | Resolution |
|---|---|---|
| Apache service | Stopped and disabled | Started and enabled |
| Listening port | Configured for TCP 81 | Corrected to TCP 80 |
| Firewall | Explicit DROP rule blocking TCP 80 | Removed active and persistent rule |
| File permissions | `index.html` unreadable by Apache | Corrected permissions to `644` |
| Verification content | Required page marker absent | Content update procedure documented |

### Investigation

The troubleshooting process involved:

- Establishing SSH connectivity.
- Checking service status with `systemctl`.
- Inspecting network listeners using `ss`.
- Testing local HTTP availability with `curl`.
- Reviewing `iptables` and `nftables` rules.
- Inspecting Apache virtual-host configuration.
- Examining Apache error logs.
- Identifying file-access failures.
- Applying targeted configuration corrections.

### Key Technical Commands

```bash
sudo systemctl --no-pager --full status apache2
sudo ss -lntp
sudo iptables -S
sudo nft list ruleset
sudo apache2ctl -S
sudo apache2ctl configtest
sudo journalctl -u apache2 --no-pager
```

**Outcome:** Apache was restored to a state where the local HTTP endpoint returned `200 OK`. The final external-browser validation is not preserved in the recovered transcript.

[Read the full Ubuntu Apache recovery case study](case-studies/002-ubuntu-web-service.md)

---

## Troubleshooting Methodology

These exercises follow a consistent approach to infrastructure incidents:

**1. Identify**

Establish the reported issue and expected system behavior.

**2. Investigate**

Collect evidence using service status, logs, networking tools, configuration inspection, and management utilities.

**3. Isolate**

Distinguish between independent failure layers rather than assuming a single root cause.

**4. Remediate**

Apply targeted corrective actions, preserving existing configurations and data where possible.

**5. Validate**

Verify functionality through service checks, application responses, and guest operating system startup.

**6. Document**

Record commands, observed results, corrective actions, remaining uncertainties, and lessons learned.

## Technologies Used

| Technology | Application |
|---|---|
| VMware ESXi | Hypervisor and virtual machine management |
| VMware Host Client | VM registration and hardware configuration |
| VMX / VMDK | Virtual machine configuration and storage |
| `vmkfstools` | Virtual disk-chain validation |
| `vim-cmd` | ESXi VM management |
| PuTTY / SSH | Remote command-line administration |
| Ubuntu Linux | Server and service administration |
| Apache HTTP Server | Web application hosting |
| systemd | Linux service management |
| iptables / nftables | Linux packet-filtering diagnostics |
| curl | HTTP availability verification |
| Linux filesystem permissions | Web-content access troubleshooting |

## Repository Structure

```text
infrastructure-troubleshooting-lab/
├── README.md
├── case-studies/
│   ├── 001-vmware-vm-recovery.md
│   └── 002-ubuntu-web-service.md
├── scripts/              # Planned
└── screenshots/          # Planned
```

## Project Scope and Documentation

These case studies are based on troubleshooting performed during a time-limited technical assessment using non-production infrastructure.

The documentation includes recovered command history, observed diagnostic output, and confirmed technical outcomes.

Company identifiers, original network addresses, and credentials are excluded.

Where the available records do not establish a final result or root cause, those limitations are explicitly documented.

The emphasis is on transparent troubleshooting methodology and technically verifiable findings.

## Future Improvements

Planned additions include:

- Reproducible VMware failure-and-recovery exercises.
- Linux web-service health-check scripts.
- Sanitized terminal-output screenshots.
- Infrastructure troubleshooting automation.
- Additional virtualization and Linux administration scenarios.

---

**Project status:** Two technical case studies documented, including successful VMware VM recovery and confirmed local Apache HTTP restoration.
