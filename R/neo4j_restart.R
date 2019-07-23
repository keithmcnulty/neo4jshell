#' Restart a local Neo4J database
#'
#' @param neo4j_path Path to the Neo4J executable (usually in the bin directory of the Neo4J installation)
#'
#' @return System messages
#'
#' @examples
#' neo4j_restart(neo4j_path = path.expand("~/neo4j-community-3.5.8/bin/neo4j"))

neo4j_restart <- function(neo4j_path = "neo4j") {
  sys::exec_background(neo4j_path, "restart")
}
