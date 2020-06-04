#' Wipe a complete local graph database in Neo4J
#'
#' @param database Name of local graph database directory to wipe.
#' @param data_path Path to the local Neo4J data directory
#'
#' @return Success or error message
#'
#' @examples
#' # wipe database directory
#' fs::dir_create("data/databases/foo")
#' neo4j_wipe(database = "foo", data_path = "data")
#' fs::dir_delete("data")

neo4j_wipe <- function(database = NULL, data_path = NULL) {
  if (substr(data_path, nchar(data_path), nchar(data_path)) != "/") {
    data_path <- paste0(data_path, "/")
  }

  fs::dir_delete(paste0(data_path, "databases/", database))
  message("Graph wiped successfully!")
}
