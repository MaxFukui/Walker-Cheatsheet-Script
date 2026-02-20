# iwctl - Wireless Connection Manager

Enter interactive prompt | iwctl
List all wifi devices | device list
Show device info | device <device> show
Power on device | device <device> set-property Powered on
Power off device | device <device> set-property Powered off
Scan for networks | station <device> scan
List available networks | station <device> get-networks
Connect to network | station <device> connect <SSID>
Connect with password inline | station <device> connect-hidden <SSID>
Show connection status | station <device> show
Disconnect from network | station <device> disconnect
List known networks | known-networks list
Forget a known network | known-networks <SSID> forget
Set network to autoconnect | known-networks <SSID> set-property AutoConnect on
Disable autoconnect | known-networks <SSID> set-property AutoConnect off
List active peers (P2P) | peer list
Show adapter info | adapter list
One-liner connect no prompt | iwctl station <device> connect <SSID>
One-liner scan no prompt | iwctl station <device> scan
One-liner list no prompt | iwctl station <device> get-networks
Check iwctl daemon status | systemctl status iwd
Restart iwd daemon | systemctl restart iwd
Enable iwd on boot | systemctl enable iwd
