# WireGuard multi-exit — exit node
# RouterOS 7.23.2
#
# Replace YOUR_* placeholders before import.
# This is exit A. For exit B use endpoint-port=51822 and address 10.254.2.2/30.
#
/interface wireguard
add listen-port=28102 mtu=1420 name=wg-to-hub
/interface wireguard peers
add allowed-address=0.0.0.0/0 client-allowed-address=::/0 endpoint-address=\
    YOUR_HUB_PUBLIC_IP endpoint-port=51821 interface=wg-to-hub name=peer-to-hub \
    persistent-keepalive=5s public-key=\
    "YOUR_HUB_PUBLIC_KEY"
/ip address
add address=10.254.1.2/30 interface=wg-to-hub network=10.254.1.0
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1
/ip route
add disabled=no dst-address=192.168.88.0/24 gateway=10.254.1.1 routing-table=\
    main
/system identity
set name=exit-krk
