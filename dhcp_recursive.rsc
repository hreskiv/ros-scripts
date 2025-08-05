:if ($bound=1) do={
    /ip route remove [ find gateway="9.9.9.9" ]; 
    /ip route remove [ find where dst-address ~"9.9.9.9" ];
    /ip route add check-gateway=ping comment="Recursive route via ISP-1" distance=1 \
        dst-address=9.9.9.9/32 gateway=$"gateway-address" scope=10
    /ip route add check-gateway=ping comment="Route via ISP-1" distance=1 \
        gateway=9.9.9.9 target-scope=11
:if [:tobool ([/ip firewall/nat/ find comment="masquerade via ISP-1"])] do={
    /ip firewall nat set [find comment="masquerade via ISP-1"] action=masquerade chain=srcnat \
        ipsec-policy=out,none out-interface=$"interface";
} else={ /ip firewall nat add action=masquerade chain=srcnat ipsec-policy=out,none \
            out-interface=$"interface" comment="masquerade via ISP-1" }
} else={
    /ip route remove [ find gateway="9.9.9.9" ]; 
    /ip route remove [ find where dst-address ~"9.9.9.9" ]
    /ip firewall nat remove [find comment="masquerade via ISP-1"]
}

