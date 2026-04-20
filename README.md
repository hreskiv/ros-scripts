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

### DNS & Security

| Script | Description |
|--------|-------------|
| [cf-ddns.rsc](cf-ddns.rsc) | Cloudflare Dynamic DNS — updates A record via API when public IP changes |
| [country-block.rsc](country-block.rsc) | Country-based IP blocking using [iwik.org](http://www.iwik.org/ipcountry/) address lists |
| [ip-reputation.rsc](ip-reputation.rsc) | Spamhaus DROP list — downloads and populates `spamhaus-drop` address-list for firewall blocking |
| [ex-im-certs.rsc](ex-im-certs.rsc) | Bulk export and import of all certificates (PKCS12) |

### Containerized Apps (RouterOS 7.22+)

| File | Description |
|------|-------------|
| [mikr.yaml](mikr.yaml) | [MikroTik Manager](https://mikr.mtik.pl) — web-based device management and monitoring |

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

### dhcp_recursive.rsc — DHCP Recursive Routes

DHCP client script that creates recursive routes on lease bound and cleans up on release. Ensures traffic always returns via the correct ISP. Includes dynamic NAT rule management.

---

### ppp-profile.txt — PPP On-Up / On-Down

Same recursive routing concept as `dhcp_recursive.rsc`, but triggered by PPP connection events. Suitable for LTE, PPPoE, or any PPP-based WAN.

---

### ip-reputation.rsc — Spamhaus DROP

Downloads the [Spamhaus DROP](https://www.spamhaus.org/drop/) list and populates the `spamhaus-drop` address-list. Use it in firewall raw/filter rules to drop traffic from known-malicious networks.

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
