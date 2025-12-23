// NOTE: The following script syntax is valid for database version 5.0 and above.

:param {
  // Define the file path root and the individual file names required for loading.
  // https://neo4j.com/docs/operations-manual/current/configuration/file-locations/
  file_path_root: 'file:///', // Change this to the folder your script can access the files at.
  file_0: 'FootBallData.csv'
};

// CONSTRAINT creation
// -------------------
//
// Create node uniqueness constraints, ensuring no duplicates for the given node label and ID property exist in the database. This also ensures no duplicates are introduced in future.
//
CREATE CONSTRAINT `GameID_Game_uniq` IF NOT EXISTS
FOR (n: `Game`)
REQUIRE (n.`GameID`) IS UNIQUE;
CREATE CONSTRAINT `CompetitionName_Competition_uniq` IF NOT EXISTS
FOR (n: `Competition`)
REQUIRE (n.`CompetitionName`) IS UNIQUE;
CREATE CONSTRAINT `PlayerID_Player_uniq` IF NOT EXISTS
FOR (n: `Player`)
REQUIRE (n.`PlayerID`) IS UNIQUE;
CREATE CONSTRAINT `PlayerTeamName_Team_uniq` IF NOT EXISTS
FOR (n: `Team`)
REQUIRE (n.`PlayerTeamName`) IS UNIQUE;
CREATE CONSTRAINT `Country_Country_uniq` IF NOT EXISTS
FOR (n: `Country`)
REQUIRE (n.`Country`) IS UNIQUE;

:param {
  idsToSkip: []
};

// NODE load
// ---------
//
// Load nodes in batches, one node label at a time. Nodes will be created using a MERGE statement to ensure a node with the same label and ID property remains unique. Pre-existing nodes found by a MERGE statement will have their other properties set to the latest values encountered in a load file.
//
// NOTE: Any nodes with IDs in the 'idsToSkip' list parameter will not be loaded.
LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row
WHERE NOT row.`GameID` IN $idsToSkip AND NOT toInteger(trim(row.`GameID`)) IS NULL
CALL (row) {
  MERGE (n: `Game` { `GameID`: toInteger(trim(row.`GameID`)) })
  SET n.`GameID` = toInteger(trim(row.`GameID`))
  // Your script contains the datetime datatype. Our app attempts to convert dates to ISO 8601 date format before passing them to the Cypher function.
  // This conversion cannot be done in a Cypher script load. Please ensure that your CSV file columns are in ISO 8601 date format to ensure equivalent loads.
  SET n.`GameDate` = datetime(row.`GameDate`)
  SET n.`HomeTeamName` = row.`HomeTeamName`
  SET n.`AwayTeamName` = row.`AwayTeamName`
  SET n.`HomeGoals` = toInteger(trim(row.`HomeGoals`))
  SET n.`AwayGoals` = toInteger(trim(row.`AwayGoals`))
  SET n.`Winner` = toInteger(trim(row.`Winner`))
  SET n.`CompetitionName` = row.`CompetitionName`
  SET n.`Country` = row.`Country`
  SET n.`PlayerID` = toInteger(trim(row.`PlayerID`))
  SET n.`MinutesPlayed` = toInteger(trim(row.`MinutesPlayed`))
  SET n.`Goals` = toInteger(trim(row.`Goals`))
  SET n.`Assists` = toLower(trim(row.`Assists`)) IN ['1','true','yes']
  SET n.`YellowCards` = toInteger(trim(row.`YellowCards`))
  SET n.`RedCards` = toLower(trim(row.`RedCards`)) IN ['1','true','yes']
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row
WHERE NOT row.`CompetitionName` IN $idsToSkip AND NOT row.`CompetitionName` IS NULL
CALL (row) {
  MERGE (n: `Competition` { `CompetitionName`: row.`CompetitionName` })
  SET n.`CompetitionName` = row.`CompetitionName`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row
WHERE NOT row.`PlayerID` IN $idsToSkip AND NOT toInteger(trim(row.`PlayerID`)) IS NULL
CALL (row) {
  MERGE (n: `Player` { `PlayerID`: toInteger(trim(row.`PlayerID`)) })
  SET n.`PlayerID` = toInteger(trim(row.`PlayerID`))
  SET n.`PlayerName` = row.`PlayerName`
  SET n.`Position` = row.`Position`
  // Your script contains the datetime datatype. Our app attempts to convert dates to ISO 8601 date format before passing them to the Cypher function.
  // This conversion cannot be done in a Cypher script load. Please ensure that your CSV file columns are in ISO 8601 date format to ensure equivalent loads.
  SET n.`BirthDate` = datetime(row.`BirthDate`)
  SET n.`PlayerTeamName` = row.`PlayerTeamName`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row
WHERE NOT row.`PlayerTeamName` IN $idsToSkip AND NOT row.`PlayerTeamName` IS NULL
CALL (row) {
  MERGE (n: `Team` { `PlayerTeamName`: row.`PlayerTeamName` })
  SET n.`PlayerTeamName` = row.`PlayerTeamName`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row
WHERE NOT row.`Country` IN $idsToSkip AND NOT row.`Country` IS NULL
CALL (row) {
  MERGE (n: `Country` { `Country`: row.`Country` })
  SET n.`Country` = row.`Country`
} IN TRANSACTIONS OF 10000 ROWS;


// RELATIONSHIP load
// -----------------
//
// Load relationships in batches, one relationship type at a time. Relationships are created using a MERGE statement, meaning only one relationship of a given type will ever be created between a pair of nodes.
LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row 
CALL (row) {
  MATCH (source: `Game` { `GameID`: toInteger(trim(row.`GameID`)) })
  MATCH (target: `Competition` { `CompetitionName`: row.`CompetitionName` })
  MERGE (source)-[r: `Part of`]->(target)
  SET r.`Country` = row.`Country`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row 
CALL (row) {
  MATCH (source: `Player` { `PlayerID`: toInteger(trim(row.`PlayerID`)) })
  MATCH (target: `Game` { `GameID`: toInteger(trim(row.`GameID`)) })
  MERGE (source)-[r: `Played In`]->(target)
  SET r.`Position` = row.`Position`
  SET r.`PlayerTeamName` = row.`PlayerTeamName`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row 
CALL (row) {
  MATCH (source: `Team` { `PlayerTeamName`: row.`PlayerTeamName` })
  MATCH (target: `Game` { `GameID`: toInteger(trim(row.`GameID`)) })
  MERGE (source)-[r: `Played In`]->(target)
  SET r.`HomeTeamName` = row.`HomeTeamName`
  SET r.`AwayTeamName` = row.`AwayTeamName`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row 
CALL (row) {
  MATCH (source: `Player` { `PlayerID`: toInteger(trim(row.`PlayerID`)) })
  MATCH (target: `Team` { `PlayerTeamName`: row.`PlayerTeamName` })
  MERGE (source)-[r: `Belongs To`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row 
CALL (row) {
  MATCH (source: `Player` { `PlayerID`: toInteger(trim(row.`PlayerID`)) })
  MATCH (target: `Player` { `PlayerID`: toInteger(trim(row.`PlayerTeamName`)) })
  MERGE (source)-[r: `Teamates`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row 
CALL (row) {
  MATCH (source: `Competition` { `CompetitionName`: row.`CompetitionName` })
  MATCH (target: `Country` { `Country`: row.`Country` })
  MERGE (source)-[r: `In Country`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row 
CALL (row) {
  MATCH (source: `Team` { `PlayerTeamName`: row.`PlayerTeamName` })
  MATCH (target: `Country` { `Country`: row.`Country` })
  MERGE (source)-[r: `In Country`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;
