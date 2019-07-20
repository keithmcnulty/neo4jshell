#' Remove subdirectory and all its contents from the Neo4J import directory
#'
#' @param con List containing three objects: bolt address, uid, pwd as character strings providing connection to the Neo4J server
#' @param dir Character string of the import subdirectory name to be deleted on the Neo4J server
#' @param import_dir Character string of path to the import directory on the Neo4J server
#'
#' @return A success message if successful.  A text string if an error is encountered.


neo4j_rmdir <- function (con = list(address = NULL, uid = NULL, pwd = NULL), dir = NULL, import_dir = NULL) {

  if (substr(import_dir, nchar(import_dir), nchar(import_dir)) != "/") {
    import_dir <- paste0(import_dir, "/")
  }

  filestring <- paste0(import_dir, dir)
  tmp1 <- tempfile()

  ssh_uid <- paste0(con$uid, "@", basename(con$address))
  session <- ssh::ssh_connect(ssh_uid, passwd = con$pwd)
  output <- ssh::ssh_exec_wait(session, command = paste("rm -r", filestring), std_err = tmp1)
  ssh::ssh_disconnect(session)

  if (output == 0) {
    message("Directory and all contents removed successfuly!")
  } else {
    readLines(tmp1) %>% paste(collapse = " ") %>% noquote() %>% warning(call. = FALSE)
  }

}

