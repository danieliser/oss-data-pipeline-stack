#!/bin/bash

note=""

# Function to clear the screen and display the title
refresh_screen() {
  clear
  echo Open Source Data Pipeline Stack Assistant
  len=$((${#note} + 6))
  # check if note is empty, if so set len to 40
  if [[ -z "$note" ]]; then
    len=40
  fi

  printf '%0.s-' $(seq 1 $len)
  echo
  # if $note is not empty, display it
  if [[ -n "$note" ]]; then
    echo "-- $note --"
    # echo - for every character in $note + 6, minimum 40
    printf '%0.s-' $(seq 1 $len)
    echo
  fi
  echo ""
}

# For each subdirectory of the services folder, do the following:
# 1. copy .example.env to .env
# 2. if setup.sh exists, run it.
# 3. ask if user wants to start the services.
services=$(find services -mindepth 1 -maxdepth 1 -type d)

for service in $services; do
  echo $service

  if [ -f "$service/.example.env" ]; then
    cp "$service/.example.env" "$service/.env"
  fi
  if [ -f "$service/setup.sh" ]; then
    # execute setup.sh in the service folder with the current working directory set to the service folder
    bash -c "cd $service; ./setup.sh"
  fi
done

refresh_screen

# ask if user wants to start the service accepting only y or n
while true; do
  read -p "Do you wish to start all services? [y/n] " yn
  case $yn in
  [Yy]*)
    if [ -f "stack.sh" ]; then
      bash "stack.sh"
    fi
    break
    ;;
  [Nn]*)
    # Set up some color variables
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    MAGENTA='\033[0;35m'
    RESET='\033[0m'
    UNDERLINE='\033[4m'

    # Use color variables to highlight the statements
    echo
    printf "${YELLOW}Modify the ${UNDERLINE}\e[1m.env\e[0m${YELLOW} file in each service folder to configure the services.${RESET}\n"
    echo
    printf "${MAGENTA}If you want to use local or remote storage, you can use \e[1mdocker-compose.override.yml\e[0m${MAGENTA} to override the volume configuration. See \e[1mdocker-compose.yml\e[0m${MAGENTA} for commented examples.${RESET}\n"
    echo
    printf "${GREEN}You can then run ${UNDERLINE}\e[1m./services.sh start\e[0m${GREEN} to start all of the services.${RESET}\n"
    echo
    break
    ;;
  *) echo "Please answer yes or no." ;;
  esac
  echo "End of loop"
done
