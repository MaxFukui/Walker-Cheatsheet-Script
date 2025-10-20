# Internet Repeater problem - Quick solutions

To see the IP | ip addr
------------------------------------- | ---------------------------------------
internet configuration | /etc/systemd/network/20-
Configuration pc using repeater | RequeredForOnline=no
Configuration pc using repeater | Commment DHCP
------------------------------------- | ---------------------------------------
Delete ip repeater | sudo ip addr del <ip>/24 dev enp3s0
Delete gateway repeater | sudo ip route del default <ip-gateway>
Turn off Net interface | sudo ip link set enp3s0 down
Turn on Net interface | sudo ip link set enp3s0 up
Restart net interface | systemctl restart systemd-networkd

