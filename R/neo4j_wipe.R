#' Wipe a complete graph database in Neo4J
#'
#' @param graph Name of graph db object to wiped
#' @param data_path Path to the Neo4J data directory
#'
#' @return Success or error message

neo4j_wipe <- function(graph = NULL, data_path = NULL) {
  if (substr(data_path, nchar(data_path), nchar(data_path)) != "/") {
    data_path <- paste0(data_path, "/")
  }

  tmp <- tempfile()

  if (.Platform$OS.type == "windows") {
    args <- c("/S", "/Q", paste0(data_path, "/databases/", graph))
    output <- sys::exec_wait("rd", args, std_err = tmp)
  } else {
    args = c("-r", paste0(data_path, "/databases/", graph))
    output <- sys::exec_wait("rm", args, std_err = tmp)
  }

  if (output == 0) {
    message("Graph wiped successfully!")
  } else {
    readLines(tmp) %>% paste(collapse = " ") %>% noquote() %>% stop(call. = FALSE)
  }
}
