
# Docker - Container Management

List all containers | docker ps -a
List running containers | docker ps
Start container | docker start <container>
Stop container | docker stop <container>
Restart container | docker restart <container>
Remove container | docker rm <container>
Remove all stopped containers | docker container prune
View container logs | docker logs <container>
Follow container logs | docker logs -f <container>
Execute command in container | docker exec -it <container> <command>
Build image from Dockerfile | docker build -t <name>:<tag> .
Pull image from registry | docker pull <image>
Push image to registry | docker push <image>
List images | docker images
Remove image | docker rmi <image>
Remove unused images | docker image prune -a
Create network | docker network create <network>
List networks | docker network ls
Remove network | docker network rm <network>
Inspect container | docker inspect <container>
Show container stats | docker stats
Copy files to container | docker cp <file> <container>:<path>
Copy files from container | docker cp <container>:<path> <file>
Run container from image | docker run -d --name <name> <image>
Run container with port mapping | docker run -d -p <host>:<container> <image>
