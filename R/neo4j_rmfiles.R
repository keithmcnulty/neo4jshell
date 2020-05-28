#' Remove files from the Neo4J import directory
#'
#' @param local Logical indicating whether import is to a locally hosted or remotely hosted server.
#' @param con If remotely hosted server, list containing three objects: bolt address, uid, pwd as character strings providing connection to the Neo4J server.
#'   uid and pwd must be for an account on the server with appropriate permissions.
#' @param files Character vector of file names to be removed.
#' @param import_dir Character string of path to the Neo4J import directory.
#'
#' @return A success message if successful.  An error message otherwise.
#'
#' @examples
#' \dontrun{
#' # remove file from remote Neo4J import directory
#' con <- list(address = "bolt://bolt.my-neo4j-server.com", uid = "my_username", pwd = "my_password")
#' datafile <- "data.csv"
#' impdir <- "./import"
#' neo4j_rmfiles(con = con, files = datafile, import_dir = impdir)
#' }
#'
#' \dontrun{
#' # remove file from local Neo4J Community 3.5.8 import directory
#' con <- list(address = "bolt://localhost:7687", uid = "neo4j", pwd = "password")
#' datafile <- "data.csv"
#' impdir <- path.expand("~/neo4j-community-3.5.8/import/")
#' neo4j_rmfiles(local = T, con = con, files = datafile, import_dir = impdir)
#' }



neo4j_rmfiles <- function (local = F, con = list(address = NULL, uid = NULL, pwd = NULL), files = NULL, import_dir = "import") {

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
