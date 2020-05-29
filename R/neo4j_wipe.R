#' Wipe a complete local graph database in Neo4J
#'
#' @param database Name of local graph database object to wipe
#' @param data_path Path to the local Neo4J data directory
#'
#' @return Success or error message
#'
#' @examples
#' \dontrun{
#' # wipe movies database from local Neo4J Community 3.5.8 installation
#' DB_LOC <- path.expand("~/neo4j-community-3.5.8/data/")
#' neo4j_wipe(database = "movies", data_path = DB_LOC)
#' }

neo4j_wipe <- function(database = NULL, data_path = NULL) {
  if (substr(data_path, nchar(data_path), nchar(data_path)) != "/") {
    data_path <- paste0(data_path, "/")
  }

  if (!grepl(".db", database, ignore.case = T)) {
    database <- paste0(database, ".db")
  }

  fs::dir_delete(paste0(data_path, "databases/", database))
  message("Graph wiped successfully!")
}
