# Neo4j Football Data Graph Database Project

## Overview
This project implements a Neo4j graph database to analyze football match data from 14 European leagues during the 2022-2023 season. The database contains 98,751 records of player performances across multiple competitions.

## Project Structure

### Documentation Files
- **Graph_Design.md**: Comprehensive graph schema design with detailed node and relationship specifications
- **Graph_Schema_Diagram.txt**: Visual ASCII representation of the graph structure
- **Design_Summary.md**: Summary of design decisions and query support analysis
- **README.md**: This file

### Cypher Scripts
- **CreateFootballGraph.cy**: Script to create the graph database schema, load data from CSV, and establish all relationships
- **Queries.cy**: All 7 required queries implemented in Cypher

## Graph Schema

### Node Types
1. **Game**: Football matches with properties (gameId, gameDate, homeGoals, awayGoals, winner)
2. **Team**: Football teams with property (name)
3. **Player**: Players with properties (playerId, name, position, birthDate)
4. **Competition**: Leagues/competitions with property (name)
5. **Country**: Countries with property (name)

### Relationship Types
1. **HOME_TEAM**: Game → Team (which team played at home)
2. **AWAY_TEAM**: Game → Team (which team played away)
3. **PLAYED_IN**: Player → Game (player participation with performance stats)
4. **PART_OF**: Game → Competition (which competition the game belongs to)
5. **IN_COUNTRY**: Competition → Country (which country hosts the competition)
6. **TEAMMATES**: Player ↔ Player (players who played together, with gamesTogether count)

## Setup Instructions

### Prerequisites
- Neo4j Desktop or Neo4j Server installed
- Access to Neo4j Browser or Neo4j Cypher Shell
- CSV file `FootBallData.csv` accessible to Neo4j

### Step 1: Prepare the CSV File
1. Place `FootBallData.csv` in Neo4j's import directory:
   - **Neo4j Desktop**: Usually `C:\Users\<username>\.Neo4jDesktop\neo4jDatabases\database-<id>\installation-<version>\import\`
   - **Neo4j Server**: Usually `<neo4j-home>/import/`

### Step 2: Create the Graph
1. Open Neo4j Browser or Cypher Shell
2. Copy and execute the contents of `CreateFootballGraph.cy`
3. **Note**: Update the file path in the LOAD CSV statements if your CSV is in a different location
4. Wait for the script to complete (this may take several minutes for 98K+ records)

### Step 3: Run Queries
1. Open `Queries.cy`
2. Update the competition and team names in queries 4-7 to match your preferences
3. Execute each query individually in Neo4j Browser

## Query Descriptions

### Query 1: List all competitions in Greece
Returns all competition names that take place in Greece.

### Query 2: List all teams in Greek competitions
Returns all unique team names that participated in Greek competitions.

### Query 3: Greek teams vs foreign teams
Lists Greek teams that played against foreign teams, showing the Greek team, foreign team, and foreign competition name.

### Query 4: Top scorer per team
For each team in your favorite competition, returns the top scorer's name and total goals.

### Query 5: Top 10 toughest defenders
Returns the 10 defenders with the most cards (yellow + red) in your favorite competition.

### Query 6: Best attacking duo
Finds the two attackers who played together most frequently for a specific team.

### Query 7: Most connected players
Identifies the 3 players who played with the most different teammates for a specific team.

## Customization

Before running queries 4-7, update these values in `Queries.cy`:
- **Competition name**: Replace `'superligaen'` with your favorite competition
- **Team name**: Replace `'FC Midtjylland'` with your favorite team

## Performance Notes

- The graph creation script may take 10-30 minutes depending on your system
- Indexes are created automatically for optimal query performance
- The TEAMMATES relationship creation is the most time-consuming step

## Troubleshooting

### CSV Loading Issues
- Ensure the CSV file path is correct in the LOAD CSV statements
- Check that the CSV file uses semicolon (`;`) as the field terminator
- Verify Neo4j has read permissions for the CSV file

### Memory Issues
- If you encounter memory errors, process the data in smaller batches
- Consider increasing Neo4j's heap memory settings

### Query Performance
- Ensure indexes are created (they should be created automatically)
- For large result sets, consider adding LIMIT clauses during development

## Data Validation

After creating the graph, you can verify the data using these queries:

```cypher
// Count nodes by type
MATCH (n)
RETURN labels(n) AS nodeType, COUNT(n) AS count
ORDER BY nodeType;

// Count relationships by type
MATCH ()-[r]->()
RETURN type(r) AS relationshipType, COUNT(r) AS count
ORDER BY relationshipType;

// Sample games
MATCH (g:Game)-[:HOME_TEAM]->(ht:Team), (g)-[:AWAY_TEAM]->(at:Team)
RETURN g.gameId, g.gameDate, ht.name AS homeTeam, at.name AS awayTeam
LIMIT 5;
```

## Design Rationale

This schema design:
- **Normalizes data** to avoid duplication
- **Optimizes queries** with direct relationships
- **Pre-computes connections** (TEAMMATES) for fast analysis
- **Supports all required queries** efficiently
- **Scales well** for large datasets

## Next Steps

1. Review the graph design documentation
2. Execute `CreateFootballGraph.cy` to build the database
3. Run queries from `Queries.cy` to analyze the data
4. Customize queries for your specific analysis needs

## Support

For issues or questions:
- Check Neo4j documentation: https://neo4j.com/docs/
- Review Cypher query language reference: https://neo4j.com/docs/cypher-manual/

