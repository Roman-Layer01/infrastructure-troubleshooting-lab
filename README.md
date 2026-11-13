# Infrastructure Troubleshooting Lab

### VMware | Linux | Virtualization | Systems Administration

A technical portfolio documenting hands-on infrastructure troubleshooting, virtual machine recovery, Linux service diagnostics, and incident-resolution methodology.

This repository features case studies based on practical technical assessments and hands-on infrastructure exercises involving VMware virtualization and Ubuntu Linux environments.

The objective is to demonstrate systematic troubleshooting, root-cause investigation, service restoration, and technical documentation.

## Technical Focus

- VMware vSphere / ESXi administration
- Virtual machine registration and recovery
- Virtual disk configuration and troubleshooting
- Ubuntu Linux administration
- SSH-based remote diagnostics
- Web service availability and troubleshooting
- Infrastructure recovery and validation
- Command-line alternatives to graphical management tools

## Case Study 001 — VMware Linux VM Recovery

**Scenario:** An existing Linux virtual machine needed to be registered and returned to a bootable state within a VMware-managed environment.

The troubleshooting exercise involved working through the VMware web client, investigating an existing virtual disk, and using SSH when graphical controls behaved unexpectedly.

### Challenges

- Registering an existing virtual machine
- Identifying and attaching the appropriate virtual disk
- Troubleshooting VMware web-client interface issues
- Investigating virtual machine configuration through SSH
- Validating successful VM registration and startup

### Outcome

The Linux VM was successfully registered and booted.

**Key takeaway:** When a graphical management interface becomes unreliable, command-line diagnostics can provide an alternative path to investigating and resolving infrastructure issues.

[View Case Study](case-studies/001-vmware-vm-recovery.md) *(documentation forthcoming)*

## Case Study 002 — Ubuntu Web Service Troubleshooting

**Scenario:** Diagnose an Ubuntu-based web server experiencing availability issues.

This exercise involved investigating Linux service availability and troubleshooting the components necessary for successful web access.

### Technical Areas

- Linux service management
- Network connectivity
- Web server diagnostics
- Service logs
- Remote SSH troubleshooting
- Availability verification

**Status:** Detailed troubleshooting notes and verified resolution steps are being prepared.

[View Case Study](case-studies/002-ubuntu-web-service.md) *(documentation forthcoming)*

## Troubleshooting Methodology

The case studies follow a structured approach:

1. **Identify:** Establish symptoms and expected system behavior.
2. **Investigate:** Collect evidence from logs, configuration, services, and network connectivity.
3. **Isolate:** Narrow potential causes through controlled testing.
4. **Remediate:** Apply an appropriate corrective action.
5. **Validate:** Confirm the expected functionality has been restored.
6. **Document:** Record findings, commands, outcomes, and preventative recommendations.

## Repository Structure

```text
infrastructure-troubleshooting-lab/
├── README.md
├── case-studies/
│   ├── 001-vmware-vm-recovery.md
│   └── 002-ubuntu-web-service.md
├── scripts/
├── screenshots/
└── lessons-learned.md
```

*Additional case studies and supporting materials will be added as they are documented.*

## Tools and Technologies

| Technology | Application |
|---|---|
| VMware ESXi / vSphere | Virtualization and VM management |
| VMware web client | VM registration and hardware configuration |
| Ubuntu Linux | Server administration and troubleshooting |
| SSH | Remote command-line access |
| Linux system utilities | Storage, process, service, and network diagnostics |
| Windows | Administrative workstation |

## Project Scope

The initial case studies are based on a time-limited remote infrastructure technical assessment completed in November 2026.

The exercises were conducted against a non-production test environment.

Organization names and original infrastructure IP addresses are omitted or replaced with documentation-safe examples.

These case studies distinguish confirmed outcomes from troubleshooting approaches and additional validation that may be performed in a recreated lab.

## Professional Development

This project supports continued development in:

- Systems engineering
- Infrastructure operations
- Linux administration
- Virtualization
- Incident troubleshooting
- Security-focused infrastructure engineering

The emphasis is on practical technical reasoning, operational recovery, and documentation that another administrator could follow.

---

**Project status:** Initial repository documentation. Detailed case studies and supporting technical evidence are being added.
