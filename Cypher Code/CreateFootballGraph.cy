// ============================================================================
// STEP 1: Create Constraints and Indexes
// ============================================================================

// Create unique constraints (ensures data integrity)
CREATE CONSTRAINT game_id_unique FOR (g:Game) REQUIRE g.gameId IS UNIQUE;
CREATE CONSTRAINT player_id_unique FOR (p:Player) REQUIRE p.playerId IS UNIQUE;
CREATE CONSTRAINT team_name_unique FOR (t:Team) REQUIRE t.name IS UNIQUE;
CREATE CONSTRAINT competition_name_unique FOR (c:Competition) REQUIRE c.name IS UNIQUE;
CREATE CONSTRAINT country_name_unique FOR (co:Country) REQUIRE co.name IS UNIQUE;

// Create indexes for performance optimization
CREATE INDEX game_date_index IF NOT EXISTS FOR (g:Game) ON (g.gameDate);
CREATE INDEX player_position_index IF NOT EXISTS FOR (p:Player) ON (p.position);
CREATE INDEX player_name_index IF NOT EXISTS FOR (p:Player) ON (p.name);



// ============================================================================
// STEP 2: Load Data from CSV and Create Nodes
// ============================================================================

// 2.1: Create unique Country nodes
LOAD CSV WITH HEADERS FROM 'file:///FootBallData.csv' AS row
FIELDTERMINATOR ';'
WITH DISTINCT row.Country AS countryName
WHERE countryName IS NOT NULL AND countryName <> ''
MERGE (co:Country {name: countryName});


// 2.2: Create unique Competition nodes and link to Country
LOAD CSV WITH HEADERS FROM 'file:///FootBallData.csv' AS row
FIELDTERMINATOR ';'
WITH DISTINCT row.CompetitionName AS compName, row.Country AS countryName
WHERE compName IS NOT NULL AND compName <> '' 
  AND countryName IS NOT NULL AND countryName <> ''
MERGE (c:Competition {name: compName})
WITH c, countryName
MATCH (co:Country {name: countryName})
MERGE (c)-[:IN_COUNTRY]->(co);


// 2.3: Create unique Team nodes (from PlayerTeamName column)

LOAD CSV WITH HEADERS FROM 'file:///FootBallData.csv' AS row
FIELDTERMINATOR ';'
WITH DISTINCT row.PlayerTeamName AS teamName
WHERE teamName IS NOT NULL AND teamName <> ''
MERGE (t:Team {name: teamName});


// 2.4: Create unique Player nodes
LOAD CSV WITH HEADERS FROM 'file:///FootBallData.csv' AS row
FIELDTERMINATOR ';'
WITH row
WHERE row.PlayerID IS NOT NULL
  AND row.PlayerName IS NOT NULL AND row.PlayerName <> ''
  AND row.BirthDate IS NOT NULL AND row.BirthDate <> ''

WITH DISTINCT
  toInteger(row.PlayerID) AS playerId,
  row.PlayerName AS playerName,
  row.Position AS position,
  date(row.BirthDate) AS birthDate

MERGE (p:Player {
  playerId: playerId,
  name: playerName,
  position: position,
  birthDate: birthDate
});


// 2.5: Create Game nodes with basic properties
LOAD CSV WITH HEADERS FROM 'file:///FootBallData.csv' AS row
FIELDTERMINATOR ';'
WITH row
WHERE row.GameID IS NOT NULL
  AND row.GameDate IS NOT NULL AND row.GameDate <> ''

WITH DISTINCT
  toInteger(row.GameID) AS gameId,
  date(row.GameDate) AS gameDate,
  toInteger(row.HomeGoals) AS homeGoals,
  toInteger(row.AwayGoals) AS awayGoals,
  toInteger(Winner) AS winner

MERGE (g:Game {gameId: gameId})
SET
  g.gameDate = gameDate,
  g.homeGoals = homeGoals,
  g.awayGoals = awayGoals,
  g.winner = winner;


// 2.6: Create relationships: Game -> Team (HOME_TEAM and AWAY_TEAM) --
LOAD CSV WITH HEADERS FROM 'file:///FootBallData.csv' AS row
FIELDTERMINATOR ';'
WITH DISTINCT 
  toInteger(row.GameID) AS gameId,
  row.HomeTeamName AS homeTeamName,
  row.AwayTeamName AS awayTeamName
WHERE gameId IS NOT NULL 
AND homeTeamName IS NOT NULL AND homeTeamName <> ''
AND awayTeamName IS NOT NULL AND awayTeamName <> ''
MATCH (g:Game {gameId: gameId})
MATCH (ht:Team {name: homeTeamName})
MATCH (at:Team {name: awayTeamName})
MERGE (g)-[:HOME_TEAM]->(ht)
MERGE (g)-[:AWAY_TEAM]->(at);


// 2.7: Create relationship: Game -> Competition (PART_OF) --
LOAD CSV WITH HEADERS FROM 'file:///FootBallData.csv' AS row
FIELDTERMINATOR ';'
WITH DISTINCT 
    toInteger(row.GameID) AS gameId,
    row.CompetitionName AS compName
WHERE gameId IS NOT NULL 
  AND compName IS NOT NULL AND compName <> ''
MATCH (g:Game {gameId: gameId})
MATCH (c:Competition {name: compName})
MERGE (g)-[:PART_OF]->(c);



// ============================================================================
// STEP 3: Create PLAYED_IN Relationships (Player -> Game with performance data)
// ============================================================================

LOAD CSV WITH HEADERS FROM 'file:///FootBallData.csv' AS row
FIELDTERMINATOR ';'
WITH 
    toInteger(row.PlayerID) AS playerId,
    toInteger(row.GameID) AS gameId,
    row.PlayerTeamName AS teamName,
    toInteger(COALESCE(row.MinutesPlayed, '0')) AS minutesPlayed,
    toInteger(COALESCE(row.Goals, '0')) AS goals,
    toInteger(COALESCE(row.Assists, '0')) AS assists,
    toInteger(COALESCE(row.YellowCards, '0')) AS yellowCards,
    toInteger(COALESCE(row.RedCards, '0')) AS redCards
WHERE playerId IS NOT NULL 
  AND gameId IS NOT NULL
  AND teamName IS NOT NULL AND teamName <> ''
MATCH (p:Player {playerId: playerId})
MATCH (g:Game {gameId: gameId})
MERGE (p)-[pi:PLAYED_IN {
    teamName: teamName,
    minutesPlayed: minutesPlayed,
    goals: goals,
    assists: assists,
    yellowCards: yellowCards,
    redCards: redCards
}]->(g);



// ============================================================================
// STEP 4: Create TEAMMATES Relationships (Player -> Player)
// ============================================================================

// For each game, find all players who played for the same team
// and create TEAMMATES relationships with gamesTogether count
MATCH (g:Game)
MATCH (p1:Player)-[pi1:PLAYED_IN]->(g)
MATCH (p2:Player)-[pi2:PLAYED_IN]->(g)
WHERE p1.playerId < p2.playerId 
  AND pi1.teamName = pi2.teamName
WITH p1, p2, COUNT(DISTINCT g) AS gamesTogether
MERGE (p1)-[tm:TEAMMATES]-(p2)
SET tm.gamesTogether = gamesTogether;

