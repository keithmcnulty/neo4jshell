#' Upload a csv or a compressed file to Neo4J import folder - accepts .csv, .zip and .tar.gz files
#'
#' @param con List containing three objects: bolt address, uid, pwd as character strings providing connection to the Neo4J server
#' @param source Character string of local path to the csv, zip or tar.gz compressed csv file
#' @param import_dir Character string of path to the import directory on the Neo4J server for ssh file transfer and unzipping
#' @param gunzip_path Path to gunzip to be passed to the system command on the Neo4J server
#' @param tar_path Path to tar to be passed to the system command on the Neo4J server
#' @param unzip_path Path to unzip to be passed to the system command on the Neo4J server
#'
#' @return System messages confirming success or error.


neo4j_import <- function (con = list(address = NULL, uid = NULL, pwd = NULL), source = NULL,
                          import_dir = NULL, unzip_path = "unzip",
                          gunzip_path = "gunzip", tar_path = "tar") {

  if (substr(import_dir, nchar(import_dir), nchar(import_dir)) != "/") {
    import_dir <- paste0(import_dir, "/")
  }


  ssh_uid <- paste0(con$uid, "@", basename(con$address))

  if (substr(source, nchar(source) - 3, nchar(source)) == ".csv") {
    session <- ssh::ssh_connect(ssh_uid, passwd = con$pwd)
    ssh::scp_upload(session, source, to = import_dir)
    ssh::ssh_disconnect(session)
  } else if (substr(source, nchar(source) - 3, nchar(source)) == ".zip") {
    session <- ssh::ssh_connect(ssh_uid, passwd = con$pwd)
    ssh::scp_upload(session, source, to = import_dir)
    ssh::ssh_exec_wait(session, paste(unzip_path, paste0(import_dir, basename(source)), "-d", import_dir))
    ssh::ssh_exec_wait(session, paste("rm", paste0(import_dir, basename(source))))
    ssh::ssh_disconnect(session)
  } else if (substr(source, nchar(source) - 6, nchar(source)) == ".tar.gz") {
    session <- ssh::ssh_connect(ssh_uid, passwd = con$pwd)
    ssh::scp_upload(session, source, to = import_dir)
    ssh::ssh_exec_wait(session, paste(gunzip_path, "-f", paste0(import_dir, basename(source))))
    ssh::ssh_exec_wait(session, paste(tar_path, "-C", import_dir, "-xvf", paste0(import_dir, gsub(".gz", "", basename(source)))))
    ssh::ssh_exec_wait(session, paste("rm", paste0(import_dir, gsub(".gz", "", basename(source)))))
    ssh::ssh_disconnect(session)
  } else {
    stop("Source is not a .csv, .zip or a .tar.gz file.")
  }
}

