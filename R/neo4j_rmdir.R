#' Remove subdirectory and all its contents from the Neo4J import directory
#'
#' @param local Logical indicating whether import is to a locally hosted or remotely hosted server.
#' @param con If remotely hosted server, list containing three objects: bolt address, uid, pwd as character strings providing connection to the Neo4J server.
#'   uid and pwd must be for an account on the server with appropriate permissions.
#' @param dir Character string of the Neo4J import subdirectory name to be deleted.
#' @param import_dir Character string of path to the Neo4J import directory.
#'
#' @return A success message if successful.  A error message otherwise.
#'
#' @examples
#' \dontrun{
#' # remove a subdirectory and all its contents from the remote Neo4J import directory
#' con <- list(address = "bolt://bolt.my-neo4j-server.com", uid = "my_username", pwd = "my_password")
#' my_dir <- "my_data"
#' impdir <-"./import"
#' neo4j_rmdir(con = con, dir = my_dir, import_dir = impdir)
#' }
#'
#' \dontrun{
#' # remove a subdirectory and all its contents from the local Neo4J Community 3.5.8 import directory
#' con <- list(address = "bolt://localhost:7687", uid = "neo4j", pwd = "password")
#' my_dir <- "my_data"
#' impdir <- path.expand("~/neo4j-community-3.5.8/import/")
#' neo4j_rmdir(local = T, con = con, dir = my_dir, import_dir = impdir)
#' }



neo4j_rmdir <- function (local = F, con = list(address = NULL, uid = NULL, pwd = NULL), dir = NULL, import_dir = "import") {

  if (substr(import_dir, nchar(import_dir), nchar(import_dir)) != "/") {
    import_dir <- paste0(import_dir, "/")
  }

  filestring <- paste0(import_dir, dir)
  tmp1 <- tempfile()

  if (!local) {

    base_address <- basename(con$address)
    if (grepl(":", base_address)) {
      base_address <- gsub(":(.*)", "", base_address)
    }

    ssh_uid <- paste0(con$uid, "@", base_address)
    session <- ssh::ssh_connect(ssh_uid, passwd = con$pwd)
    output <- ssh::ssh_exec_wait(session, command = paste("rm -r", filestring), std_err = tmp1)
    ssh::ssh_disconnect(session)

    if (output == 0) {
      message("Directory and all contents removed successfully!")
    } else {
      readLines(tmp1) %>% paste(collapse = " ") %>% noquote() %>% stop(call. = FALSE)
    }

  } else {

    fs::dir_delete(filestring)
    message("Directory and all contents removed successfully!")

  }



}

