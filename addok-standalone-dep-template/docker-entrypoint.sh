#!/usr/bin/env bash

# Lancer Redis en arrière-plan
echo "Starting Redis..."
redis-server /usr/local/etc/redis/redis.conf &

# Attendre que Redis soit prêt
echo "Waiting for Redis to be ready..."
until nc -z localhost 6379; do
    sleep 1
done
echo "Redis is ready."

# Lancer Addok au premier plan
echo "Starting Addok..."
cp /etc/addok/addok.conf /etc/addok/addok.patched.conf

echo "LOG_DIR = '/logs'" >> /etc/addok/addok.patched.conf

if [ "$LOG_QUERIES" = "1" ]; then
  echo Will log queries
  echo "LOG_QUERIES = True" >> /etc/addok/addok.patched.conf
fi

if [ "$LOG_NOT_FOUND" = "1" ]; then
echo Will log Not Found
  echo "LOG_NOT_FOUND = True" >> /etc/addok/addok.patched.conf
fi

if [ ! -z "$SLOW_QUERIES" ]; then
  echo Will log slow queries
  echo "SLOW_QUERIES = ${SLOW_QUERIES}" >> /etc/addok/addok.patched.conf
fi

WORKERS=${WORKERS:-1}
WORKER_TIMEOUT=${WORKER_TIMEOUT:-30}
gunicorn -w $WORKERS --timeout $WORKER_TIMEOUT -b 0.0.0.0:7878 --access-logfile - addok.http.wsgi
