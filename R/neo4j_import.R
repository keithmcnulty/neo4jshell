#' Imports a csv or a compressed file to Neo4J import folder.
#'
#' @param local Logical indicating whether import is to a locally hosted or a remotely hosted server.
#' @param con If remotely hosted server, list containing three objects: address, uid, pwd as character strings providing connection to the Neo4J server.
#'   uid and pwd must be for an account on the server with appropriate permissions.
#' @param source Character string of local path to the csv, zip or tar.gz compressed csv file to be imported
#' @param import_dir Character string of full path to the Neo4J import directory
#' @param gunzip_path Path to gunzip on the local or remote server to be passed to the system command following import if necessary.
#' @param tar_path Path to tar on the local or remote server to be passed to the system command following import if necessary.
#' @param unzip_path Path to unzip on the local or remote server to be passed to the system command if necessary.
#'
#' @return System messages confirming success or error.  zip or tar files will be removed after import and decompression.
#'
#' @examples
#' # import zip to local import directory, with zip in the local system PATH variable
#' write.csv(mtcars, "mtcars.csv")
#' zip("mtcars.zip", "mtcars.csv")
#' fs::dir_create("import")
#' neo4j_import(local = TRUE, source = "mtcars.zip")
#' fs::file_delete("mtcars.zip")
#' fs::file_delete("mtcars.csv")
#' fs::dir_delete("import")



neo4j_import <- function (local = FALSE, con = list(address = NULL, uid = NULL, pwd = NULL), source = NULL,
                          import_dir = "import", unzip_path = "unzip",
                          gunzip_path = "gunzip", tar_path = "tar") {


  if (substr(import_dir, nchar(import_dir), nchar(import_dir)) != "/") {
    import_dir <- paste0(import_dir, "/")
  }

  tmp1 <- tempfile()
  tmp2 <- tempfile()
  tmp3 <- tempfile()
  tmp4 <- tempfile()

  if (local == FALSE) {

    base_address <- basename(con$address)
    if (grepl(":", base_address)) {
      base_address <- gsub(":(.*)", "", base_address)
    }

    ssh_uid <- paste0(con$uid, "@", base_address)

    if (substr(source, nchar(source) - 3, nchar(source)) == ".csv") {
      session <- ssh::ssh_connect(ssh_uid, passwd = con$pwd)
      ssh::scp_upload(session, source, to = import_dir)
      ssh::ssh_disconnect(session)
      message("Import successful!")
    } else if (substr(source, nchar(source) - 3, nchar(source)) == ".zip") {
      session <- ssh::ssh_connect(ssh_uid, passwd = con$pwd)
      ssh::scp_upload(session, source, to = import_dir)
      output1 <- ssh::ssh_exec_wait(session, paste(unzip_path, "-o", paste0(import_dir, basename(source)), "-d", import_dir), std_err = tmp1)
      output2 <- ssh::ssh_exec_wait(session, paste("rm", paste0(import_dir, basename(source))), std_err = tmp2)
      ssh::ssh_disconnect(session)
      if (output1 == 0 & output2 == 0) {
        message("Import and unzip successful!  Zip file has been removed!")
      } else {
        c(readLines(tmp1), readLines(tmp2)) %>% paste(collapse = " ") %>% noquote() %>% stop(call. = FALSE)
      }
    } else if (substr(source, nchar(source) - 6, nchar(source)) == ".tar.gz") {
      session <- ssh::ssh_connect(ssh_uid, passwd = con$pwd)
      ssh::scp_upload(session, source, to = import_dir)
      output1 <- ssh::ssh_exec_wait(session, paste(gunzip_path, "-f", paste0(import_dir, basename(source))), std_err = tmp1)
      output2 <- ssh::ssh_exec_wait(session, paste(tar_path, "-C", import_dir, "-xvf", paste0(import_dir, gsub(".gz", "", basename(source)))), std_err = tmp2)
      output3 <- ssh::ssh_exec_wait(session, paste("rm", paste0(import_dir, gsub(".gz", "", basename(source)))), std_err = tmp3)
      ssh::ssh_disconnect(session)
      if (output1 == 0 & output2 == 0 & output3 == 0) {
        message("Import and gunzip successful!  Tar file has been removed!")
      } else {
        c(readLines(tmp1), readLines(tmp2), readLines(tmp3)) %>% paste(collapse = " ") %>% noquote() %>% stop(call. = FALSE)
      }
    } else {
      stop("Source is not a .csv, .zip or a .tar.gz file.")
    }

  } else {

    if (substr(source, nchar(source) - 3, nchar(source)) == ".csv") {
      new <- paste0(import_dir, basename(source))
      fs::file_copy(source, new, overwrite = TRUE)
      message("Import successful!")
    } else if (substr(source, nchar(source) - 3, nchar(source)) == ".zip") {
      new <- paste0(import_dir, basename(source))
      fs::file_copy(source, new, overwrite = TRUE)
      unzip(new, exdir = import_dir, unzip = unzip_path)
      fs::file_delete(new)
      message("Import and unzip successful!  Zip file has been removed!")
    } else if (substr(source, nchar(source) - 6, nchar(source)) == ".tar.gz") {
      new <- paste0(import_dir, basename(source))
      fs::file_copy(source, new, overwrite = TRUE)
      R.utils::gunzip(new)
      untar(gsub(".gz", "", new), exdir = import_dir, tar = tar_path)
      fs::file_delete(gsub(".gz", "", new))
      message("Import and gunzip successful!  Tar file has been removed!")
    } else {
      stop("Source is not a .csv, .zip or a .tar.gz file.")
    }

  }
}

