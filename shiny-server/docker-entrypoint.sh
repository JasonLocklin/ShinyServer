#!/bin/bash
# Start cron in the background (for data serialization)
cron -f &

# Start Shiny Server in the foreground
exec /usr/bin/shiny-server
