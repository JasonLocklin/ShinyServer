# Demonstration of Self-Hosted SurveyDown Deployment with Docker Compose

This project provides a minimal working example of self-hosting `surveydown` surveys with a self-hosted PostgreSQL database, all orchestrated with Docker Compose. It is designed to be as simple as possible to understand and use for demonstration purposes, local development, and as a starting point for understanding how such a system can be deployed. **It should be used with appropriate security measures if adapting for production environments.**

For more featureful deployment of shiny apps, including surveydown, consider [Shinyproxy](https://www.shinyproxy.io/) and similar projects. 

## Overview

This setup creates a multi-container Docker application that includes:

  * **PostgreSQL Database:** A dedicated database to store `surveydown` responses.
  * **Shiny Server:** Runs the `surveydown` application. This also periodically runs an R script that exports the `responses` table from PostgreSQL to Parquet files for analysis.
  * **Caddy Reverse Proxy:** Handles SSL/TLS termination, routes traffic to the Shiny server, and serves password-protected Parquet data exports.

## Features

  * **Self-contained:** All components run within Docker containers, simplifying deployment.
  * **Persistent Data:** Database data and Caddy's SSL certificates are persisted using Docker volumes.
  * **Automated Data Export:** Survey responses are automatically dumped to Parquet files every 10 minutes, making data extraction easy.
  * **Secure Access:** Caddy provides HTTPS (SSL/TLS) for your survey and password protection for data downloads.
  * **Demonstration-ready:** A good starting point to understand the architecture.

## Project Structure

Here is the updated file structure table based on the `ls` output you provided, showing the correct project layout:

```
.
├── Caddyfile                      # Caddy web server configuration
├── docker-compose.yml             # Defines and orchestrates the Docker services
├── dot.env.example                # Template for environment variables (rename to .env)
├── LICENSE                        # Project license file
├── README.md                      # Project README file
├── data_dumps/                    # Local directory for generated Parquet files (created by Docker)
├── data-serializer-logs/          # Local directory for data serializer logs (contains data-serializer.log)
│   └── data-serializer.log        # Log file for the data serialization cron job
├── shiny-logs/                    # Local directory for Shiny Server logs (created by Docker)
└── shiny-server/                  # Directory for the Shiny Server application build context
    ├── crontab                    # Cron job configuration for the R script
    ├── docker-entrypoint.sh       # Entrypoint script to start cron and Shiny Server
    ├── Dockerfile                 # Dockerfile for the Shiny Server (includes cron setup)
    └── dump_to_parquet.R          # R script to dump data to Parquet
```

## Prerequisites

  * Docker Desktop (for Windows/macOS) or Docker Engine & Docker Compose (for Linux) installed on your system.
  * A domain name connected with the IP address of the server

For demonstrating, I created a $5 micro VPS on OVH. I used the "Debian 12 with Docker" image to get started. Most VPSs come with a free un-memorable domain name (For OVH, it looks like randomstring.vps.ovh.ca). That would work fine for demonstrating. Don't forget to set it in the Caddyfile.

SSH is sufficient to set all this up. Connect, `sudo -s`, git pull this repository in `/opt` and get started configuring.

## Setup and Deployment

Follow these steps to get your `surveydown` deployment up and running.

### Step 1: Configuration

Several files need to be configured for your specific environment.

1.  **Create `.env` file:**

      * Rename `.env.example` to `.env`.
      * Open `.env` and fill in your desired database credentials. These will be used by both PostgreSQL and your `surveydown` application to connect to the database.
        ```ini
        # Database Configuration
        SD_HOST=postgresql
        SD_PORT=5432 # Note: Using 5432 internally for Docker network communication
        SD_DBNAME=shiny_db
        SD_USER=shiny_user
        SD_PASSWORD=my-secure-password-goes-here # CHANGE THIS!
        SD_TABLE=responses
        SURVEYDOWN_GIT_URL=https://yourgithubsurveyrepo
        ```
      * **Note:** `SD_HOST` is set to `postgresql` because that's the service name of the PostgreSQL container within the Docker network. `SD_PORT` for the application to connect to is the default PostgreSQL port `5432`.

2. **Set your Survey Location**
      * In docker-compose.yml, change the line starting with `SURVERYDOWN_GIT_URL:` to point to the git repository of your survey. Every time the containers build, it will pull in the most recent version of your survey.

3.  **Update `Caddyfile`:**

      * Open `Caddyfile`.
      * **Change your domain:** Replace `shiny.locklin.science` with your actual domain name. Caddy will automatically obtain SSL certificates for this domain. If you are just testing locally, you can connect to the shiny server directly at (http://localhost:3838).
      * **Set data download credentials:** In the `handle @data_dumps_path` block of `Caddyfile`, change `your_username` and `your_secure_password_hash_here`. Instructions below.

#### Step 1b: Generate Caddy Password Hash

For the password-protected data downloads, you need to provide a hashed password in the `Caddyfile`.

1.  **Generate the hash:** Run one of the following commands, replacing `your_password_here` with your desired plaintext password:
      * If you have Caddy installed directly on your host:
        ```bash
        caddy hash-password --plaintext your_password_here
        ```
      * If you prefer to use Caddy via Docker (recommended if Caddy is not installed globally):
        ```bash
        docker run --rm caddy caddy hash-password --plaintext your_password_here
        ```
2.  **Copy the hash:** Copy the long string that is outputted (it starts with `$` and is very long).
3.  **Paste into `Caddyfile`:** In your `Caddyfile`, replace `your_secure_password_hash_here` with the hash you just generated.

### Step 2: Deploy with Docker Compose

Navigate to the root directory of this project (where `docker-compose.yml` is located) in your terminal and run:

```bash
docker-compose up -d --build
```

  * `up`: Starts the services defined in `docker-compose.yml`.
  * `-d`: Runs the containers in detached mode (in the background).
  * `--build`: Forces Docker Compose to rebuild the `shiny_server` and `data_serializer` images, ensuring any changes to your Dockerfiles or cloned repositories are applied.

The first time you run this, it will download base images and build your custom images, which may take some time.

## Accessing the Application

  * **Shiny Survey:** Once deployed, your `surveydown` application should be accessible via HTTPS at the domain you configured in your `Caddyfile` (e.g., `https://yourdomain.com/survey`).
  * The standard shiny landing page is currently available at `https://yourdomain.com` and the surveydown templates are available at `https://yourdomain.com/templates`
  * **Data Downloads:** The generated Parquet files can be accessed at `https://yourdomain.com/data-downloads/`. You will be prompted for the username and password configured in your `Caddyfile`.

## Data Management

### Database Data

The PostgreSQL database stores the `surveydown` responses.

  * **Persistence:** The `postgres_data` Docker volume ensures that your database data persists even if the PostgreSQL container is removed or recreated.
  * **Ephemeral Mindset:** It's recommended to treat the database itself as potentially ephemeral. Rely on the Parquet data dumps for long-term data retention and analysis.
  * **Access:** The database is only accessible internally within the Docker network by the `shiny_server` and `data_serializer` services for security simplicity. You cannot directly access it from your host machine without adding port mappings in `docker-compose.yml` (not recommended for production without firewall rules).

### Parquet Data Dumps

  * **Location:** Parquet files are generated every 10 minutes and stored in the local `data_dumps/` directory on your host machine. This directory is created automatically by Docker Compose if it doesn't exist.
  * **Contents:** Each Parquet file contains a dump of the `responses` table from PostgreSQL at the time of its creation, with a timestamp in the filename.
  * **Accessibility:** These files are exposed via Caddy at the password-protected `/data-downloads/` path, allowing for easy download through a web browser or script.
  * **Temporary Nature:** While accessible, consider these files as temporary copies for transfer. For robust production systems, implement a process to regularly move these files to secure, long-term storage (e.g., cloud storage, data warehouse).

### Logs

  * **Shiny Server Logs:** Located in the `shiny-logs/` directory on your host.
  * **Data Serializer Logs:** Located in the `data-serializer-logs/` directory on your host. This will contain output from the cron job execution.
  * **Caddy Logs:** Configured to write to `/var/log/caddy/access.log` within the Caddy container, but is not directly volume-mounted to the host in this setup (though you could add a volume mount for it if desired). You can view Caddy logs using `docker-compose logs caddy`.


## Security Considerations for Production

This setup is a toy example. For production use, consider the following:

  * **Strong Passwords:** Use very strong, unique passwords for database credentials and Caddy's basic authentication.
  * **Data Dumps:**
      * The `/data-export/` path offers basic HTTP authentication. For higher security, consider more robust authentication mechanisms or VPN access.
      * Change the R script to push the data to a secure server rather than saving the files locally.

## License

This project is open-source and available under the MIT License.

-----
