# This script pulls the data from the database
# and saves it to files for analysis and consumption

# In this demo, they are served by the webserver,
# but this script could be modified to push the data
# to annother machine.

# Load necessary packages
library(RPostgres)
library(DBI)
library(arrow)

# Database connection details from environment variables
DB_HOST <- Sys.getenv("SD_HOST")
DB_PORT <- as.numeric(Sys.getenv("SD_PORT"))
DB_DBNAME <- Sys.getenv("SD_DBNAME")
DB_USER <- Sys.getenv("SD_USER")
DB_PASSWORD <- Sys.getenv("SD_PASSWORD")
DB_TABLE <- Sys.getenv("SD_TABLE")

OUTPUT_DIR <- "/srv/data_dumps"
LATEST_FILEPATH <- file.path(OUTPUT_DIR, "responses_latest.parquet")

# Function to exit with a specific status
# status = 0 for success, 1 for error
exit_script <- function(msg, status) {
  message(msg)
  quit(save = "no", status = status)
}

tryCatch({
  # --- Step 1: Read existing 'responses_latest.parquet' if it exists ---
  df_latest_existing <- NULL
  if (file.exists(LATEST_FILEPATH)) {
    message(paste("Reading existing latest data from", LATEST_FILEPATH))
    df_latest_existing <- read_parquet(LATEST_FILEPATH)
  } else {
    message("No existing responses_latest.parquet found. Will create it.")
  }

  # --- Step 2: Connect to PostgreSQL and read new data ---
  message("Connecting to PostgreSQL...")
  con <- dbConnect(RPostgres::Postgres(),
                   host = DB_HOST,
                   port = DB_PORT,
                   dbname = DB_DBNAME,
                   user = DB_USER,
                   password = DB_PASSWORD)
  message("Successfully connected to PostgreSQL.")

  message(paste0("Reading data from table: ", DB_TABLE))
  # Read data from PostgreSQL table
  # dbReadTable is generally more robust for full table dumps than dbGetQuery
  df_new <- dbReadTable(con, DB_TABLE)
  message(paste0("Successfully read ", nrow(df_new), " rows from ", DB_TABLE))

  # --- Step 3: Compare new data with existing latest data ---
  # Use all.equal for a robust comparison of data frames.
  # It returns TRUE if identical, or a character string describing differences.
  if (!is.null(df_latest_existing)) {
    comparison_result <- all.equal(df_new, df_latest_existing)

    if (isTRUE(comparison_result)) {
      # Data is identical, no need to write
      exit_script("No new data found. Data is identical to responses_latest.parquet. Exiting.", 0)
    } else {
      message("New data detected. Differences found:")
      message(comparison_result) # Log the differences
    }
  } else {
    message("No previous 'latest' data to compare against, proceeding with write.")
  }

  # --- Step 4: Generate filename with timestamp and write to Parquet ---
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  filename <- paste0("responses_", timestamp, ".parquet")
  filepath_timestamped <- file.path(OUTPUT_DIR, filename)

  message(paste("Writing timestamped data to", filepath_timestamped))
  write_parquet(df_new, filepath_timestamped)
  message(paste("Successfully dumped data to", filepath_timestamped))

  # --- Step 5: Write to 'responses_latest.parquet' ---
  message(paste("Updating latest data to", LATEST_FILEPATH))
  write_parquet(df_new, LATEST_FILEPATH)
  message(paste("Successfully updated", LATEST_FILEPATH))

}, error = function(e) {
  # --- Error handling: Exit with status 1 ---
  exit_script(paste("Error dumping data:", e$message), 1)
}, finally = {
  # --- Disconnect from the database ---
  if (exists("con") && dbIsValid(con)) {
    message("Disconnecting from PostgreSQL.")
    dbDisconnect(con)
  }
})
