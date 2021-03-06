% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/neo4j_import.R
\name{neo4j_import}
\alias{neo4j_import}
\title{Imports a csv or a compressed file to Neo4J import folder.}
\usage{
neo4j_import(
  local = FALSE,
  con = list(address = NULL, uid = NULL, pwd = NULL),
  source = NULL,
  import_dir = "import",
  unzip_path = "unzip",
  gunzip_path = "gunzip",
  tar_path = "tar"
)
}
\arguments{
\item{local}{Logical indicating whether import is to a locally hosted or a remotely hosted server.}

\item{con}{If remotely hosted server, list containing three objects: address, uid, pwd as character strings providing connection to the Neo4J server.
uid and pwd must be for an account on the server with appropriate permissions.}

\item{source}{Character string of local path to the csv, zip or tar.gz compressed csv file to be imported}

\item{import_dir}{Character string of full path to the Neo4J import directory}

\item{unzip_path}{Path to unzip on the local or remote server to be passed to the system command if necessary.}

\item{gunzip_path}{Path to gunzip on the local or remote server to be passed to the system command following import if necessary.}

\item{tar_path}{Path to tar on the local or remote server to be passed to the system command following import if necessary.}
}
\value{
System messages confirming success or error.  zip or tar files will be removed after import and decompression.
}
\description{
Imports a csv or a compressed file to Neo4J import folder.
}
\examples{
# import zip to local import directory, with zip in the local system PATH variable
write.csv(mtcars, "mtcars.csv")
zip("mtcars.zip", "mtcars.csv")
fs::dir_create("import")
neo4j_import(local = TRUE, source = "mtcars.zip")
fs::file_delete("mtcars.zip")
fs::file_delete("mtcars.csv")
fs::dir_delete("import")
}
