#!/bin/bash
set -e

source .env

CONTAINER_NAME=local-jenkins

cleanup_and_exit() {
    echo -e "\nCleaning up and exiting please wait..."
    docker stop $CONTAINER_NAME > /dev/null 2>&1
    docker rm $CONTAINER_NAME > /dev/null 2>&1
    exit 0
}

# Trap interrupt signal (Ctrl+C) and call cleanup_and_exit function
trap 'cleanup_and_exit' INT

LOCAL_JENKINS_DOCKER_SOCKET=$(echo $DOCKER_HOST | sed 's|unix://||')
LOCAL_JENKINS_DOCKER_BIN=$(which docker)

echo -e "\n\nLOCAL_JENKINS_DOCKER_SOCKET=$LOCAL_JENKINS_DOCKER_SOCKET"
echo -e "LOCAL_JENKINS_DOCKER_BIN=$LOCAL_JENKINS_DOCKER_BIN\n\n"

docker build -t ${CONTAINER_NAME} .

docker run -d \
  --name ${CONTAINER_NAME} \
  -p "$LOCAL_JENKINS_PORT:8080" \
  -v $(pwd)/../.:/mnt/local-project:ro \
  -v ${LOCAL_JENKINS_DOCKER_SOCKET}:/var/run/docker.sock \
  -v ${LOCAL_JENKINS_DOCKER_BIN}:/usr/bin/docker \
  --env-file .env \
  ${CONTAINER_NAME}

docker logs -f ${CONTAINER_NAME}


