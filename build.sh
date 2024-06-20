#!/bin/sh

docker network create nginx-proxy
docker compose --env-file ".env" build
