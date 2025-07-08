FROM rocker/shiny-verse:latest

WORKDIR /srv/shiny-server

# Install system dependencies if needed
RUN apt-get update && apt-get install -y \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install additional R packages
RUN R -e "install.packages(c('surveydown', 'DBI', 'RPostgres'), repos='https://cran.rstudio.com/')"

# Alternatively, the development version
#install.packages("pak")
#pak::pak("surveydown-dev/surveydown")


# Now pull in surveys by cloning their repos
# Templates for testing:
RUN git clone https://github.com/surveydown-dev/templates.git /srv/shiny-server/templates


# Expose port 3838
EXPOSE 3838

# Start shiny-server
CMD ["/usr/bin/shiny-server"]
