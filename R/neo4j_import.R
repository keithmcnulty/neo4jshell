#' Upload a csv or a compressed file to Neo4J import folder - accepts .csv, .zip and .tar.gz files.  Leaves only uncompressed files behind.
#'
#' @param local Logical indicating whether import is to a locally hosted or a remotely hosted server.
#' @param con If remotely hosted server, list containing three objects: bolt address, uid, pwd as character strings providing connection to the Neo4J server
#' @param source Character string of local path to the csv, zip or tar.gz compressed csv file to be imported
#' @param import_dir Character string of full path to the Neo4J import directory
#' @param gunzip_path Path to gunzip on the local or remote server to be passed to the system command following import if necessary.
#' @param tar_path Path to tar on the local or remote server to be passed to the system command following import if necessary.
#' @param unzip_path Path to unzip on the local or remote server to be passed to the system command if necessary.
#'
#' @return System messages confirming success or error.


neo4j_import <- function (local = FALSE, con = list(address = NULL, uid = NULL, pwd = NULL), source = NULL,
                          import_dir = NULL, unzip_path = "unzip",
                          gunzip_path = "gunzip", tar_path = "tar") {


  if (substr(import_dir, nchar(import_dir), nchar(import_dir)) != "/") {
    import_dir <- paste0(import_dir, "/")
  }

  tmp1 <- tempfile()
  tmp2 <- tempfile()
  tmp3 <- tempfile()
  tmp4 <- tempfile()

  if (!local) {

    ssh_uid <- paste0(con$uid, "@", basename(con$address))

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
        args <- c(source, import_dir)
        output <- sys::exec_wait("cp", args = args, std_err = tmp1)
        if (output == 0) {
          message("Import successful!")
        } else {
          readLines(tmp1) %>% paste(collapse = " ") %>% noquote() %>% stop(call. = FALSE)
        }
      } else if (substr(source, nchar(source) - 3, nchar(source)) == ".zip") {
        args <- c(source, import_dir)
        output1 <- sys::exec_wait("cp", args = args, std_err = tmp1)
        args <- c("-o", paste0(import_dir, basename(source)), "-d", import_dir)
        output2 <- sys::exec_wait(unzip_path, args, std_err = tmp2)
        args <- c(paste0(import_dir, basename(source)))
        output3 <- sys::exec_wait("rm", args = args, std_err = tmp3)
        if (output1 == 0 & output2 == 0 & output3 == 0) {
          message("Import and unzip successful!  Zip file has been removed!")
        } else {
          c(readLines(tmp1), readLines(tmp2), readLines(tmp3)) %>% paste(collapse = " ") %>% noquote() %>% stop(call. = FALSE)
        }
      } else if (substr(source, nchar(source) - 6, nchar(source)) == ".tar.gz") {
        args <- c(source, import_dir)
        output1 <- sys::exec_wait("cp", args = args, std_err = tmp1)
        args <- c("-f", paste0(import_dir, basename(source)))
        output2 <- sys::exec_wait(gunzip_path, args = args, std_err = tmp2)
        args <- c("-C", import_dir, "-xvf", paste0(import_dir, gsub(".gz", "", basename(source))))
        output3 <- sys::exec_wait(tar_path, args = args, std_err = tmp3)
        args <- c(paste0(import_dir, gsub(".gz", "", basename(source))))
        output4 <- sys::exec_wait("rm", args = args, std_err = tmp4)
        if (output1 == 0 & output2 == 0 & output3 == 0 & output4 == 0) {
          message("Import and gunzip successful!  Tar file has been removed!")
        } else {
          c(readLines(tmp1), readLines(tmp2), readLines(tmp3), readLines(tmp4)) %>% paste(collapse = " ") %>% noquote() %>% stop(call. = FALSE)
        }
      } else {
        stop("Source is not a .csv, .zip or a .tar.gz file.")
      }

    }
}

