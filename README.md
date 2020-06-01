
<!-- README.md is generated from README.Rmd. Please edit that file -->

# neo4jshell

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R build
status](https://github.com/keithmcnulty/neo4jshell/workflows/R-CMD-check/badge.svg)](https://github.com/keithmcnulty/neo4jshell/actions)
[![Travis build
status](https://travis-ci.com/keithmcnulty/neo4jshell.svg?branch=master)](https://travis-ci.com/keithmcnulty/neo4jshell)
<!-- badges: end -->

The goal of neo4jshell is to provide rapid querying of ‘Neo4J’ graph
databases by offering a programmatic interface with ‘cypher-shell’. A
wide variety of other functions are offered that allow importing and
management of data files for local and remote servers, as well as simple
administration of local servers for development purposes.

## Pre-installation notes

This package requires the `ssh` package for interacting with remote
‘Neo4J’ databases, which requires `libssh` to be installed. See the
vignettes for the `ssh` package
[here](https://CRAN.R-project.org/package=ssh) for more details.

This package also requires the ‘cypher-shell’ executable to be available
**locally**. This is installed as standard in ‘Neo4J’ installations and
can usually be found in the `bin` directory of that installation. It can
also be installed standalone using Homebrew or is available here:
<https://github.com/neo4j/cypher-shell>.

It is recommended, for ease of use, that the path to the ‘cypher-shell’
executable is added to your `PATH` environment variable. If not, you
should record its location for use in some of the functions within this
package.

## Installation

You can install the released version of neo4jshell from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("neo4jshell")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("keithmcnulty/neo4jshell")
```

## Functionality

### Query

`neo4j_query()` sends queries to the specified ‘Neo4J’ graph database
and, where appropriate, retrieves the results in a dataframe.

In this example, the movies dataset has been started locally in the
‘Neo4J’ browser, with a user created that has the credentials
indicated. `cypher-shell` is in the local system path.

``` r
library(neo4jshell)
library(dplyr)
library(tibble)
```

``` r
# set credentials (no port required in bolt address)
neo_movies <- list(address = "bolt://localhost", uid = "neo4j", pwd = "password")

# find directors of movies with Kevin Bacon as actor
CQL <- 'MATCH (p1:Person {name: "Kevin Bacon"})-[:ACTED_IN]->(m:Movie)<-[:DIRECTED]-(p2:Person)
RETURN p2.name, m.title;'

# run query
neo4j_query(con = neo_movies, qry = CQL)
#>      p2.name        m.title
#> 1 Ron Howard    Frost/Nixon
#> 2 Rob Reiner A Few Good Men
#> 3 Ron Howard      Apollo 13
```

Older versions of ‘Neo4J’ and ‘cypher-shell’ (\<4.0) will require the
`encryption` argument to be explicitly `'true'` or `'false'`. For newer
versions, which have multi-tenancy, you can use the `database` argument
to specify the database to query.

### Server management

  - `neo4j_import()` imports a csv, zip or tar.gz file from a local
    source into the specified ‘Neo4J’ import directory, uncompresses
    compressed files and removes the original compressed file as clean
    up.
  - `neo4j_rmfiles()` removes specified files from specified ‘Neo4J’
    import directory
  - `neo4j_rmdir()` removes entire specified subdirectories from
    specified ‘Neo4J’ import directory

### Remote development

In this general example, we can see how these functions can be used for
smooth ETL to a remote ‘Neo4J’ server. This example assumes that the URL
of the server that hosts the ‘Neo4J’ database is the same as the bolt
URL for the ‘Neo4J’ database. If not, a different set of credentials
will be needed for using `neo4j_import()`.

    # credentials (note no port required in server address)
    neo_server <- list(address = "bolt://neo.server.address", uid = "neo4j", pwd = "password")
    
    # csv data file to be loaded onto 'Neo4J' server (path relative to current working directory)
    datafile <- "data.csv"
    
    # CQL query to write data from datafile to 'Neo4J'
    loadcsv_CQL <- "LOAD CSV FROM 'file:///data.csv' etc etc;"
    
    # path to import directory on remote 'Neo4J' server (should be relative to user home directory on remote server)
    impdir <- "./import"
    
    # import data
    neo4jshell::neo4j_import(con = neo_server, source = datafile, import_dir = impdir)
    
    # write data to 'Neo4J' (assumes cypher-shell is in system PATH variable)
    neo4jshell:neo4j_query(con = neo_server, qry = loadcsv_CQL)
    
    # remove data file as clean-up
    neo4jshell::neo4j_rmfiles(con = neo_server, files = datafile, import_dir = impdir)

In Windows, the ‘cypher-shell’ executable may need to be specified with
the file extension, for example `shell_path = "cypher-shell.bat"`.

### Local Development

If you are working with the ‘Neo4J’ server locally, below will help you
get started.

First, the code below is relative to user and is using ‘Neo4J 4.0.4
Community’ installed at my user’s root. The directory containing the
‘cypher-shell’ and ‘neo4j’ executables are in my system’s PATH
environment variables.

``` r
## setup connection credentials and import directory location
neo_con <- list(address = "bolt://localhost:7687", uid = "neo4j", pwd = "password")
import_loc <- path.expand("~/neo4j-community-4.0.4/import/")
```

First we save `mtcars` to a `.csv` file, and we compress that file. This
package supports a number of delivery formats, but we use a `.zip` file
as an example.

``` r
mtcars <- mtcars %>% 
  tibble::rownames_to_column(var = "model")

write.csv(mtcars, "mtcars.csv", row.names = FALSE)
zip("mtcars.zip", "mtcars.csv")
```

Now we use `neo4j_import()` to place a **copy** of this file within the
import directory you defined in `import_loc` above.

``` r
neo4j_import(local = TRUE, graph, source = "mtcars.zip", import_dir = import_loc)
#> Import and unzip successful!  Zip file has been removed!
```

We now write a CQL query to write some information from `mtcars.csv` to
the graph, and execute that query.

``` r
CQL <- "LOAD CSV WITH HEADERS FROM 'file:///mtcars.csv' AS row
WITH row WHERE row.model IS NOT NULL
MERGE (c:Car {name: row.model});"

neo4j_query(neo_con, CQL)
#> Query succeeded with a zero length response from Neo4J
```

Now, let’s remove the `mtcars.csv` file from the import directory of our
local server as cleanup. If you want to use a sub-directory to help
manage your files during an ETL into ‘Neo4J’, you can remove that local
sub-directory when your process has completed using `neo4j_rmdir()`.

``` r
## remove the file
neo4j_rmfiles(local = TRUE, graph, files="mtcars.csv", import_dir = import_loc)
#> Files removed successfully!
```

Now let’s run a query to check the data was loaded to the graph.

``` r
CQL <- "MATCH (c:Car) RETURN c.name as name LIMIT 5;"

neo4j_query(neo_con, CQL)
#>                name
#> 1         Mazda RX4
#> 2     Mazda RX4 Wag
#> 3        Datsun 710
#> 4    Hornet 4 Drive
#> 5 Hornet Sportabout
```

### Local server administration and control

  - `neo4j_start()` starts a local ‘Neo4J’ instance
  - `neo4j_stop()` stops a local ‘Neo4J’ instance
  - `neo4j_restart()` restarts a local ‘Neo4J’ instance
  - `neo4j_status()` returns the status of a local ‘Neo4J’ instance
  - `neo4j_wipe()` wipes an entire graph from a local ‘Neo4J’ instance

For example:

``` r

# my server was already running, confirm
neo4j_status()
#> Neo4j is running at pid 1771
#> [1] 0

# stop the server
neo4j_stop()
#> Stopping Neo4j....... stopped
#> [1] 0

# restart
neo4j_start()
#> Directories in use:
#>   home:         /Users/keithmcnulty/neo4j-community-4.0.4
#>   config:       /Users/keithmcnulty/neo4j-community-4.0.4/conf
#>   logs:         /Users/keithmcnulty/neo4j-community-4.0.4/logs
#>   plugins:      /Users/keithmcnulty/neo4j-community-4.0.4/plugins
#>   import:       /Users/keithmcnulty/neo4j-community-4.0.4/import
#>   data:         /Users/keithmcnulty/neo4j-community-4.0.4/data
#>   certificates: /Users/keithmcnulty/neo4j-community-4.0.4/certificates
#>   run:          /Users/keithmcnulty/neo4j-community-4.0.4/run
#> Starting Neo4j.
#> Started neo4j (pid 1924). It is available at http://localhost:7474/
#> There may be a short delay until the server is ready.
#> See /Users/keithmcnulty/neo4j-community-4.0.4/logs/neo4j.log for current status.
#> [1] 0

# give it a few seconds to fire up
Sys.sleep(10)

# query again
neo4j_query(neo_con, qry="MATCH (c:Car) RETURN c.name as name LIMIT 5;")
#>                name
#> 1         Mazda RX4
#> 2     Mazda RX4 Wag
#> 3        Datsun 710
#> 4    Hornet 4 Drive
#> 5 Hornet Sportabout
```

If you are using an admin account and you are using ‘Neo4J 4+’ you can
check what databases are available by querying the system database.

``` r
neo4j_query(neo_con, qry="SHOW DATABASES;", database = "system")
#>     name        address       role requestedStatus currentStatus error default
#> 1  neo4j localhost:7687 standalone          online        online  <NA>    TRUE
#> 2 system localhost:7687 standalone          online        online  <NA>   FALSE
```
