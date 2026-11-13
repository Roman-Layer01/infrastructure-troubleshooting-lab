# Case Study 002 — Ubuntu Apache Web Server Availability Troubleshooting

**Category:** Linux Administration / Infrastructure Operations  
**Operating System:** Ubuntu Server 22.04.4 LTS  
**Web Server:** Apache HTTP Server  
**Virtualization Platform:** VMware  
**Environment:** Remote, non-production infrastructure  
**Assessment Date:** November 4, 2026  
**Troubleshooting Window:** Approximately 5:31–5:39 AM Mountain Time (documented portion)  
**Status:** Initial fault identified; additional connectivity issue under investigation

---

## 1. Executive Summary

During a time-limited remote infrastructure technical assessment, I was tasked with restoring public access to a website hosted on an Ubuntu Linux virtual machine.

The initial symptom was that the public website was completely unreachable.

My first hypothesis involved DNS resolution, but after successfully establishing an SSH session to the server, I began investigating the web service and local network connectivity.

The investigation identified that Apache was installed but stopped and disabled.

After validating the Apache configuration, I enabled and started the service using `systemctl`.

However, HTTP requests to the local loopback interface continued to time out, indicating that the inactive Apache service was not necessarily the only problem.

The next diagnostic phase focused on verifying Apache's runtime state, active TCP listeners, firewall rules, and virtual-host configuration.

This case study documents the actual commands and results recovered from the assessment transcript, rather than assuming an unverified final root cause.

## 2. Assessment Objective

Restore an externally accessible HTTP website hosted on an Ubuntu virtual machine.

The assessment required the page to be accessible from a public browser without using the environment's VPN connection.

Successful completion also required the website to display an assigned verification marker.

For documentation purposes, the original endpoint and verification marker are omitted.

**Example public endpoint:**

```text
http://web-lab.example.com/
```

The public accessibility requirement was important because successful local HTTP connectivity would not, by itself, establish that external users could reach the website.

## 3. Environment Overview

| Component | Details |
|---|---|
| Guest operating system | Ubuntu 22.04.4 LTS |
| Kernel | Linux 5.15.0-60-generic |
| Virtualization | VMware Virtual Platform |
| Web service | Apache HTTP Server |
| Alternate web service | Nginx not installed |
| Administrative access | SSH |
| Local interface | `ens160` |
| Example private IP | `10.20.30.79` |
| Example public IP | `192.0.2.10` |
| HTTP port | TCP 80 |
| SSH port | TCP 22 |
| Environment | Remote technical assessment |

The host was reachable over SSH, establishing that the machine was running and that at least one network service was accessible.

The specific organization, hostname, original addresses, and authentication details are excluded.

## 4. Initial Symptoms

The public website failed to load.

At the beginning of the investigation, DNS resolution was considered as a possible cause.

An initial SSH connection attempt using the supplied hostname did not resolve successfully. A subsequent attempt connected to the Ubuntu machine.

The successful connection established that the target hostname was resolvable and reachable from the administrative workstation at that time.

This did not establish that the HTTP service was functioning.

### Successful SSH Connection

```bash
ssh sysadmin@web-lab.example.com
```

The server presented the Ubuntu 22.04.4 LTS login banner.

The system reported a VMware virtual platform and an active network interface.

This provided an administrative path for investigating the web-service failure directly.

## 5. Initial Diagnostic Commands

The first diagnostic sequence examined the installed web services, listening TCP ports, loopback HTTP accessibility, and UFW firewall status.

The following commands were executed during the assessment:

```bash
sudo systemctl --no-pager --full status nginx apache2
sudo ss -lntp
curl -v --max-time 10 http://127.0.0.1/
sudo ufw status verbose
```

### Finding 1 — Nginx Was Not Installed

```text
Unit nginx.service could not be found.
```

This ruled out Nginx as an installed systemd-managed service under that name.

### Finding 2 — Apache Was Stopped and Disabled

```text
apache2.service - The Apache HTTP Server

Loaded: loaded (...; disabled; vendor preset: enabled)
Active: inactive (dead)
```

This was the first confirmed service-level problem.

Apache was installed, but the service was not running and was not configured to start automatically.

### Finding 3 — No HTTP Listener Was Present

The initial TCP listener inspection showed SSH and the local DNS stub resolver.

Sanitized output:

```text
Local Address:Port       Process
127.0.0.53:53            systemd-resolved
0.0.0.0:22               sshd
[::]:22                  sshd
```

No listener on TCP port 80 was visible in this initial output.

This was consistent with Apache being inactive.

### Finding 4 — Local HTTP Requests Timed Out

```text
Trying 127.0.0.1:80...

Connection timed out after 10000 milliseconds

curl: (28) Connection timed out
```

The request did not return an HTTP response.

This was notable because a connection to an unused local TCP port would commonly fail immediately with a connection-refused error.

A timeout suggested that additional network or packet-filtering behavior might need investigation.

### Finding 5 — UFW Was Inactive

```text
Status: inactive
```

Ubuntu's UFW interface was not active.

However, this did not rule out firewall filtering implemented directly through `iptables`, `nftables`, or upstream network controls.

## 6. Initial Remediation

With Apache confirmed as installed but inactive, the next step was to validate the service configuration before attempting to start it.

### Validate Apache Configuration

Executed:

```bash
sudo apache2ctl configtest
```

Result:

```text
Syntax OK
```

Apache's configuration passed its syntax check.

This did not guarantee that the web server would function correctly, but it ruled out configuration syntax errors detectable by `apache2ctl configtest`.

### Enable and Start Apache

Executed:

```bash
sudo systemctl enable --now apache2
```

The command invoked the systemd service-management process and created the boot-time enablement symlink.

Sanitized output:

```text
Synchronizing state of apache2.service
with SysV service script

Created symlink:
multi-user.target.wants/apache2.service
→ /lib/systemd/system/apache2.service
```

The operation enabled Apache for startup during system boot.

The available output did not include a subsequent confirmation of Apache's active runtime state.

## 7. Post-Change Verification

After the Apache enable/start command, the local HTTP endpoint was tested again.

Executed:

```bash
curl -v --max-time 10 http://127.0.0.1/
```

Result:

```text
Trying 127.0.0.1:80...

Connection timed out after 10000 milliseconds

curl: (28) Connection timed out
```

**The web service was still not reachable through the loopback interface.**

This was a significant finding.

Although the inactive Apache service had been addressed as an initial configuration issue, the continuing HTTP timeout meant the assessment objective had not yet been verified.

The timeout did not establish whether Apache had successfully started or whether packets were being filtered.

Additional investigation was required.

## 8. Next Diagnostic Phase

After the HTTP request continued to fail, the investigation moved beyond the initial service state.

The next recommended commands were:

```bash
sudo systemctl --no-pager --full status apache2
sudo ss -lntp
sudo iptables -S
sudo nft list ruleset
sudo apache2ctl -S
```

These commands were proposed at the end of the recovered troubleshooting transcript.

**Their execution and results are not present in the available record.**

### Diagnostic Objectives

| Command | Purpose |
|---|---|
| `systemctl status apache2` | Confirm whether Apache successfully started |
| `ss -lntp` | Identify active listeners and their bound addresses |
| `iptables -S` | Inspect legacy/compatibility firewall rules |
| `nft list ruleset` | Inspect nftables packet-filtering configuration |
| `apache2ctl -S` | Examine Apache virtual-host mappings |

The goal was to determine whether the continued timeout originated from:

- Apache not remaining active
- Missing or incorrect HTTP listeners
- Local packet-filtering rules
- Incorrect virtual-host configuration
- Another networking or service-level condition

No single cause is asserted without supporting evidence.

## 9. Troubleshooting Timeline

| Time (MT) | Action | Result |
|---|---|---|
| 5:31 AM | Began investigation of inaccessible website | DNS initially considered |
| 5:32 AM | Initial SSH hostname resolution attempt | Failed |
| 5:38 AM | Established SSH connection to Ubuntu VM | Successful |
| 5:38 AM | Checked Nginx, Apache, listeners, localhost HTTP, and UFW | Apache inactive; no HTTP listener |
| 5:39 AM | Validated Apache configuration | Syntax OK |
| 5:39 AM | Enabled and attempted to start Apache | Enablement symlink created |
| 5:39 AM | Repeated localhost HTTP test | Still timed out |
| 5:39 AM | Prepared deeper Apache and firewall diagnostics | Follow-up results unavailable |

Times are derived from the recovered assessment conversation.

## 10. Findings and Evidence

| Investigation item | Observed result | Status |
|---|---|---|
| Ubuntu host reachable by SSH | Yes | Confirmed |
| Apache installed | Yes | Confirmed |
| Apache initially running | No | Confirmed |
| Apache initially enabled | No | Confirmed |
| Nginx service installed | No | Confirmed |
| TCP 80 listening initially | No listener observed | Confirmed |
| UFW active | No | Confirmed |
| Apache configuration syntax valid | Yes | Confirmed |
| Apache boot-time enablement applied | Yes | Confirmed |
| Apache active after remediation | Not established | Unverified |
| Local HTTP working after change | No | Confirmed |
| Public website restored | Not verified in recovered transcript | Unverified |
| Final root cause | Not established | Open |

## 11. Technical Analysis

### Why the Initial DNS Hypothesis Was Reasonable

An inaccessible public hostname can result from DNS failure, routing problems, server unavailability, or application-layer issues.

The first hostname-resolution failure made DNS a reasonable starting point.

However, the subsequent successful SSH connection demonstrated that the hostname could resolve and reach the server from the administrative workstation.

The investigation therefore shifted toward the HTTP service itself.

### Why Apache Being Stopped Mattered

The initial diagnostic output showed Apache inactive and no port 80 listener.

That explained at least part of the observed service-unavailability condition.

Starting and enabling Apache was a reasonable initial remediation.

### Why the Continued Timeout Mattered More

The next local HTTP request still timed out.

This prevented the investigation from being considered complete.

A valid Apache configuration and a successful systemd enablement operation do not necessarily establish:

- That the process remains running
- That it listens on the expected network interface
- That traffic reaches the listener
- That an HTTP response is returned

The next diagnostic stage therefore focused on runtime state, listener configuration, and packet-filtering rules.

### Why UFW Status Was Not Sufficient

UFW being inactive does not establish that the Linux host has no packet-filtering rules.

Direct `iptables` or `nftables` policies may exist independently of UFW.

Likewise, upstream virtualization or network controls may affect public accessibility.

However, upstream filtering would not ordinarily explain a localhost timeout, making local service and packet-filtering verification especially important.

## 12. Generalized Troubleshooting Workflow

The exercise reinforced a layered approach to web-service availability incidents.

1. Verify DNS resolution and host connectivity.
2. Establish administrative access.
3. Identify the installed web-server software.
4. Check service state and startup configuration.
5. Inspect TCP listeners.
6. Test the service locally.
7. Inspect local firewall policies.
8. Validate application configuration.
9. Apply evidence-supported remediation.
10. Test local and external accessibility.
11. Confirm required application content.
12. Document verified outcomes and remaining uncertainties.

This approach separates host availability from application availability and helps prevent premature conclusions.

## 13. Lessons Learned

### An Accessible Host Can Still Have an Unavailable Application

SSH connectivity proved that the Ubuntu host was accessible, but it did not prove HTTP availability.

### Fixing One Problem Does Not Necessarily Resolve the Incident

Apache being stopped was a confirmed issue.

However, the continued HTTP timeout showed that further investigation was necessary.

### Service Configuration and Service State Are Different

`apache2ctl configtest` confirmed valid configuration syntax.

It did not establish that the daemon was actively serving HTTP traffic.

### Local Timeouts Deserve Investigation

A timeout connecting to `127.0.0.1` is different from an immediate connection refusal.

This distinction can point the investigation toward service behavior, local filtering, and socket-level diagnostics.

### Evidence-Based Troubleshooting Improves Technical Documentation

The recovered command history provides concrete evidence of what was observed and attempted.

Where final resolution evidence is unavailable, it is more accurate to document the known findings and limitations rather than invent a root cause.

## 14. Future Lab Reproduction

This case study can be expanded by reproducing similar failures in a personally controlled Ubuntu VM.

Potential scenarios include:

- Apache stopped or disabled
- Apache startup failure
- Incorrect listening configuration
- Local packet-filtering restrictions
- Virtual-host configuration issues
- File and directory permission problems
- Application unavailable despite network reachability

A controlled reproduction would make it possible to collect complete command output, demonstrate root-cause analysis, document remediation, and verify recovery from both local and remote clients.

## 15. Conclusion

This assessment provided a practical example of systematic Linux infrastructure troubleshooting.

The initial investigation identified an installed but inactive Apache service, verified valid Apache configuration syntax, and applied a service enable/start operation.

When the local HTTP request continued to time out, the troubleshooting approach shifted toward verifying runtime service state, port listeners, firewall policies, and virtual-host configuration.

**The recovered evidence confirms a real service-level fault and an unresolved HTTP connectivity issue at the end of the documented session.**

The final restoration outcome and complete root cause remain unverified in the available record.

---

**Case Study Status:** Updated with recovered November 4, 2026 terminal commands and diagnostic evidence. Final resolution details pending verification.
