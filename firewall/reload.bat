@echo off

docker-compose down
docker image prune -a -f
docker-compose up -d
