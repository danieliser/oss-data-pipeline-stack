#!/bin/bash

# Start the hydra container.
docker-compose -f ./docker-compose.yml up -d

# Use a loop to wait for the hydra container to be ready.
while true; do
    # Check if the hydra container is ready.
    hydra_state=$(docker container inspect --format='{{.State.Status}}' hydra)

    # Check the status of the Postgres database inside the container.
    postgres_ready=$(docker exec hydra pg_isready)

    # If both the hydra container and the Postgres database are ready, break the loop.
    if [[ "$hydra_state" == "running" && "$postgres_ready" == *"accepting connections"* ]]; then
        break
    fi

    # Wait 1 second before checking again.
    sleep 1
done

# Prompt for new superuser name & password
read -p "Enter a new superuser name: " superuser_name

# Define a global variable to store the password
password=""

get_password() {
    local confirm

    while true; do
        read -s -p "Enter password: " password
        echo
        read -s -p "Confirm password: " confirm
        echo

        if [ "$password" != "$confirm" ]; then
            echo "Passwords do not match. Please try again."
        else
            # Set the global password variable
            export password
            break
        fi
    done
}

# Check if user exists and ask if users wants to drop or skip this step.
user_exists=$(docker exec hydra sh -c "psql -U postgres -d postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$superuser_name'\"")

# If user exists ask if password should be changed, otherwise create it
if [[ -n "$user_exists" ]]
then
    while true; do
        read -p "User $superuser_name already exists. Do you want to change the password? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            get_password
            docker exec hydra sh -c "psql -U postgres -d postgres -c \"ALTER USER $superuser_name WITH PASSWORD '$password';\""
            echo "Changed password for user $superuser_name to $password"
            break
        elif [[ $REPLY =~ ^[Nn]$ ]]; then
            break
        else
            echo "Please enter y or n."
        fi
    done
else
    get_password
    docker exec hydra sh -c "psql -U postgres -d postgres -c \"CREATE USER $superuser_name WITH PASSWORD '$password';\""
    echo "Created user $superuser_name with password *********"
fi