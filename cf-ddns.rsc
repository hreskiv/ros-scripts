:local cfToken    "YOUR_TOKEN_HERE"
:local cfZoneID   "YOUR_ZONE_ID_HERE"
:local cfRecordID "YOUR_RECORD_ID_HERE"
:local recordName "YOUR_DOMAIN_HERE"
:local recordType "A"
:local ttl 60
:local proxied "false"

# Recieve current public IP over API
:local currentIP
:do {
    :set currentIP [/tool fetch url="https://api.ipify.org" as-value output=user]
    :set currentIP ($currentIP->"data")
} on-error={
    :log warning "Cloudflare DDNS: Failed to get public IP"
}

:if (($currentIP = "") or ($currentIP = "0.0.0.0")) do={ 
    :log warning "Cloudflare DDNS: No public IP detected"
} else={
    :if ([:len [:toip $currentIP]] = 0) do={ 
        :log warning ("Cloudflare DDNS: Detected IP '" . $currentIP . "' is not a valid IPv4 address")
    } else={
        :global cfLastIP
        :if ([:typeof $cfLastIP] = "nothing") do={ :set cfLastIP "" }

        :if ($currentIP = $cfLastIP) do={ 
            :log info ("Cloudflare DDNS: IP unchanged (" . $currentIP . ") - no update needed")
        } else={
            :local apiURL ("https://api.cloudflare.com/client/v4/zones/" . $cfZoneID . "/dns_records/" . $cfRecordID)
            :local jsonData ("{\"type\":\"" . $recordType . "\",\"name\":\"" . $recordName . "\",\"content\":\"" . $currentIP . "\",\"ttl\":" . $ttl . ",\"proxied\":" . $proxied . "}")

            :do {
                /tool fetch url=$apiURL mode=https http-method=put http-data=$jsonData \
                    http-header-field="Content-Type: application/json,Authorization: Bearer $cfToken" \
                    output=none
                :set cfLastIP $currentIP
                :log info ("Cloudflare DDNS: DNS record updated to " . $currentIP)
            } on-error={
                :log error "Cloudflare DDNS: Failed to update DNS record"
            }
        }
    }
}

