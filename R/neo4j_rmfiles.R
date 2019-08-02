#' Remove files from the Neo4J import directory
#'
#' @param local Logical indicating whether import is to a locally hosted or remotely hosted server.
#' @param con If remotely hosted server, list containing three objects: bolt address, uid, pwd as character strings providing connection to the Neo4J server
#' @param files Character vector of file names to be removed.
#' @param import_dir Character string of path to the Neo4J import directory.
#'
#' @return A success message if successful.  An error message otherwise.



neo4j_rmfiles <- function (local = FALSE, con = list(address = NULL, uid = NULL, pwd = NULL), files = NULL, import_dir = NULL) {

  if (substr(import_dir, nchar(import_dir), nchar(import_dir)) != "/") {
    import_dir <- paste0(import_dir, "/")
  }

  files <- paste0(import_dir, files)
  filestring <- paste(files, collapse = " ")
  tmp1 <- tempfile()

  if (!local) {

    base_address <- basename(con$address)
    if (grepl(":", base_address)) {
      base_address <- gsub(":(.*)", "", base_address)
    }

    ssh_uid <- paste0(con$uid, "@", base_address)
    session <- ssh::ssh_connect(ssh_uid, passwd = con$pwd)
    output <- ssh::ssh_exec_wait(session, command = paste("rm", filestring), std_err = tmp1)
    ssh::ssh_disconnect(session)

  } else {

    if (.Platform$OS.type == "windows") {
      args <- c(files, "/Q")
      output <- sys::exec_wait("del", args = args, std_err = tmp1)
    } else {
      args <- files
      output <- sys::exec_wait("rm", args = args, std_err = tmp1)
    }
  }

  if (output == 0) {
    message("Files removed successfuly!")
  } else {
    readLines(tmp1) %>% paste(collapse = " ") %>% noquote() %>% stop(call. = FALSE)
  }

}
