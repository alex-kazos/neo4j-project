# Neo4j Graph Database Design for Football Data

## Overview
This document describes the graph database schema designed to support the football match data analysis project. The schema is optimized to answer all required queries efficiently.

## Node Types

### 1. **Game** Node
Represents a football match/game.

**Properties:**
- `gameId` (Integer, unique) - Unique identifier for the game
- `gameDate` (Date) - Date when the game was played
- `homeGoals` (Integer) - Goals scored by home team
- `awayGoals` (Integer) - Goals scored by away team
- `winner` (Integer) - Winner code (0=Draw, 1=Home, 2=Away)

**Constraints:**
- Unique constraint on `gameId`

### 2. **Team** Node
Represents a football team.

**Properties:**
- `name` (String, unique) - Team name

**Constraints:**
- Unique constraint on `name`

### 3. **Player** Node
Represents a football player.

**Properties:**
- `playerId` (Integer, unique) - Unique identifier for the player
- `name` (String) - Player's name
- `position` (String) - Player position (Goalkeeper, Defender, Midfield, Attack)
- `birthDate` (Date) - Player's date of birth

**Constraints:**
- Unique constraint on `playerId`

### 4. **Competition** Node
Represents a football league/competition.

**Properties:**
- `name` (String, unique) - Competition name

**Constraints:**
- Unique constraint on `name`

### 5. **Country** Node
Represents a country where competitions are held.

**Properties:**
- `name` (String, unique) - Country name

**Constraints:**
- Unique constraint on `name`

## Relationship Types

### 1. **HOME_TEAM** (Game → Team)
Indicates which team played at home in a game.

**Properties:**
- None

**Cardinality:**
- One Game has exactly one HOME_TEAM relationship

### 2. **AWAY_TEAM** (Game → Team)
Indicates which team played away in a game.

**Properties:**
- None

**Cardinality:**
- One Game has exactly one AWAY_TEAM relationship

### 3. **PLAYED_IN** (Player → Game)
Represents a player's participation in a game.

**Properties:**
- `teamName` (String) - The team the player played for in this game
- `minutesPlayed` (Integer) - Minutes the player played
- `goals` (Integer) - Goals scored by the player
- `assists` (Integer) - Assists made by the player
- `yellowCards` (Integer) - Yellow cards received
- `redCards` (Integer) - Red cards received

**Cardinality:**
- Multiple players can play in one game
- One player can play in multiple games

### 4. **PART_OF** (Game → Competition)
Indicates which competition a game belongs to.

**Properties:**
- None

**Cardinality:**
- One Game belongs to exactly one Competition

### 5. **IN_COUNTRY** (Competition → Country)
Indicates which country a competition is held in.

**Properties:**
- None

**Cardinality:**
- One Competition is in exactly one Country

### 6. **TEAMMATES** (Player → Player)
Represents players who have played together in the same team in the same game.

**Properties:**
- `gamesTogether` (Integer) - Number of games where both players played together

**Cardinality:**
- Undirected relationship (can be traversed both ways)
- Multiple relationships between the same pair of players are merged, with `gamesTogether` incremented

**Note:** This relationship is created by identifying players who:
- Played in the same game (same GameID)
- Played for the same team (same PlayerTeamName in that game)

## Graph Schema Diagram

```
┌─────────────┐
│   Country   │
│  (name)     │
└──────┬──────┘
       │ IN_COUNTRY
       │
┌──────▼──────────┐
│  Competition    │
│    (name)       │
└──────┬──────────┘
       │ PART_OF
       │
┌──────▼──────┐
│    Game     │
│ (gameId,    │
│  gameDate,  │
│  homeGoals, │
│  awayGoals, │
│  winner)    │
└──┬──────┬───┘
   │      │
   │      │
   │ HOME_TEAM    │ AWAY_TEAM
   │              │
┌──▼──────┐   ┌──▼──────┐
│  Team   │   │  Team   │
│ (name)  │   │ (name)  │
└─────────┘   └─────────┘
       │              │
       │              │
       └──────┬───────┘
              │
       ┌──────▼──────┐
       │   Player    │
       │ (playerId,  │
       │  name,      │
       │  position,  │
       │  birthDate) │
       └──────┬──────┘
              │
              │ PLAYED_IN
              │ (teamName, minutesPlayed,
              │  goals, assists,
              │  yellowCards, redCards)
              │
       ┌──────▼──────┐
       │    Game    │
       └────────────┘

       ┌─────────────┐
       │   Player    │◄───┐
       └──────┬──────┘    │
              │           │
              │ TEAMMATES │
              │ (gamesTogether) │
              │           │
       ┌──────▼───────────┘
       │   Player    │
       └─────────────┘
```

## Design Rationale

### Why This Schema?

1. **Normalized Structure**: Each entity type (Game, Team, Player, Competition, Country) is represented as a distinct node type, avoiding data duplication.

2. **Efficient Querying**: 
   - Direct relationships between entities allow fast traversal
   - TEAMMATES relationship pre-computes player connections for quick analysis
   - Team relationships (HOME_TEAM, AWAY_TEAM) enable easy game-to-team queries

3. **Query Support**:
   - **Query 1-3**: Supported by Competition → Country, Team relationships
   - **Query 4**: Top scorers per team - easily queried via PLAYED_IN relationships with teamName property
   - **Query 5**: Toughest defenders - filtered by position and aggregated cards via PLAYED_IN
   - **Query 6**: Attacking duos - uses TEAMMATES relationship filtered by position
   - **Query 7**: Most connected players - uses TEAMMATES relationship degree

4. **Performance Considerations**:
   - Unique constraints on IDs ensure fast lookups
   - TEAMMATES relationship aggregates game counts, avoiding repeated calculations
   - Indexes on key properties (gameId, playerId, team names) for fast access

5. **Data Integrity**:
   - Unique constraints prevent duplicate nodes
   - Relationships maintain referential integrity
   - Properties stored at appropriate levels (game-level vs player-game-level)

## Data Loading Strategy

1. **Phase 1**: Create unique nodes
   - Create all unique Team nodes
   - Create all unique Player nodes
   - Create all unique Competition nodes
   - Create all unique Country nodes

2. **Phase 2**: Create Game nodes and basic relationships
   - For each unique GameID, create a Game node
   - Create HOME_TEAM and AWAY_TEAM relationships
   - Create PART_OF relationship to Competition
   - Create IN_COUNTRY relationship

3. **Phase 3**: Create PLAYED_IN relationships
   - For each CSV row, create PLAYED_IN relationship from Player to Game
   - Store player performance data as relationship properties

4. **Phase 4**: Create TEAMMATES relationships
   - For each game, identify all players who played for the same team
   - Create or update TEAMMATES relationships between all pairs
   - Increment gamesTogether counter

## Indexes and Constraints

```cypher
// Unique constraints
CREATE CONSTRAINT game_id_unique FOR (g:Game) REQUIRE g.gameId IS UNIQUE;
CREATE CONSTRAINT player_id_unique FOR (p:Player) REQUIRE p.playerId IS UNIQUE;
CREATE CONSTRAINT team_name_unique FOR (t:Team) REQUIRE t.name IS UNIQUE;
CREATE CONSTRAINT competition_name_unique FOR (c:Competition) REQUIRE c.name IS UNIQUE;
CREATE CONSTRAINT country_name_unique FOR (co:Country) REQUIRE co.name IS UNIQUE;

// Indexes for performance
CREATE INDEX game_date_index FOR (g:Game) ON (g.gameDate);
CREATE INDEX player_position_index FOR (p:Player) ON (p.position);
CREATE INDEX player_name_index FOR (p:Player) ON (p.name);
```

## Notes

- The `teamName` property in PLAYED_IN relationship is necessary because players may change teams, and we need to know which team they played for in each specific game.
- TEAMMATES relationships are bidirectional in nature but stored as directed relationships in Neo4j. Queries should consider both directions or use undirected pattern matching.
- The schema supports temporal queries (by gameDate) and aggregations (goals, cards, etc.) efficiently.

