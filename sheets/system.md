# System - Common Commands

Check disk usage | df -h
Check directory size | du -sh <directory>
Monitor processes | htop
Find process by name | ps aux | grep <name>
Kill process by PID | kill <pid>
Force kill process | kill -9 <pid>
Check memory usage | free -h
Show system info | neofetch
Check CPU info | lscpu
List USB devices | lsusb
List PCI devices | lspci
Check network interfaces | ip addr
Test network connectivity | ping <host>
Check open ports | ss -tulpn
Find files | find <path> -name <pattern>
Search in files | grep -r <pattern> <path>
Archive directory | tar -czf archive.tar.gz <directory>
Extract archive | tar -xzf archive.tar.gz
Check systemd service status | systemctl status <service>
Restart systemd service | systemctl restart <service>
