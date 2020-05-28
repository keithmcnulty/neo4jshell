#' Check status of a local Neo4J database
#'
#' @param neo4j_path Path to the Neo4J executable (usually in the bin directory of the Neo4J installation)
#'
#' @return System messages
#'
#' @examples
#' \donttest{
#' # Check status local graph with neo4j executable in the system PATH variable
#' neo4j_status()
#' }

neo4j_status <- function(neo4j_path = "neo4j") {
  sys::exec_background(neo4j_path, "status")
}
