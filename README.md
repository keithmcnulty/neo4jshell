# neo4jshell
Efficient querying and server management for Neo4J in R using bolt and cypher-shell.  Requires cypher-shell to be available for querying.

## Installation

```r
devtools::install_github("keithmcnulty/neo4jshell")
```

## Functionality

### Query

- `neo4j_query()` sends queries to the specified Neo4J graph database and, where appropriate, retrieves the results in a dataframe.

In this example, the movies dataset has been started locally in the Neo4J browser, with a user created that has the credentials indicated.   cypher-shell is in the local system path. 
```
# set credentials
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

### Server management (designed for working with remote Neo4J servers)

- `neo4j_import()` imports a csv, zip or tar.gz file from a local sources into the specified import directory on the Neo4J server and uncompresses compressed files
- `neo4j_rmfiles()` removes specified files from specified Neo4J import directory
- `neo4j_rmdir()` removes entire specified subdirectories from specified Neo4J import directory

