# RouterOS 7.19.4
# 
#
/interface bridge
add name=br-em
/interface list
add name=LAN
add name=WAN
/ip pool
add name=dhcp_pool0 ranges=172.16.1.2-172.16.1.254
/ip dhcp-server
add address-pool=dhcp_pool0 interface=ether3 name=dhcp1
/routing table
add disabled=no fib name=isp-1-rt
add disabled=no fib name=isp-2-rt
/interface list member
add interface=ether3 list=LAN
add interface=ether1 list=WAN
add interface=ether2 list=WAN
/ip address
add address=172.16.1.1/24 interface=ether3 network=172.16.1.0
/ip dhcp-client
add default-route-tables=default,isp-1-rt interface=ether1
add default-route-distance=2 default-route-tables=default,isp-2-rt:1 \
    interface=ether2
/ip dhcp-server network
add address=172.16.1.0/24 dns-server=172.16.1.1 gateway=172.16.1.1
/ip dns
set allow-remote-requests=yes
/ip firewall mangle
add action=mark-connection chain=prerouting connection-mark=no-mark \
    in-interface=ether1 new-connection-mark=isp-1-conn passthrough=no
add action=mark-connection chain=prerouting connection-mark=no-mark \
    in-interface=ether2 new-connection-mark=isp-2-conn passthrough=no
add action=mark-routing chain=prerouting connection-mark=isp-1-conn \
    dst-address-type=!local in-interface-list=!WAN new-routing-mark=isp-1-rt \
    passthrough=no
add action=mark-routing chain=prerouting connection-mark=isp-2-conn \
    dst-address-type=!local in-interface-list=!WAN new-routing-mark=isp-2-rt \
    passthrough=no
add action=mark-routing chain=output connection-mark=isp-1-conn \
    dst-address-type=!local new-routing-mark=isp-1-rt passthrough=no
add action=mark-routing chain=output connection-mark=isp-2-conn \
    dst-address-type=!local new-routing-mark=isp-2-rt passthrough=no
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1
add action=masquerade chain=srcnat out-interface=ether2
/ip route
add disabled=no distance=254 dst-address=0.0.0.0/0 gateway=br-em \
    routing-table=main suppress-hw-offload=no
/tool romon
set enabled=yes
