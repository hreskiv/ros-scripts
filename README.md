# MikroTik RouterOS Scripts

![RouterOS](https://img.shields.io/badge/RouterOS-v7-blue)
![License](https://img.shields.io/badge/license-CC--BY--NC--4.0-green)
![Stars](https://img.shields.io/github/stars/hreskiv/ros-scripts)

A collection of practical RouterOS v7 scripts, configurations, and app definitions used in [MikroTik training courses](https://mtik.pl) and [YouTube videos](https://www.youtube.com/@mikrotikpolska).

## Scripts

### Routing & Dual WAN

| Script | Description |
|--------|-------------|
| [DualWAN-Active-Active.rsc](DualWAN-Active-Active.rsc) | Active-Active Dual WAN with connection marking, policy routing, and per-ISP masquerade |
| [dhcp_recursive.rsc](dhcp_recursive.rsc) | DHCP client script — sets up recursive routes and NAT on lease bound/unbound |
| [ppp-profile.txt](ppp-profile.txt) | PPP On-Up / On-Down scripts — recursive default route via PPP peer with NAT |

### VPN & Policy Routing

| Script | Description |
|--------|-------------|
| [wg-multi-exit-hub.rsc](wg-multi-exit-hub.rsc) | WireGuard hub (CHR) — two remote exit points, per-host policy routing by address-list |
| [wg-multi-exit-spoke.rsc](wg-multi-exit-spoke.rsc) | WireGuard spoke (office router) — selected LAN hosts routed into the hub tunnel |
| [wg-multi-exit-node.rsc](wg-multi-exit-node.rsc) | WireGuard exit node — terminates one exit tunnel and masquerades the traffic to the internet |

### DNS & Security

| Script | Description |
|--------|-------------|
| [cf-ddns.rsc](cf-ddns.rsc) | Cloudflare Dynamic DNS — updates A record via API when public IP changes |
| [country-block.rsc](country-block.rsc) | Country-based IP blocking using [iwik.org](http://www.iwik.org/ipcountry/) address lists |
| [ip-reputation.rsc](ip-reputation.rsc) | Spamhaus DROP list (JSON) — downloads and populates `spamhaus-drop` address-list for firewall blocking |
| [ex-im-certs.rsc](ex-im-certs.rsc) | Bulk export and import of all certificates (PKCS12) |

### Containerized Apps (RouterOS 7.22+)

| File | Description |
|------|-------------|
| [mikr.yaml](mikr.yaml) | [MikroTik Manager](https://mikr.mtik.pl) — web-based device management and monitoring |

### Monitoring

| File | Description |
|------|-------------|
| [mikrotik-isp-by-snmp.yaml](mikrotik-isp-by-snmp.yaml) | Zabbix 7.4 template — discovers uplink interfaces by the RouterOS **comment** (`ifAlias`), not by port name |
| [mikrotik-lte-by-ssh.yaml](mikrotik-lte-by-ssh.yaml) | Zabbix 7.4 template — LTE band, cell, operator and signal over **one SSH session per poll**, LTE interfaces auto-discovered |

## Usage

Each `.rsc` file is a standalone script. Review and adjust variables before importing:

```routeros
/import file-name=cf-ddns.rsc
```

For **scheduler-based** scripts (like `cf-ddns.rsc`), add to the RouterOS scheduler:

```routeros
/system scheduler add name=cloudflare-ddns interval=5m \
    on-event="/system script run cf-ddns"
```

> **Important:** All scripts contain placeholder values (tokens, IPs, interface names). Edit them to match your environment before use.

## Script Details

### cf-ddns.rsc — Cloudflare DDNS

Updates a Cloudflare DNS A record when the router's public IP changes. Uses the Cloudflare API v4.

**Variables to set:**
- `cfToken` — Cloudflare API Bearer token
- `cfZoneID` / `cfRecordID` — Zone and record identifiers
- `recordName` — DNS record (e.g. `router.example.com`)

**Features:** IP validation, change detection (skips update if IP unchanged), error logging.

---

### DualWAN-Active-Active.rsc — Dual WAN

Complete Active-Active configuration for two ISPs with:
- DHCP clients on both WAN interfaces
- Connection marking (mangle) for reply routing
- Per-ISP routing tables (`isp-1-rt`, `isp-2-rt`)
- Masquerade on both uplinks
- Blackhole fallback route

---

### wg-multi-exit-*.rsc — WireGuard Multi-Exit

A hub-and-spoke WireGuard setup where selected LAN hosts leave the internet through
different remote exit points, while the rest of the network keeps the local uplink.

```
office LAN ──▶ spoke ──▶ hub ─┬─▶ exit A (10.254.1.2) ──▶ internet
 .50 / .60                    └─▶ exit B (10.254.2.2) ──▶ internet
```

**Hub (CHR):**
- Three WireGuard interfaces — two towards remote exits (`wg-exit-a`, `wg-exit-b`), one towards the office
- Routing tables `exit-a` / `exit-b`, each with its own default route and `check-gateway=ping`
- Address-lists `via-a` / `via-b` decide which host uses which exit
- `lookup-only-in-table` routing rules — no fallback to the main table if the tunnel is down

**Spoke (office router):**
- One tunnel to the hub, `persistent-keepalive=5s`
- Address-list `to-remote` marks the hosts that should be tunneled
- Everything else is masqueraded out of `ether1` as usual

**Exit node:**
- One tunnel back to the hub (`endpoint-port=51821` for exit A, `51822` for exit B)
- Address `10.254.1.2/30` (exit A) or `10.254.2.2/30` (exit B)
- `masquerade` on the local uplink — without it the tunneled traffic leaves with a
  private source address and never comes back
- A route for `192.168.88.0/24` via the hub, so replies find their way home

Deploy the same file on both exits, changing only the port and the `/30` address.

**Placeholders to replace:** `YOUR_EXIT_A_PUBLIC_KEY`, `YOUR_EXIT_B_PUBLIC_KEY`,
`YOUR_SPOKE_PUBLIC_KEY`, `YOUR_UPSTREAM_GATEWAY` (hub), `YOUR_HUB_PUBLIC_IP` and
`YOUR_HUB_PUBLIC_KEY` (spoke and exit nodes). Private addressing (`10.10.0.0/30`, `10.254.x.0/30`,
`192.168.88.0/24`) is example-only — adjust to your own network.

> **Note:** the exports are made with hidden private keys. After import, generate the
> keys on each device and exchange the public ones.

---

### dhcp_recursive.rsc — DHCP Recursive Routes

DHCP client script that creates recursive routes on lease bound and cleans up on release. Ensures traffic always returns via the correct ISP. Includes dynamic NAT rule management.

---

### ppp-profile.txt — PPP On-Up / On-Down

Same recursive routing concept as `dhcp_recursive.rsc`, but triggered by PPP connection events. Suitable for LTE, PPPoE, or any PPP-based WAN.

---

### ip-reputation.rsc — Spamhaus DROP

Downloads the [Spamhaus DROP](https://www.spamhaus.org/drop/) list in JSON format (`drop_v4.json`) and populates the `spamhaus-drop` address-list. Use it in firewall raw/filter rules to drop traffic from known-malicious networks.

Spamhaus recommends the JSON feed over the legacy `drop.txt`, which is going to be deprecated. The JSON file is too large for `/file get contents`, so the script reads it in chunks.

**Safety checks:** if the download fails or the file is smaller than 10 KB, the existing list is left untouched and an error is logged.

**Schedule (once per day):**
```routeros
/system scheduler add name=spamhaus-drop interval=1d start-time=03:00 \
    on-event="/import file-name=ip-reputation.rsc"
```

**Example firewall rule:**
```routeros
/ip firewall raw add chain=prerouting src-address-list=spamhaus-drop action=drop
```

---

### mikr.yaml — MikroTik Manager App

YAML definition for deploying [MikroTik Manager](https://mikr.mtik.pl) as a containerized app on RouterOS 7.22+.

**Deploy on CHR/RouterOS:**
```routeros
/app add yaml=[/file get mikr.yaml contents]
```

> **Important:** The `ENCRYPTION_KEY` and `JWT_SECRET` values in the file are examples. Generate your own before use:
> ```bash
> openssl rand -hex 32
> ```

**Default credentials:** `admin` / `admin`

---

### mikrotik-isp-by-snmp.yaml — Zabbix template, ISP discovery by interface comment

Zabbix template (export format 7.4) that discovers uplink interfaces by the **interface comment** instead of the port name. RouterOS exposes the comment over SNMP as `IF-MIB::ifAlias`, so the same template fits a router with the uplink on `ether1`, on `sfp-sfpplus1` or on a VLAN interface — nothing has to be adjusted per host.

**On the router:**
```routeros
/interface ethernet set [find default-name=ether1] comment=ISP1
/snmp community set [find default=yes] name=<community> addresses=<Zabbix IP>
/snmp set enabled=yes
```

**Verify before importing** — an empty output here means there is nothing for discovery to find:
```bash
snmpwalk -v2c -c <community> <router> IF-MIB::ifAlias
```

**In Zabbix:** *Data collection → Templates → Import*, then link the template to a host that has an SNMP interface and `{$SNMP_COMMUNITY}` set.

**What it creates per discovered interface:** bits received / bits sent (`ifHCInOctets` / `ifHCOutOctets`), operational status with a value map, the comment itself as an item, a traffic graph, and a `link down` trigger.

**Macros:**

| Macro | Default | Meaning |
|-------|---------|---------|
| `{$ISP.ALIAS.MATCHES}` | `^ISP` | Regex matched against the interface comment — change it to discover a different set of interfaces |
| `{$ISP.STATUS.DOWN}` | `2` | `ifOperStatus` value treated as down |
| `{$ISP.STATUS.UP}` | `1` | `ifOperStatus` value treated as up |

Discovery runs hourly, items poll every minute. Tested with Zabbix 7.4 against RouterOS 7.23.3 (CRS320, RB5009).

---

### mikrotik-lte-by-ssh.yaml — Zabbix template, LTE monitoring over SSH

Zabbix template (export format 7.4) for RouterOS v7 LTE interfaces. The signal numbers are only part of the picture — when a backup LTE link degrades, the questions are which cell the modem jumped to, which band it is on, which operator serves it and how long the session has lasted. All of that is in `/interface lte monitor`, and this template collects it.

**How it works:**
- **One SSH session per poll.** A master item runs `/interface lte monitor <iface> once as-value`; every metric is a dependent item parsed from that single output — not twelve sessions.
- **Discovery over SSH.** Once an hour a short RouterOS script lists `/interface lte` and returns the LLD JSON with `{#LTE.IFNAME}`.
- **SSH, not REST API** — deliberately, because of session leaks on RouterOS v7.
- **Layers, not a replacement.** Traffic and oper-status are out of scope on purpose — link the official MikroTik SNMP template to the same host.

**What it creates per LTE interface:** primary band, Cell ID, eNB ID, EARFCN, operator, access technology, session uptime, status, RSRP, RSRQ, RSSI and SINR (12 dependent items), plus 6 triggers — no data for 5 minutes, RSRP low / critically low, RSRQ low, SINR low, and not connected. Text items use *Discard unchanged with heartbeat* (1h), so history only grows when the value changes.

**In Zabbix:** *Data collection → Templates → Import*, link the template to the router host and set the SSH credentials.

> **Credentials:** the file ships with `admin` / `admin` as placeholders. Create a dedicated read-only user on the router and put it in `{$SSH.USER}` / `{$SSH.PASSWORD}` (the password macro is a secret text).

**Macros:**

| Macro | Default | Meaning |
|-------|---------|---------|
| `{$SSH.USER}` | `admin` | SSH user on the router — replace with a read-only user |
| `{$SSH.PASSWORD}` | `admin` | SSH password (secret text) |
| `{$SSH.PORT}` | `22` | SSH port |
| `{$LTE.IFNAME.MATCHES}` | `.*` | Regex of LTE interface names to discover |
| `{$LTE.IFNAME.NOT_MATCHES}` | `CHANGE_IF_NEEDED` | Regex of LTE interface names to skip |
| `{$LTE.RSRP.CRIT}` | `-110` | RSRP critical threshold, dBm |
| `{$LTE.RSRP.WARN}` | `-100` | RSRP warning threshold, dBm |
| `{$LTE.RSRQ.WARN}` | `-15` | RSRQ warning threshold, dB |
| `{$LTE.SINR.WARN}` | `0` | SINR warning threshold, dB |

The thresholds are a starting point, not a standard — tune them to what your site considers a healthy signal.

> **Note:** on RHEL-family Zabbix servers with SELinux enforcing, SSH checks fail with `Permission denied` until you run `setsebool -P zabbix_can_network on`.

Parsing verified against a Quectel EC25-EU modem; tested with Zabbix 7.4 on RouterOS 7.24.2 (KNOT LTE4).

## Requirements

- RouterOS **v7** (tested on 7.13+)
- Scripts use `/tool fetch` — ensure the router has internet access for API-based scripts

## License

[Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)](https://creativecommons.org/licenses/by-nc/4.0/)

You are free to use, modify, and share these materials for personal learning and non-commercial purposes. If you use them in your own courses, videos, or publications — please credit the author and link to this repository.

## Author

**Ihor Hreskiv** — MikroTik Certified Trainer

- [mtik.pl](https://mtik.pl) — MikroTik training (Poland, Kraków)
- [mtik.tech](https://mtik.tech) — MikroTik training (Ukraine, online)
- [YouTube PL](https://www.youtube.com/@mikrotikpolska) · [YouTube UA](https://www.youtube.com/@mikrotikukraine)
- [LinkedIn](https://www.linkedin.com/in/hreskiv) · [GitHub](https://github.com/hreskiv)
