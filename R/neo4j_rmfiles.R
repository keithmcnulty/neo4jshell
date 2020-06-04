#' Remove files from the Neo4J import directory
#'
#' @param local Logical indicating whether import is to a locally hosted or remotely hosted server.
#' @param con If remotely hosted server, list containing three objects: address, uid, pwd as character strings providing connection to the Neo4J server.
#'   uid and pwd must be for an account on the server with appropriate permissions.
#' @param files Character vector of file names to be removed.
#' @param import_dir Character string of path to the Neo4J import directory.
#'
#' @return A success message if successful.  An error message otherwise.
#'
#' @examples
#' # remove file from local import directory
#' fs::dir_create("import")
#' fs::file_create("import/data.csv")
#' neo4j_rmfiles(local = TRUE, files = "data.csv", import_dir = "import")
#' fs::dir_delete("import")



neo4j_rmfiles <- function (local = FALSE, con = list(address = NULL, uid = NULL, pwd = NULL), files = NULL, import_dir = "import") {

  if (substr(import_dir, nchar(import_dir), nchar(import_dir)) != "/") {
    import_dir <- paste0(import_dir, "/")
  }

  files <- paste0(import_dir, files)
  filestring <- paste(files, collapse = " ")
  tmp1 <- tempfile()

  if (local == FALSE) {

    base_address <- basename(con$address)
    if (grepl(":", base_address)) {
      base_address <- gsub(":(.*)", "", base_address)
    }

    ssh_uid <- paste0(con$uid, "@", base_address)
    session <- ssh::ssh_connect(ssh_uid, passwd = con$pwd)
    output <- ssh::ssh_exec_wait(session, command = paste("rm", filestring), std_err = tmp1)
    ssh::ssh_disconnect(session)

    if (output == 0) {
      message("Files removed successfully!")
    } else {
      readLines(tmp1) %>% paste(collapse = " ") %>% noquote() %>% stop(call. = FALSE)
    }

  } else {

    fs::file_delete(files)
    message("Files removed successfully!")

  }

}
