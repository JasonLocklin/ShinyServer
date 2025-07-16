#!/bin/bash
set -e

chown -R shiny:shiny /srv

# Write Docker env vars to .Renviron for the shiny user
cat <<EOF > /home/shiny/.Renviron
SD_HOST=${SD_HOST}
SD_PORT=${SD_PORT}
SD_DBNAME=${SD_DBNAME}
SD_USER=${SD_USER}
SD_PASSWORD=${SD_PASSWORD}
SD_TABLE=${SD_TABLE}
EOF

# Start cron in the background (for data serialization)
cron -f &

# Start Shiny Server in the foreground
exec /usr/bin/shiny-server
