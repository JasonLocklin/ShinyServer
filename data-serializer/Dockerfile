# Use the same base image as your shiny_server
FROM rocker/shiny-verse:latest

# Install PostgreSQL client (pg_dump) and cron
RUN apt-get update && apt-get install -y \
    postgresql-client \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Install R packages for database interaction and Parquet
RUN R -e "install.packages(c('RPostgres', 'DBI', 'arrow'), repos='https://cran.rstudio.com/')"

# Copy the dumping script
COPY dump_to_parquet.R /usr/local/bin/dump_to_parquet.R
RUN chmod +x /usr/local/bin/dump_to_parquet.R

# Set up cron job
COPY crontab /etc/cron.d/data-serializer-cron
RUN chmod 0644 /etc/cron.d/data-serializer-cron \
    && crontab /etc/cron.d/data-serializer-cron

# Create a directory for the output files
RUN mkdir -p /app/data_dumps

# Keep container running to allow cron to execute
CMD ["cron", "-f"]
