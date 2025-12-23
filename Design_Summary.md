# Graph Database Design Summary

## Overview
This graph schema is designed to efficiently support all 7 required queries for the football data analysis project.

## Key Design Decisions

### 1. **Separate Node Types for Each Entity**
- **Game**: Stores match-level information (date, scores, winner)
- **Team**: Stores team names (reusable across games)
- **Player**: Stores player information (name, position, birth date)
- **Competition**: Stores league/competition names
- **Country**: Stores country names

**Rationale**: Normalized structure prevents data duplication and enables efficient queries.

### 2. **PLAYED_IN Relationship with Performance Data**
The `PLAYED_IN` relationship stores player performance metrics (goals, assists, cards, minutes) as relationship properties rather than node properties.

**Rationale**: 
- A player's performance varies per game
- Allows aggregation across multiple games
- The `teamName` property tracks which team the player represented in each specific game

### 3. **TEAMMATES Relationship**
A dedicated relationship between players who played together, with a `gamesTogether` counter.

**Rationale**:
- Pre-computes player connections for fast queries
- Supports queries 6 and 7 directly
- Avoids repeated calculations during query time

### 4. **Game-to-Team Relationships**
Separate `HOME_TEAM` and `AWAY_TEAM` relationships from Game to Team.

**Rationale**:
- Clear distinction between home and away teams
- Supports queries about team matchups
- Enables easy filtering by team role

## Query Support Analysis

### Query 1-3: Competition/Country/Team Information
**Supported by:**
- `Competition` → `IN_COUNTRY` → `Country` relationships
- `Game` → `PART_OF` → `Competition` relationships
- `Game` → `HOME_TEAM`/`AWAY_TEAM` → `Team` relationships

**Example Query Pattern:**
```cypher
MATCH (c:Competition)-[:IN_COUNTRY]->(co:Country)
WHERE co.name = 'Greece'
RETURN c.name, co.name
```

### Query 4: Top Scorer per Team
**Supported by:**
- `Player` → `PLAYED_IN` → `Game` relationships
- `PLAYED_IN.teamName` property to filter by team
- `PLAYED_IN.goals` property for aggregation

**Example Query Pattern:**
```cypher
MATCH (p:Player)-[pi:PLAYED_IN]->(g:Game)
WHERE pi.teamName = 'Team Name'
WITH p, SUM(pi.goals) as totalGoals
ORDER BY totalGoals DESC
LIMIT 1
RETURN p.name, totalGoals
```

### Query 5: Toughest Defenders (Most Cards)
**Supported by:**
- `Player.position` property to filter defenders
- `PLAYED_IN.yellowCards` and `PLAYED_IN.redCards` for aggregation

**Example Query Pattern:**
```cypher
MATCH (p:Player)-[pi:PLAYED_IN]->(g:Game)
WHERE p.position = 'Defender'
WITH p, SUM(pi.yellowCards + pi.redCards) as totalCards
ORDER BY totalCards DESC
LIMIT 10
RETURN p.name, totalCards
```

### Query 6: Best Attacking Duo
**Supported by:**
- `TEAMMATES` relationship between players
- `Player.position` to filter attackers
- `TEAMMATES.gamesTogether` to find most frequent pairs

**Example Query Pattern:**
```cypher
MATCH (p1:Player)-[t:TEAMMATES]-(p2:Player)
WHERE p1.position = 'Attack' AND p2.position = 'Attack'
  AND p1.playerId < p2.playerId  // Avoid duplicates
WITH p1, p2, t.gamesTogether as games
ORDER BY games DESC
LIMIT 1
RETURN p1.name, p2.name, games
```

### Query 7: Most Connected Players
**Supported by:**
- `TEAMMATES` relationship degree (number of connections)
- Direct count of TEAMMATES relationships per player

**Example Query Pattern:**
```cypher
MATCH (p:Player)-[t:TEAMMATES]-()
WITH p, COUNT(DISTINCT t) as teammateCount
ORDER BY teammateCount DESC
LIMIT 3
RETURN p.name, teammateCount
```

## Data Loading Considerations

### Performance Optimization
1. **Batch Processing**: Load data in batches to avoid memory issues
2. **Constraint Creation**: Create constraints before loading data
3. **Index Creation**: Create indexes on frequently queried properties
4. **TEAMMATES Calculation**: Process after all PLAYED_IN relationships are created

### Data Integrity
- Use MERGE instead of CREATE to avoid duplicates
- Handle missing/null values appropriately
- Validate data types during loading

## Advantages of This Design

1. **Query Efficiency**: Direct relationships enable fast traversals
2. **Scalability**: Schema handles large datasets efficiently
3. **Flexibility**: Easy to extend with additional relationships or properties
4. **Clarity**: Clear separation of concerns (games, players, teams)
5. **Maintainability**: Well-structured schema is easy to understand and modify

## Potential Extensions

Future enhancements could include:
- **TRANSFERRED_TO** relationship between Player and Team (for player transfers)
- **COACHES** relationship between Coach nodes and Team nodes
- **VENUE** nodes for stadiums
- **SEASON** nodes for temporal organization
- **ASSISTED** relationship between players (who assisted whom)

