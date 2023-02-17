#!/bin/bash

# Given no argument start all, otherwise stop, restart or status of all docker-compose.yml files in the current directory and subdirectories

# Get the directory of this script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Get all the directories with a docker-compose.yml or docker-compose.yaml file
get_compose_dirs() {
  find "$DIR/services" -regex ".*/docker-compose\.\(yml\|yaml\)" -exec dirname {} \;
}

# Get the first argument
ARG=$1

# For each directory, perform the appropriate action
for COMPOSE_DIR in $(get_compose_dirs); do
  cd "$COMPOSE_DIR"

  # Perform the appropriate action based on the first argument
  case $ARG in
  stop)
    echo "Stopping $COMPOSE_DIR"
    docker-compose down
    ;;
  restart)
    echo "Restarting $COMPOSE_DIR"
    docker-compose restart
    ;;
  status)
    echo "Status of $COMPOSE_DIR"
    docker-compose ps
    ;;
  "" | "start")
    echo "Starting $COMPOSE_DIR"
    docker-compose up -d
    ;;
  *)
    echo "Unknown argument: $ARG"
    break;
    ;;
  esac
done
