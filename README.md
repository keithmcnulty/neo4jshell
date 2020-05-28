<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R build status](https://github.com/keithmcnulty/neo4jshell/workflows/R-CMD-check/badge.svg)](https://github.com/keithmcnulty/neo4jshell/actions)
[![Travis build status](https://travis-ci.com/keithmcnulty/neo4jshell.svg?branch=master)](https://travis-ci.com/keithmcnulty/neo4jshell)
<!-- badges: end -->

# neo4jshell
Efficient querying and server management for 'Neo4J' in R using bolt and cypher-shell.  

## Pre-installation notes
This package requires uses the `ssh` package which requires `libssh` to be installed.  See the vignettes for the `ssh` package [here](https://CRAN.R-project.org/package=ssh) for more details.

This package also requires the `cypher-shell` executable to be available **locally**.  This is installed as standard in 'Neo4J' installations and can usually be found in the `bin` directory of that installation.  It can also be installed standalone using Homebrew or is available here:  https://github.com/neo4j/cypher-shell.

It is recommended, for ease of use, that the path to the `cypher-shell` executable is added to your `PATH` environment variable.  If not, you should record its location for use in some of the functions within this package.

## Installation

```r
devtools::install_github("keithmcnulty/neo4jshell")
```

## Functionality

### Query

- `neo4j_query()` sends queries to the specified 'Neo4J' graph database and, where appropriate, retrieves the results in a dataframe.

In this example, the movies dataset has been started locally in the 'Neo4J' browser, with a user created that has the credentials indicated.   `cypher-shell` is in the local system path. 
```
# set credentials (no port required in bolt address)
neo_movies <- list(address = "bolt://localhost", uid = "neo4juser", pwd = "neo4juser")

# find directors of movies with Kevin Bacon as actor
CQL <- 'MATCH (p1:Person {name: "Kevin Bacon"})-[:ACTED_IN]->(m:Movie)<-[:DIRECTED]-(p2:Person)
RETURN p2.name, m.title'

# run query
neo4jshell::neo4j_query(con = neo_movies, qry = CQL)



     p2.name         m.title
1 Ron Howard     Frost/Nixon
2 Rob Reiner  A Few Good Men
3 Ron Howard       Apollo 13

```

### Server management

- `neo4j_import()` imports a csv, zip or tar.gz file from a local source into the specified 'Neo4J' import directory, uncompresses compressed files and removes the original compressed file as clean up.
- `neo4j_rmfiles()` removes specified files from specified 'Neo4J' import directory
- `neo4j_rmdir()` removes entire specified subdirectories from specified 'Neo4J' import directory

### Remote development

In this general example, we can see how these functions can be used for smooth ETL to a remote 'Neo4J' server.  

```
# credentials (note no port required in server address)
neo_server <- list(address = "bolt://neo.server.address", uid = "neo4j", pwd = "password")

# csv data file to be loaded onto 'Neo4J' server (path relative to current working directory)
datafile <- "data.csv"

# CQL query to write data from datafile to 'Neo4J'
loadcsv_CQL <- "LOAD CSV FROM 'file:///data.csv' etc etc"

# path to import directory on remote 'Neo4J' server (should be relative to user home directory on remote server)
impdir <- "./import"

# import data
neo4jshell::neo4j_import(con = neo_server, source = datafile, import_dir = impdir)

# write data to 'Neo4J' (assumes cypher-shell is in system PATH variable)
neo4jshell:neo4j_query(con = neo_server, qry = loadcsv_CQL)

# remove data file as clean-up
neo4jshell::neo4j_rmfiles(con = neo_server, files = datafile, import_dir = impdir)


```

### Local Development

If you are working with the 'Neo4J' server locally, below will help you get started.  

First, the code below is relative to user and is using 'Neo4J 3.5.8 Community' installed at my user's root.

```
## graph setup
graph = list(address = "bolt://localhost:7687", uid = "neo4j", pwd = "password")
SHELL_LOC = path.expand("~/neo4j-community-3.5.8/bin/cypher-shell")
IMPORT_LOC = path.expand("~/neo4j-community-3.5.8/import/")
```

- `graph` = the connection information
- `SHELL_LOC` = the full path to the `cypher-shell` ulility.  
- `IMPORT_LOC` = for the same server, the `import` directory, fully specified

Below, we will create a simple datafame and save that dataset to a csv file.

```
df = data.frame(id = 1:10, 
                b = letters[1:10], 
                stringsAsFactors=FALSE)
write.csv(df, "test-df.csv")
```

This package supports a number of delivery formats, but for simplicity sake, a `csv` file is created above.

Below, we will confirm the location of the file in our __current__ working directory, and then use `neo4j_import` to place a **copy** of this file within the import directory you defined in `IMPORT_LOC` above.  

```
# test that the file was saved to the current working directory
# list.files(pattern = "test")
# [1] "test-df.csv"
neo4j_import(local = TRUE, graph, source="test-df.csv", import_dir = IMPORT_LOC)
```

Now, let's remove that file from the import directory of our local server

```
## remove the file
neo4j_rmfiles(local = TRUE, graph, files="test-df.csv", import_dir = IMPORT_LOC)
```

Lastly, if you want to use a subdiretory to help manage your files during an ETL into 'Neo4J', you can remove that local subdirectory when your process has completed.

Below walks through the steps to confirm this feature.

```
## create a test subdirectory
fs::dir_create(paste0(IMPORT_LOC, "test-dr"))

## what exists?
fs::dir_ls(IMPORT_LOC)

## remove the directory
neo4j_rmdir(local = TRUE, graph, dir = "test-dr", import_dir = IMPORT_LOC)

## confirm
fs::dir_ls(IMPORT_LOC)
```

### Local server administration and control

- `neo4j_start()` starts a local 'Neo4J' instance
- `neo4j_stop()` stops a local 'Neo4J' instance
- `neo4j_restart()` restarts a local 'Neo4J' instance
- `neo4j_status()` returns the status of a local 'Neo4J' instance
- `neo4j_wipe()` wipes an entire graph from a local 'Neo4J' instance


For Example:

```
options(stringsAsFactors = FALSE)

# load the package
library(neo4jshell)

# setup relative to your server - for me, this is local
graph = list(address = "bolt://localhost:7687", uid = "neo4j", pwd = "password")
SHELL_LOC = path.expand("~/neo4j-community-3.5.8/bin/cypher-shell")
IMPORT_LOC = path.expand("~/neo4j-community-3.5.8/import/")
SERVER_LOC = path.expand("~/neo4j-community-3.5.8/bin/neo4j")
DB_LOC = path.expand("~/neo4j-community-3.5.8/data/")

# my server was already running, confirm
neo4j_status(neo4j_path = SERVER_LOC)

# stop the server
neo4j_stop(SERVER_LOC)

# restart to confirm that flow
neo4j_start(SERVER_LOC)

# I had a test node, that was returned
neo4j_query(graph, qry="MATCH (n) RETURN count(n) as total", shell_path = SHELL_LOC)

# stop the server and wipe the database
# useful for rapid protoyping
neo4j_stop(SERVER_LOC)
neo4j_wipe(database = "graph.db", data_path = DB_LOC)

# fire up the server
neo4j_start(SERVER_LOC)

# confirm that there are no data - a clean database server!
neo4j_query(graph, qry="MATCH (n) RETURN count(n) as total", shell_path = SHELL_LOC)
```
