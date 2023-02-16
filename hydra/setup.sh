#!/bin/bash

source ../bin/inquiry.sh

# Define the log file path
LOG_FILE="commands.log"

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

# Function to log a command and then execute it
log_and_execute() {
    local command=$1
    echo "Running command: $command"
    echo "$command" >>"$LOG_FILE"
    eval "$command"
}

refresh_screen

# Start the hydra container.
log_and_execute "docker-compose -f ./docker-compose.yml up -d"

root_user="postgres"

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

note="Set up superuser for Postgres database."

refresh_screen

# Prompt for new superuser name & password
text_input "Enter a new superuser name: " superuser_name

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
user_exists=$(docker exec hydra sh -c "psql -U $root_user -d postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$superuser_name'\"")

# If user exists ask if password should be changed, otherwise create it
if [[ -n "$user_exists" ]]; then
    while true; do
        read -p "User $superuser_name already exists. Do you want to change the password? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            get_password
            log_and_execute "docker exec hydra sh -c \"psql -U $root_user -d postgres -c \\\"ALTER USER $superuser_name WITH PASSWORD '$password';\\\"\""
            echo "Changed password for user $superuser_name to $password"
            sleep 1.5
            break
        elif [[ $REPLY =~ ^[Nn]$ ]]; then
            break
        else
            echo "Please enter y or n."
        fi
    done
else
    get_password
    log_and_execute "docker exec hydra sh -c \"psql -U $root_user -d postgres -c \\\"CREATE USER $superuser_name WITH SUPERUSER CREATEDB CREATEROLE PASSWORD '$password';\\\"\""
    echo "Created user $superuser_name with password *********"
    sleep 1.5
fi

note="Set up new database"

refresh_screen

# From here on out we will use the new superuser to create databases and users
echo "Using user $superuser_name to create databases, schemas, & users"
db_user=$superuser_name

# Prompt if they need new database, if so prompt for name and create it
while true; do
    read -p "Do you need a new database? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        note="Set up new database"
        refresh_screen

        text_input "Enter a new database name: " database_name
        log_and_execute "docker exec hydra sh -c \"psql -U $db_user -d postgres -c \\\"CREATE DATABASE $database_name;\\\"\""
        echo "Created database $database_name"

        note="Set up schemas for database $database_name"

        # Prompt if they need to create a new schema, if so prompt for name and create it
        while true; do
            read -p "Do you need a new schema? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                text_input "Enter a new schema name: " schema_name
                log_and_execute "docker exec hydra sh -c \"psql -U $db_user -d $database_name -c \\\"CREATE SCHEMA $schema_name;\\\"\""
                echo "Created schema $schema_name"
                sleep 1.5
            elif [[ $REPLY =~ ^[Nn]$ ]]; then
                break
            else
                echo "Please enter y or n."
            fi
        done
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
        break
    else
        echo "Please enter y or n."
    fi
done

# Get list of databases
databases=($(docker exec hydra sh -c "psql -U postgres -d postgres -t -c 'SELECT datname FROM pg_database;'"))

# Get list of schemas
schemas=($(docker exec hydra sh -c "psql -U $db_user -d postgres -t -c 'SELECT schema_name FROM information_schema.schemata;'"))

note="Set up users"
refresh_screen

# Prompt if they need additional users, if so give continous prompt until they hit escape, then create them
while true; do
    read -p "Do you need to create a new user? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        text_input "Enter a new user name: " user_name
        get_password
        log_and_execute "docker exec hydra sh -c \"psql -U $db_user -d postgres -c \\\"CREATE USER $user_name WITH PASSWORD '$password';\\\"\""
        echo "Created user $user_name with password *********"

        # Prompt if they need to grant privileges to the new user, if so render checkbox_list of databases and schemas
        while true; do
            read -p "Do you need to grant privileges to the new user? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then

                # Render checkbox list of databases and schemas
                echo "Select the databases you want to grant privileges to the new user for."
                echo "Press space to select and enter to continue."
                echo "Press escape to skip this step."
                # Use checkbox_list to prompt user for selection
                checkbox_input "Select Databases for Read Only:" databases ro_database_selections

                # Use checkbox_list to prompt user for selection
                checkbox_input "Select Databases for Full Access:" databases rw_database_selections

                # Foreach ro_database_selections grant read only privileges to the new user
                for database in "${ro_database_selections[@]}"; do
                    log_and_execute "docker exec hydra sh -c \"psql -U $db_user -d postgres -c \\\"GRANT CONNECT ON DATABASE $database TO $user_name;\\\"\""
                    log_and_execute "docker exec hydra sh -c \"psql -U $db_user -d postgres -c \\\"GRANT USAGE ON SCHEMA public TO $user_name;\\\"\""
                    log_and_execute "docker exec hydra sh -c \"psql -U $db_user -d postgres -c \\\"GRANT SELECT ON ALL TABLES IN SCHEMA public TO $user_name;\\\"\""
                    log_and_execute "docker exec hydra sh -c \"psql -U $db_user -d postgres -c \\\"GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO $user_name;\\\"\""
                    log_and_execute "docker exec hydra sh -c \"psql -U $db_user -d postgres -c \\\"GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO $user_name;\\\"\""
                    echo "Granted read only privileges to user $user_name on database $database"
                    sleep 0.5
                done

                # Foreach rw_database_selections grant full access privileges to the new user
                for database in "${rw_database_selections[@]}"; do
                    log_and_execute "docker exec hydra sh -c \"psql -U $db_user -d postgres -c \\\"GRANT CONNECT ON DATABASE $database TO $user_name;\\\"\""
                    log_and_execute "docker exec hydra sh -c \"psql -U $db_user -d postgres -c \\\"GRANT ALL PRIVILEGES ON DATABASE $database TO $user_name;\\\"\""
                    echo "Granted full access privileges to user $user_name on database $database"
                    sleep 0.5
                done

                break
            elif [[ $REPLY =~ ^[Nn]$ ]]; then
                break
            else
                echo "Please enter y or n."
            fi
        done

    elif
        [[ $REPLY =~ ^[Nn]$ ]]
    then
        break
    else
        echo "Please enter y or n."
    fi
done

note="Hydra is ready to go!"
refresh_screen

exit
