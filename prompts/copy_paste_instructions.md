# CheatSheet

Create a cheatsheet in markdown format following these STRICT requirements:

FORMAT RULES:
1. First line MUST be: # Title - Brief Description
2. Use ## Section headers to group related entries (they appear in the file but NOT in the menu)
3. Every entry line MUST be: Description | value_to_copy
   - Left side: short human description of what it is (under 30 characters)
   - Right side: the exact value the user will paste (command, shortcut, symbol, etc.)
   - The right side CAN contain pipe characters (|) — only the first | is used as delimiter
4. Use ~ prefix for informational notes: ~ note text
   - These appear in the menu with an ℹ prefix for context
   - They are NOT copied to clipboard when selected
   - Use them sparingly for reminders or context that aids lookup
5. Include 15-25 practical, commonly-used entries
6. NO empty lines between entries within a section
7. NO additional markdown (no bold, italic, code blocks, bullets, etc.)
8. NO explanations or text outside the format
9. Use simple angle brackets for placeholders: <placeholder>
10. NO escaped characters (no backslashes before < > or _)

EXAMPLE:
# Docker - Container Management

~ Use <placeholder> syntax for values you fill in at runtime

## Containers
List all containers | docker ps -a
Start container | docker start <container>
Stop container | docker stop <container>
Remove container | docker rm <container>
View container logs | docker logs <container>
Execute command in container | docker exec -it <container> <command>

## Images
Build image from Dockerfile | docker build -t <name> .
Pull image from registry | docker pull <image>
Push image to registry | docker push <image>
List images | docker images
Remove image | docker rmi <image>

## Network & Inspect
Create network | docker network create <network>
List networks | docker network ls
Inspect container | docker inspect <container>
Show container stats | docker stats
