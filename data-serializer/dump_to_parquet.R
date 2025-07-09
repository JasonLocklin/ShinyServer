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

OUTPUT_DIR <- "/app/data_dumps"

tryCatch({
  # Connect to PostgreSQL
  con <- dbConnect(RPostgres::Postgres(),
                   host = DB_HOST,
                   port = DB_PORT,
                   dbname = DB_DBNAME,
                   user = DB_USER,
                   password = DB_PASSWORD)

  # Read data from PostgreSQL table
  query <- paste0("SELECT * FROM ", DB_TABLE)
  df <- dbReadTable(con, DB_TABLE) # More robust than dbGetQuery for full table dump

  # Generate filename with timestamp
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  filename <- paste0("responses_", timestamp, ".parquet")
  filepath <- file.path(OUTPUT_DIR, filename)

  # Write DataFrame to Parquet file
  write_parquet(df, filepath)
  message(paste("Successfully dumped data to", filepath))

}, error = function(e) {
  message(paste("Error dumping data:", e$message))
}, finally = {
  # Disconnect from the database
  if (exists("con") && dbIsValid(con)) {
    dbDisconnect(con)
  }
})
