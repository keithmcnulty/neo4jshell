#' Start a local Neo4J database
#'
#' @param neo4j_path Path to the Neo4J executable (usually in the bin directory of the Neo4J installation)
#'
#' @return System messages


neo4j_start <- function(neo4j_path = "neo4j") {
  sys::exec_background(neo4j_path, "start")
}
