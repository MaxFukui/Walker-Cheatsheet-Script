# SSH

Tunneling access compressed data for browsing | ssh -D 8280 -N -C <server>
Forward specific port to internal LAN machine | ssh -L <local_port>:<internal_ip>:<remote_port> <server>

## Jump Host
~ Jump host (-J) relays your connection through an intermediary server
Connect via single jump host | ssh -J <jump> <target>
Connect via multiple jump hosts | ssh -J <jump1>,<jump2> <target>
Connect with different users | ssh -J <user>@<jump> <user>@<target>
Copy file through jump host | scp -J <jump> <file> <target>:<path>
Add jump host to SSH config | ProxyJump <jump>
Dynamic port forward via jump | ssh -J <jump> -D 8280 -N <target>
Forward port via jump host | ssh -J <jump> -L <local_port>:<internal_ip>:<remote_port> <target>
