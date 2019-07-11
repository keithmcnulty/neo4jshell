#' Remove files from the Neo4J import directory
#'
#' @param con List containing three objects: address, uid, pwd as character strings providing connection to the Neo4J server
#' @param files Character vector of file names to be passed to the rm command on the Neo4J server
#' @param import_dir Character string of path to the import directory on the Neo4J server
#'
#' @return A success message if successful.  A text string if an error is encountered.
#'
#' @example neo4j_rmfiles with files = "*" will remove all files from the import directory


neo4j_rmfiles <- function (con = list(address = NULL, uid = NULL, pwd = NULL), files = NULL, import_dir = NULL) {

  if (substr(import_dir, nchar(import_dir), nchar(import_dir)) != "/") {
    import_dir <- paste0(import_dir, "/")
  }

  files <- paste0(import_dir, files)
  filestring <- paste(files, collapse = " ")
  tmp1 <- tempfile()

  ssh_uid <- paste0(con$uid, "@", basename(con$address))
  session <- ssh::ssh_connect(ssh_uid, passwd = con$pwd)
  output <- ssh::ssh_exec_wait(session, command = paste("rm", filestring), std_err = tmp1)
  ssh::ssh_disconnect(session)

  if (output == 0) {
    message("Files removed successfuly!")
  } else {
    readLines(tmp1) %>% paste(collapse = " ") %>% noquote() %>% warning(call. = FALSE)
  }

}
