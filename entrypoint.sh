#!/bin/sh

docker_run="docker run"

if [ -n "$INPUT_MYSQL_ROOT_PASSWORD" ]; then
  echo "Root password not empty, use root superuser"

  docker_run="$docker_run -e MYSQL_ROOT_PASSWORD=$INPUT_MYSQL_ROOT_PASSWORD"
elif [ -n "$INPUT_MYSQL_USER" ]; then
  if [ -z "$INPUT_MYSQL_PASSWORD" ]; then
    echo "The mysql password must not be empty when mysql user exists"
    exit 1
  fi

  echo "Use specified user and password"

  docker_run="$docker_run -e MYSQL_RANDOM_ROOT_PASSWORD=true -e MYSQL_USER=$INPUT_MYSQL_USER -e MYSQL_PASSWORD=$INPUT_MYSQL_PASSWORD"
else
  echo "Using empty password for root"

  docker_run="$docker_run -e MYSQL_ALLOW_EMPTY_PASSWORD=true"
fi

if [ -n "$INPUT_MYSQL_DATABASE" ]; then
  echo "Use specified database"

  docker_run="$docker_run -e MYSQL_DATABASE=$INPUT_MYSQL_DATABASE"
fi

docker_run="$docker_run --health-cmd='healthcheck.sh --connect --innodb_initialized'"
docker_run="$docker_run -d -p $INPUT_HOST_PORT:$INPUT_CONTAINER_PORT mariadb:$INPUT_MARIADB_VERSION --port=$INPUT_CONTAINER_PORT"
docker_run="$docker_run --character-set-server=$INPUT_CHARACTER_SET_SERVER --collation-server=$INPUT_COLLATION_SERVER"
docker_run="$docker_run --lower-case-table-names=2"


CONTAINER_NAME=$(eval "$docker_run" )

echo "Waiting for container $CONTAINER_NAME to start..."

# Loop until the container is healthy
while true; do
    # Get the health status of the container
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null)

    # Check if the container is unhealthy status, but as the docker running, it is now can be connected from client
    if [ "$HEALTH" = "unhealthy" ]; then
        echo "Container $CONTAINER_NAME is healthy!"
        break
    elif [ "$HEALTH" = "healthy" ]; then
        echo "Container $CONTAINER_NAME is healthy!"
        break
    else
        echo "Container $CONTAINER_NAME is still starting (current status: $HEALTH)"
        sleep 1
    fi
done

echo "Container $CONTAINER_NAME is now started and healthy."
