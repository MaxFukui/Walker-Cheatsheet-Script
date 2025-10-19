Create a cheatsheet in markdown format following these STRICT requirements:

FORMAT RULES:
1. First line MUST be: # Title - Brief Description
2. Every other line MUST be: Description | command
3. Keep descriptions under 50 characters
4. Include 15-25 practical, commonly-used commands
5. NO empty lines between commands
6. NO additional markdown (no bold, italic, code blocks, bullets, etc.)
7. NO explanations, comments, or text outside the format
8. Group related commands together logically
9. Use simple angle brackets for placeholders: <placeholder> NOT \<placeholder\>
10. NO escaped characters (no backslashes before < > or _)

EXAMPLE:
# Docker - Container Management

List all containers | docker ps -a
Start container | docker start <container>
Stop container | docker stop <container>
Remove container | docker rm <container>
View container logs | docker logs <container>
Execute command in container | docker exec -it <container> <command>
Build image from Dockerfile | docker build -t <name> .
Pull image from registry | docker pull <image>
Push image to registry | docker push <image>
List images | docker images
Remove image | docker rmi <image>
Create network | docker network create <network>
List networks | docker network ls
Inspect container | docker inspect <container>
Show container stats | docker stats

