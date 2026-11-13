# Case Study 002 — Ubuntu Apache Web Server Recovery

**Category:** Linux Administration / Infrastructure Operations  
**Operating System:** Ubuntu 22.04.4 LTS  
**Web Server:** Apache HTTP Server 2.4.52  
**Platform:** VMware Virtual Platform  
**Environment:** Remote, non-production technical assessment  
**Date:** November 4, 2026  
**Outcome:** Apache restored to HTTP 200 OK locally; final external verification not preserved in transcript

---

## 1. Executive Summary

During a remote infrastructure technical assessment, I was tasked with restoring an inaccessible public website hosted on an Ubuntu Linux virtual machine.

The initial symptom was complete website unavailability. DNS was my first consideration, but a successful SSH connection established that the host was reachable.

Further investigation uncovered multiple independent configuration problems:

1. Apache was installed but stopped and disabled.
2. Apache was configured to listen on TCP port 81 rather than port 80.
3. An explicit firewall rule dropped incoming TCP port 80 traffic.
4. The website's `index.html` file had permissions that prevented Apache from reading it.
5. The required verification text was absent from the page.

After the service, port configuration, firewall, and file-permission corrections, Apache returned HTTP 200 OK locally.

The remaining assessment requirement was to ensure the assigned verification marker appeared and to validate access through the public URL without a VPN. The recovered transcript contains the instructions for that final step but not its complete verification output.

This case study documents the actual troubleshooting evidence, configuration corrections, and results.

## 2. Environment Overview

| Component | Configuration |
|---|---|
| Operating system | Ubuntu Server 22.04.4 LTS |
| Kernel | Linux 5.15.0-60-generic |
| Web server | Apache 2.4.52 |
| Virtualization | VMware |
| Administrative access | SSH |
| Network interface | ens160 |
| HTTP service | TCP 80 |
| Initial Apache listener | TCP 81 |
| Firewall | iptables / nftables |
| Web document root | `/var/www/html` |
| Environment | Non-production assessment |

Original public and private IP addresses, hostnames, credentials, and organization identifiers have been omitted or sanitized.

## 3. Problem Statement

The assigned objective was to make a public HTTP website accessible from outside the remote lab environment.

The page also needed to contain a specific verification marker.

The website was initially unreachable.

Potential causes included:

- DNS resolution failure
- Server connectivity problems
- Inactive web services
- Incorrect listening ports
- Firewall restrictions
- Web-server configuration problems
- Filesystem permissions

Because an inaccessible website can fail at multiple layers, the investigation began by establishing host connectivity and identifying the installed web-server software.

## 4. Establishing SSH Connectivity

The initial SSH hostname resolution attempt failed.

A subsequent connection using the assigned administrative account succeeded.

Example:

```bash
ssh sysadmin@web-lab.example.com
```

The server reported Ubuntu 22.04.4 LTS running on a VMware virtual platform.

This established that SSH connectivity was functional.

However, successful SSH access did not establish that the HTTP service was available.

## 5. Initial Service Diagnostics

The following commands were executed:

```bash
sudo systemctl --no-pager --full status nginx apache2
sudo ss -lntp
curl -v --max-time 10 http://127.0.0.1/
sudo ufw status verbose
```

### Finding 1 — Apache Was Stopped

The service-status output reported:

```text
Unit nginx.service could not be found.

apache2.service - The Apache HTTP Server

Loaded: loaded (...; disabled; vendor preset: enabled)
Active: inactive (dead)
```

Apache was installed but inactive and disabled at boot.

The initial listener inspection showed SSH on port 22 and the local DNS resolver on port 53, but no HTTP listener on port 80.

A local HTTP request returned:

```text
Trying 127.0.0.1:80...

Connection timed out after 10000 milliseconds

curl: (28) Connection timed out
```

The UFW status was:

```text
Status: inactive
```

Although UFW was inactive, that did not rule out firewall rules configured directly through other mechanisms.

## 6. Initial Remediation — Start Apache

Before starting Apache, the configuration was checked:

```bash
sudo apache2ctl configtest
```

Result:

```text
Syntax OK
```

Apache was then enabled and started:

```bash
sudo systemctl enable --now apache2
```

Systemd created the required service enablement symlink.

However, another local HTTP test still timed out.

This demonstrated that starting Apache alone was insufficient to restore website availability.

## 7. Further Investigation — Listener and Firewall

The next diagnostic commands were:

```bash
sudo systemctl --no-pager --full status apache2
sudo ss -lntp
sudo iptables -S
sudo nft list ruleset
sudo apache2ctl -S
```

### Finding 2 — Apache Was Listening on the Wrong Port

Apache was now confirmed active:

```text
Active: active (running)
```

However, the TCP listener was configured on port 81:

```text
LISTEN ... :81 ... apache2
```

The virtual-host configuration also showed:

```text
*:81
```

Further inspection revealed:

`/etc/apache2/ports.conf`

```apache
Listen 81
```

`/etc/apache2/sites-available/000-default.conf`

```apache
<VirtualHost *:81>
```

The assessment required standard HTTP access through port 80, so this configuration was incompatible with the expected endpoint.

### Finding 3 — Explicit Firewall Rule Blocking HTTP

The firewall inspection revealed:

```bash
-A INPUT -p tcp -m tcp --dport 80 -j DROP
```

The nftables ruleset also showed a corresponding rule dropping TCP port 80 traffic.

This explained why UFW reporting an inactive status did not eliminate firewall filtering as a potential cause.

A search of persistent firewall configuration identified the rule in:

```text
/etc/iptables/rules.v4
```

Therefore, both the active rule and its persistent configuration needed correction.

## 8. Correcting the Port and Firewall Configuration

Before applying changes, backups were created:

```bash
sudo cp -a /etc/apache2/ports.conf \
  /etc/apache2/ports.conf.before-fix

sudo cp -a /etc/apache2/sites-available/000-default.conf \
  /etc/apache2/sites-available/000-default.conf.before-fix

sudo cp -a /etc/iptables/rules.v4 \
  /etc/iptables/rules.v4.before-fix
```

The Apache listening port was corrected:

```bash
sudo sed -i 's/^Listen 81$/Listen 80/' \
  /etc/apache2/ports.conf
```

The virtual host was updated:

```bash
sudo sed -i \
  's/<VirtualHost \*:81>/<VirtualHost *:80>/' \
  /etc/apache2/sites-available/000-default.conf
```

Apache configuration syntax was checked, followed by a restart:

```bash
sudo apache2ctl configtest && sudo systemctl restart apache2
```

The active firewall rule was removed:

```bash
sudo iptables -D INPUT -p tcp --dport 80 -j DROP
```

The persistent firewall entry was removed:

```bash
sudo sed -i \
  '/^-A INPUT -p tcp -m tcp --dport 80 -j DROP$/d' \
  /etc/iptables/rules.v4
```

This addressed both the current blocking rule and its saved configuration.

## 9. Finding 4 — HTTP 403 Forbidden

With Apache reachable on port 80, the next HTTP request produced a different result:

```text
HTTP/1.1 403 Forbidden
Server: Apache/2.4.52 (Ubuntu)
```

This represented progress: the server was now returning an HTTP response rather than timing out.

The next step was to investigate why Apache could not serve the requested page.

### Diagnostic Commands

```bash
sudo tail -n 30 /var/log/apache2/error.log
sudo namei -l /var/www/html
sudo ls -la /var/www/html
```

### Apache Error Log Evidence

```text
AH00132: file permissions deny server access:
/var/www/html/index.html
```

The directory traversal permissions were valid, but the actual HTML file had the following permissions:

```text
--w------- 1 root root ... index.html
```

The owner had write permission but no read permission, and the Apache process running as `www-data` could not read the file.

The permissions were clearly inconsistent with the requirements for serving a public web page.

### Permission Correction

The documented correction was:

```bash
sudo chmod 644 /var/www/html/index.html
```

This sets the file to:

```text
-rw-r--r--
```

The resulting permissions allow the owner to read and write the file while granting read access to other users, including Apache.

A subsequent status summary in the recovered transcript confirms that Apache returned HTTP 200 OK after the permission correction.

## 10. Finding 5 — Missing Verification Content

After the HTTP availability issues were resolved, the remaining assessment requirement was to display a specific verification marker.

The page was reachable locally, but the required text was absent.

A backup-and-edit procedure was provided:

```bash
sudo cp -a /var/www/html/index.html \
  /var/www/html/index.html.before-content-fix
```

The example below uses a sanitized marker:

```html
<p>LAB-VERIFICATION-OK</p>
```

The original procedure inserted the assigned text into the HTML page and called for verification with `curl` and `grep`.

The transcript does not preserve the final command output showing the marker or the public-browser verification.

Therefore, the verified technical outcome is local HTTP 200 OK, with final external validation not independently documented.

## 11. Root Cause Summary

The web-service outage involved multiple independent configuration problems.

| Issue | Evidence | Correction |
|---|---|---|
| Apache stopped and disabled | `inactive (dead)` | Enabled and started Apache |
| Incorrect listening port | TCP 81 | Changed to TCP 80 |
| Firewall blocking HTTP | `iptables` DROP on TCP 80 | Removed active and persistent rule |
| HTML file unreadable | `AH00132` and `--w-------` | Changed permissions to `644` |
| Required text missing | Verification marker absent | Content update procedure documented |

The first four issues directly affected service availability or the ability to serve the page.

The fifth affected compliance with the assessment's content requirement.

## 12. Troubleshooting Timeline

| Stage | Investigation | Finding |
|---|---|---|
| 1 | Attempt SSH connection | Initial hostname resolution difficulty |
| 2 | Establish SSH connectivity | Ubuntu host reachable |
| 3 | Check web services | Apache installed but inactive |
| 4 | Enable and start Apache | Service started; HTTP still unavailable |
| 5 | Inspect listeners | Apache listening on port 81 |
| 6 | Inspect firewall rules | TCP 80 explicitly blocked |
| 7 | Correct port and firewall | HTTP returned 403 |
| 8 | Inspect Apache error log | File permissions denied access |
| 9 | Correct HTML permissions | HTTP 200 OK reported |
| 10 | Check required page content | Verification marker missing |
| 11 | Prepare content correction | Final external confirmation not retained |

## 13. Technical Lessons Learned

### Multiple Independent Failures Can Affect One Service

The investigation identified several unrelated problems, each capable of preventing the expected website behavior.

Restoring the Apache process was necessary but not sufficient.

### A Running Service Does Not Guarantee Availability

Apache reported an active state while listening on the wrong port.

Checking process state alone would have produced an incomplete diagnosis.

### UFW Status Is Not a Complete Firewall Audit

Even with UFW inactive, an explicit iptables rule blocked TCP 80.

Both active rules and persistent configuration should be considered during troubleshooting.

### HTTP Status Codes Help Narrow the Failure

The transition from a connection timeout to HTTP 403 showed that the troubleshooting had progressed beyond basic HTTP reachability and into application/file-access problems.

### File Permissions Matter

The Apache error log identified the exact affected file.

Correcting its permissions addressed the server's inability to read the page.

### Configuration Changes Require Validation

Each remediation should be followed by a functional test rather than assuming that a successful command means the overall issue is resolved.

## 14. Outcome

The recovered assessment transcript supports the following confirmed outcomes:

- SSH access established.
- Apache identified as stopped and disabled.
- Apache started and enabled.
- Incorrect HTTP port identified and corrected.
- Active and persistent TCP 80 firewall block identified and addressed.
- HTML file-permission problem identified and corrected.
- Local HTTP 200 OK reported after remediation.

The transcript also records the procedure to add the required verification text.

The final browser-based test from outside the lab is not preserved in the available records.

## 15. Conclusion

This exercise demonstrated a layered approach to Linux web-service troubleshooting.

Instead of treating the unavailable website as a single failure, the investigation moved through host connectivity, service state, network listeners, firewall rules, virtual-host configuration, application responses, and filesystem permissions.

The key lesson was that **successful service recovery requires resolving each confirmed failure and verifying behavior at the appropriate layer**.

This case study is based on recovered terminal commands, diagnostic output, and documented troubleshooting decisions from the original assessment.

---

**Case Study Status:** Technical recovery documented with verified root causes and local HTTP restoration. Final external verification remains undocumented.
