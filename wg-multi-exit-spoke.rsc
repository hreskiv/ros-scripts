# WireGuard multi-exit spoke (office router)
# RouterOS 7.23.2
#
# Replace YOUR_* placeholders before import.
#
/interface wireguard
add listen-port=2071 mtu=1420 name=wg-to-hub
/routing table
add fib name=to-hub
/interface wireguard peers
add allowed-address=0.0.0.0/0 client-allowed-address=::/0 endpoint-address=\
    YOUR_HUB_PUBLIC_IP endpoint-port=51820 interface=wg-to-hub name=peer-to-hub \
    persistent-keepalive=5s public-key=\
    "YOUR_HUB_PUBLIC_KEY"
/ip address
add address=10.10.0.2/30 interface=wg-to-hub network=10.10.0.0
/ip firewall address-list
add address=192.168.88.50 list=to-remote
add address=192.168.88.60 list=to-remote
/ip firewall mangle
add action=mark-routing chain=prerouting dst-address-type=!local \
    new-routing-mark=to-hub passthrough=no src-address-list=to-remote
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1
/ip route
add check-gateway=ping dst-address=0.0.0.0/0 gateway=10.10.0.1 routing-table=\
    to-hub
/routing rule
add action=lookup disabled=no routing-mark=to-hub table=to-hub
/system identity
set name=r-main
