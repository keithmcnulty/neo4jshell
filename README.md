# neo4jshell
Efficient querying and server management for Neo4J in R using bolt and cypher-shell.

## Installation

```r
devtools::install_github("keithmcnulty/neo4jshell")
```

## Functionality

### Query

- `neo4j_query()` sends queries to the specified Neo4J graph database and, where appropriate, retrieves the results in a dataframe.

### Server management

- `neo4j_import()` imports a csv, zip or tar.gz file from a local sources into the specified import directory on the Neo4J server and uncompresses compressed files
- `neo4j_rmfiles()` removes specified files from specified Neo4J import directory
- `neo4j_rmdir()` removes entire specified subdirectories from specified Neo4J import directory

