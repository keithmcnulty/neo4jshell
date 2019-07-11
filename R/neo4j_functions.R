library(sys)
library(ssh)
library(magrittr)

#' Execute a query string in Neo4J using cypher-shell and capture output
#'
#' @param con list containing three objects: address, uid, pwd as character strings providing connection to the Neo4J server
#' @param qry character string of the query or queries to be sent to Neo4J.  Read queries should be single queries.
#' @param shell_path path to cypher-shell to be passed to the system command
#'
#' @return A dataframe of results if the read query is successful.  A text string if an error is encountered.
#' Embedded lists will have commas converted to semicolons.  Write queries will return a zero length response if successful.
#' If multiple read queries were submitted, only the results of the final query will be returned.

neo4j_query <- function(con = list(address = NULL, uid = NULL, pwd = NULL), qry = NULL,
                        shell_path = "cypher-shell") {

  qry <- gsub("\n", " ", qry)
  qry <- gsub("\t", "", qry)
  qry <- gsub("^\\s+|\\s+$", "", qry)

  # remove trailing ;

  if (substr(qry, nchar(qry), nchar(qry)) == ";") {
    qry <- substr(qry, 1, nchar(qry) - 1)
  }

  # split multiple queries into single queries inside a vector (command line cypher-shell only accepts one query at a time)

  if (grepl(";", qry)) {
    qry <- strsplit(qry, ";")
    qry <- as.vector(qry[[1]])
  } else {
    qry <- as.vector(qry)
  }

  # execute queries

  for (i in 1:length(qry)) {

    assign(paste0("args_", i),
           c("-a", con$address,
           "-u", con$uid,
           "-p", con$pwd,
           qry[i]) %>%
            noquote()
    )

    assign(paste0("tmp1_", i), tempfile())
    assign(paste0("tmp2_", i), tempfile())
  }

  for (i in 1:length(qry)) {
    assign(paste0("output_", i),
           sys::exec_wait(shell_path,
                          args = get(paste0("args_", i)),
                          std_out = get(paste0("tmp1_", i)),
                          std_err = get(paste0("tmp2_", i))
                          )
    )
  }

  # gather output statuses in vector

  if (length(qry)  == 1) {
    output <- get(paste0("output_", 1))
  } else {
    output <- get(paste0("output_", 1))
    for (k in 2:length(qry)) {
    output <- c(output, get(paste0("output_", i)))
    }
  }



  tmp_final <- tempfile()

  # if all queries successful, write results of final query or confirm zero-length response
  if (sum(output) == 0) {
      tmp <- readLines(get(paste0("tmp1_", length(qry))))
      if (length(tmp) > 0) {
      tmp <- gsub("(?:\\G(?!^)|\\[)[^][,]*\\K,(?=[^][]*])", ";", tmp, perl = TRUE) # deal with embedded [] lists for read.csv
      tmp <- gsub("(?:\\G(?!^)|\\{)[^{},]*\\K,(?=[^{}]*})", ";", tmp, perl = TRUE) # deal with embedded {} lists for read.csv
      write(tmp, tmp_final)
      read.csv(tmp_final)
      } else {
        message("Query succeeded with a zero length response from Neo4J")
      }
  } else {
    # if any error occurred, show all responses from Neo4J
    if (length(qry) == 1) {
      readLines(get("tmp2_1")) %>% paste(collapse = " ") %>% noquote() %>% stop(call. = FALSE)
    } else {
      tmpvec <- readLines(get("tmp2_1"))
      for (w in 2:length(qry)) {
        tmpvec <- c(tmpvec, readLines(get(paste0("tmp2_", w))))
      }
      tmpvec %>% paste(collapse = " ") %>% noquote() %>% stop(call. = FALSE)
    }


  }

}


#' Upload a csv or a compressed file to Neo4J import folder - accepts .csv, .zip and .tar.gz files
#'
#' @param con list containing three objects: address, uid, pwd as character strings providing connection to the Neo4J server
#' @param source character string of local path to the zip or tar.gz compressed csv file
#' @param import_dir character string of path to the import directory on the Neo4J server for ssh file transfer and unzipping
#' @param gunzip_path path to gunzip to be passed to the system command on the Neo4J server
#' @param tar_path path to tar to be passed to the system command on the Neo4J server
#' @param unzip_path path to unzip to be passed to the system command on the Neo4J server
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


#' Remove files from the Neo4J import directory
#'
#' @param con list containing three objects: address, uid, pwd as character strings providing connection to the Neo4J server
#' @param files character vector of file names to be passed to the rm command on the Neo4J server
#' @param import_dir character string of path to the import directory on the Neo4J server
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

#' Remove subdirectory and all its contents from the Neo4J import directory
#'
#' @param con list containing three objects: address, uid, pwd as character strings providing connection to the Neo4J server
#' @param dir character string of the import subdirectory name to be deleted on the Neo4J server
#' @param import_dir character string of path to the import directory on the Neo4J server
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

