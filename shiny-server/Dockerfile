# Use a base image with R and Shiny pre-installed.
# This image provides a solid foundation for Shiny applications.
FROM rocker/shiny-verse:latest

# Install system-level dependencies required for R packages and Quarto.
# - libpq-dev: Necessary for the RPostgres package to connect to PostgreSQL databases.
# - git: Required for cloning Git repositories.
# - wget: Used to download files from the internet (e.g., Quarto CLI).
# - gdebi-core: Enables installation of .deb packages.
# The `rm -rf /var/lib/apt/lists/*` cleans up apt cache to keep the image size small.
RUN apt-get update && apt-get install -y \
    libpq-dev \
    git \
    wget \
    postgresql-client \
    cron \
    gdebi-core \
    && rm -rf /var/lib/apt/lists/*

# Install R packages essential for the application.
# `surveydown`: For creating survey applications.
# `DBI`: Database interface for R.
# `RPostgres`: PostgreSQL client for R, often used with DBI.
# `quarto`: For dynamic reporting and document generation.
RUN R -e "install.packages(c('rmarkdown', 'leaflet', 'here', 'DBI', 'RPostgres', 'quarto', 'arrow', 'pak'), repos='https://cran.rstudio.com/')"

# Installing development version of Shinydown (can be added above for stable version instead)
RUN R -e "pak::pak('surveydown-dev/surveydown')"

# Install Quarto CLI.
# Define the Quarto version and construct the download URL.
ENV QUARTO_VERSION=1.7.32
ENV QUARTO_DOWNLOAD_URL=https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb

# Download and install the Quarto .deb package, then clean up the downloaded file.
RUN wget ${QUARTO_DOWNLOAD_URL} -O /tmp/quarto.deb && \
    gdebi -n /tmp/quarto.deb && \
    rm /tmp/quarto.deb

# Set the working directory for subsequent instructions.
WORKDIR /srv/shiny-server

# Define a build argument for the Git repository URL.
# This allows the URL to be passed in during the build process,
# e.g., using `docker build --build-arg SURVERYDOWN_GIT_URL=your_repo_url .`
ARG SURVERYDOWN_GIT_URL=https://github.com/JasonLocklin/surveydown-templates.git

# Clone the specified Git repository into a 'surveydown' directory.
# Note: If /srv/shiny-server is mounted as a volume from the host,
# any content cloned here within the Dockerfile will be overwritten by the mount.
RUN git clone ${SURVERYDOWN_GIT_URL} /srv/shiny-server/survey

# Include a copy of the surveydown templates for troubleshooting/demonstrating
# Note: this is identical to the upstream templates, except set to connect to the database
RUN git clone https://github.com/JasonLocklin/surveydown-templates.git /srv/shiny-server/templates

# Set appropriate ownership for the /srv/shiny-server directory to the 'shiny' user.
# This ensures that the Shiny server has the necessary permissions to read and write files.
RUN chown -R shiny:shiny /srv/shiny-server/
RUN chown -R shiny:shiny /var/log/shiny-server/

# Set up survey data serialization to files
# Copy the dumping script
COPY dump_to_parquet.R /usr/local/bin/dump_to_parquet.R
RUN chmod +x /usr/local/bin/dump_to_parquet.R

# Set up cron job
COPY crontab /etc/cron.d/data-serializer-cron
RUN chmod 0644 /etc/cron.d/data-serializer-cron

# Create a directory for the output files
RUN mkdir -p /app/data_dumps

# Expose port 3838, the default port for Shiny Server.
EXPOSE 3838

# Copy the entrypoint script into the container
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
# Make the entrypoint script executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set the entrypoint for the container
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
