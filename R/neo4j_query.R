#' Execute a query string in Neo4J using cypher-shell and capture output
#'
#' @param con List containing three objects: bolt address, uid, pwd as character strings providing connection to the Neo4J server
#' @param qry Character string of the query or queries to be sent to Neo4J.  Read queries should be single queries.
#' @param shell_path If cypher-shell is not in the PATH system variable, the full local path to cypher-shell executable.
#' @param database The name of the database if other than the default database.  (For multi-tenancy installations).
#' @param encryption Passes encryption argument to cypher-shell if necessary.  Older versions of cypher-shell may require 'true' or 'false' to be passed.
#'
#' @return A dataframe of results if the read query is successful.  A text string if an error is encountered.
#' Write queries will return a zero length response if successful.
#' If multiple read queries were submitted, only the results of the final query will be returned.
#'
#' @examples
#' # if neo4j exists, start the local server, give it a moment to fire up, and run a query
#' if (nzchar(Sys.which("neo4j"))) {
#'   neo4j_start()
#'   Sys.sleep(2)
#'   graph <- list(address = "bolt://localhost:7687", uid = "neo4j", pwd = "password")
#'   neo4j_query(con = graph, qry = "MATCH (n) RETURN (n)")
#' }



neo4j_query <- function(con = list(address = NULL, uid = NULL, pwd = NULL), qry = NULL,
                        shell_path = "cypher-shell", database = NULL, encryption = c("default", "true", "false")) {

  encryption <- match.arg(encryption)

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
      if (!is.null(database)) {
        assign(paste0("args_", i),
               c("-a", con$address,
                 "-u", con$uid,
                 "-p", con$pwd,
                 "-d", database,
                 "--encryption", encryption,
                 qry[i]) %>%
                 noquote()
        )
      } else {
        assign(paste0("args_", i),
               c("-a", con$address,
                 "-u", con$uid,
                 "-p", con$pwd,
                 "--encryption", encryption,
                 qry[i]) %>%
                 noquote()
        )
     }

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
      tmp <- gsub("(?:\\G(?!^)|\\[)[^][,]*\\K,(?=[^][]*])", ";;;", tmp, perl = TRUE) # deal with embedded [] lists for read.csv
      tmp <- gsub("(?:\\G(?!^)|\\{)[^{},]*\\K,(?=[^{}]*})", ";;;", tmp, perl = TRUE) # deal with embedded {} lists for read.csv
      write(tmp, tmp_final)
      r <- read.csv(tmp_final, colClasses = "character", strip.white = TRUE)
      r <- lapply(r, function (x) gsub(";;;", ",", x))
      as.data.frame(r, stringsAsFactors = FALSE)
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
