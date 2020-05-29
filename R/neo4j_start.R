#' Start a local Neo4J database
#'
#' @param neo4j_path Path to the Neo4J executable (usually in the bin directory of the Neo4J installation)
#'
#' @return System messages
#'
#' @examples
#' \dontrun{
#' # start local graph on with neo4j executable in the system PATH variable
#' neo4j_start()
#' }


neo4j_start <- function(neo4j_path = "neo4j") {
  sys::exec_wait(neo4j_path, "start")
}
