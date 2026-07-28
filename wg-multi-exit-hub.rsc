# WireGuard multi-exit hub (CHR)
# RouterOS 7.23.2
#
# Replace YOUR_* placeholders before import.
#
/interface wireguard
add listen-port=51821 mtu=1420 name=wg-exit-a
add listen-port=51822 mtu=1420 name=wg-exit-b
add listen-port=51820 mtu=1420 name=wg-r-main
/routing table
add fib name=exit-a
add fib name=exit-b
/interface wireguard peers
add allowed-address=0.0.0.0/0 client-allowed-address=::/0 interface=wg-exit-a \
    name=peer-krk public-key="YOUR_EXIT_A_PUBLIC_KEY" \
    responder=yes
add allowed-address=0.0.0.0/0 client-allowed-address=::/0 interface=wg-exit-b \
    name=peer-to-lon public-key=\
    "YOUR_EXIT_B_PUBLIC_KEY" responder=yes
add allowed-address=192.168.88.0/24,10.10.0.0/30 client-allowed-address=::/0 \
    interface=wg-r-main name=peer-office public-key=\
    "YOUR_SPOKE_PUBLIC_KEY" responder=yes
/ip address
add address=10.254.1.1/30 interface=wg-exit-a network=10.254.1.0
add address=10.254.2.1/30 interface=wg-exit-b network=10.254.2.0
add address=10.10.0.1/30 interface=wg-r-main network=10.10.0.0
/ip firewall address-list
add address=192.168.88.50 comment="-> Krakow" list=via-a
add address=192.168.88.60 comment="-> London" list=via-b
/ip firewall mangle
add action=mark-routing chain=prerouting dst-address-type=!local \
    new-routing-mark=exit-a passthrough=no src-address-list=via-a
add action=mark-routing chain=prerouting dst-address-type=!local \
    new-routing-mark=exit-b passthrough=no src-address-list=via-b
/ip route
add gateway=YOUR_UPSTREAM_GATEWAY
add dst-address=192.168.88.0/24 gateway=10.10.0.2
add check-gateway=ping dst-address=0.0.0.0/0 gateway=10.254.1.2 \
    routing-table=exit-a
add check-gateway=ping dst-address=0.0.0.0/0 gateway=10.254.2.2 \
    routing-table=exit-b
/routing rule
add action=lookup-only-in-table disabled=no routing-mark=exit-a table=exit-a
add action=lookup-only-in-table disabled=no routing-mark=exit-b table=exit-b
/system identity
set name=chr-yt-01
