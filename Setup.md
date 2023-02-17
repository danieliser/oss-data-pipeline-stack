Some notes on how to setup the stack manually without the setup scripts.

# 1. Setup Hydra/Postgres/Cloudbeaver

## Modify the `.env` & `docker-compose.yml` files

Set passwords, ports & volumes accordingly.

## Start the containers

```bash
docker-compose up -d
```

## Connect to the DB & create a new superuser with password via docker

```bash
docker exec -it hydra psql -U postgres -c "CREATE ROLE daniel WITH SUPERUSER LOGIN PASSWORD 'password';"
```

## Create a new database with the new user

```bash
docker exec -it hydra psql -d postgres -U daniel -c "CREATE DATABASE codeatlantic;"
```

## Reconnect to the db in -it mode with new user.

```bash
docker exec -it hydra psql -d codeatlantic -U daniel
```

## Create extra schemas if needed

```sql
CREATE SCHEMA IF NOT EXISTS popupmaker;
CREATE SCHEMA IF NOT EXISTS contentcontrol;
CREATE SCHEMA IF NOT EXISTS usermenus;
CREATE SCHEMA IF NOT EXISTS ahoy;
```




## Create the database

```sql
CREATE ROLE daniel WITH SUPERUSER LOGIN PASSWORD 'password';

\c
```


# 2. Setup Airbyte

# 3. Setup Prefect

# 4. Setup Appsmith

# 5. Setup DBeaver

# 6. Setup Jupyter
