// ============================================================================
// Queries.cy
// Neo4j Cypher Queries for Football Data Analysis
// ============================================================================

// ============================================================================
// QUERY 1: List all competitions in Greece
// ============================================================================

MATCH (c:Competition)-[:IN_COUNTRY]->(co:Country)
WHERE co.name = 'Greece'
RETURN c.name AS competitionName, co.name AS country
ORDER BY c.name;

// ============================================================================
// QUERY 2: List all teams that participated in Greek competitions
// ============================================================================

MATCH (g:Game)-[:PART_OF]->(c:Competition)-[:IN_COUNTRY]->(co:Country)
WHERE co.name = 'Greece'
MATCH (g)-[:HOME_TEAM|AWAY_TEAM]->(t:Team)
WITH DISTINCT t.name AS teamName
RETURN teamName
ORDER BY teamName;

// ============================================================================
// QUERY 3: List all Greek teams that played against foreign teams
// ============================================================================

// First, identify Greek competitions
MATCH (greekComp:Competition)-[:IN_COUNTRY]->(greekCountry:Country)
WHERE greekCountry.name = 'Greece'
WITH COLLECT(greekComp.name) AS greekCompetitions

// Find games in Greek competitions
MATCH (g:Game)-[:PART_OF]->(c:Competition)
WHERE c.name IN greekCompetitions
MATCH (g)-[:HOME_TEAM]->(ht:Team)
MATCH (g)-[:AWAY_TEAM]->(at:Team)

// Find games where one team is Greek and the other is foreign
MATCH (g)-[:PART_OF]->(comp:Competition)-[:IN_COUNTRY]->(country:Country)
WITH g, ht, at, comp, country,
     CASE 
       WHEN comp.name IN greekCompetitions THEN ht.name
       ELSE NULL
     END AS greekTeam,
     CASE 
       WHEN comp.name IN greekCompetitions THEN at.name
       ELSE NULL
     END AS foreignTeam

// Alternative approach: Find teams that played in both Greek and foreign competitions
MATCH (greekComp:Competition)-[:IN_COUNTRY]->(greekCountry:Country)
WHERE greekCountry.name = 'Greece'
WITH COLLECT(greekComp.name) AS greekCompetitions

MATCH (g:Game)-[:PART_OF]->(c:Competition)
WHERE c.name IN greekCompetitions
MATCH (g)-[:HOME_TEAM|AWAY_TEAM]->(t:Team)
WITH DISTINCT t.name AS greekTeamName

MATCH (g2:Game)-[:PART_OF]->(c2:Competition)-[:IN_COUNTRY]->(co2:Country)
WHERE co2.name <> 'Greece'
MATCH (g2)-[:HOME_TEAM|AWAY_TEAM]->(t2:Team)
WHERE t2.name = greekTeamName
WITH DISTINCT greekTeamName AS greekTeam, 
     COLLECT(DISTINCT c2.name) AS foreignCompetitions,
     COLLECT(DISTINCT co2.name) AS foreignCountries

MATCH (g3:Game)-[:PART_OF]->(c3:Competition)
WHERE c3.name IN foreignCompetitions
MATCH (g3)-[:HOME_TEAM|AWAY_TEAM]->(t3:Team)
WHERE t3.name <> greekTeam
WITH DISTINCT greekTeam, t3.name AS foreignTeam, c3.name AS foreignCompetition
RETURN greekTeam AS greekTeamName, 
       foreignTeam AS foreignTeamName, 
       foreignCompetition AS foreignCompetitionName
ORDER BY greekTeamName, foreignTeamName;

// ============================================================================
// QUERY 4: Top scorer per team in your favorite competition
// Replace 'superligaen' with your favorite competition name
// ============================================================================

MATCH (c:Competition {name: 'superligaen'})<-[:PART_OF]-(g:Game)
MATCH (p:Player)-[pi:PLAYED_IN]->(g)
WITH pi.teamName AS teamName, p, SUM(pi.goals) AS totalGoals
ORDER BY teamName, totalGoals DESC
WITH teamName, COLLECT({player: p.name, goals: totalGoals})[0] AS topScorer
RETURN teamName AS teamName,
       topScorer.player AS topScorerName,
       topScorer.goals AS totalGoals
ORDER BY topScorer.goals DESC;

// ============================================================================
// QUERY 5: Top 10 toughest defenders in your favorite competition
// Replace 'superligaen' with your favorite competition name
// ============================================================================

MATCH (c:Competition {name: 'superligaen'})<-[:PART_OF]-(g:Game)
MATCH (p:Player)-[pi:PLAYED_IN]->(g)
WHERE p.position = 'Defender'
WITH p, pi.teamName AS teamName, 
     SUM(pi.redCards) AS redCards,
     SUM(pi.yellowCards) AS yellowCards,
     SUM(pi.yellowCards + pi.redCards) AS totalCards
ORDER BY totalCards DESC, redCards DESC
LIMIT 10
RETURN p.name AS playerName, teamName, redCards, yellowCards
ORDER BY totalCards DESC;

// ============================================================================
// QUERY 6: Best attacking duo for a team in your favorite competition
// Replace 'superligaen' with your favorite competition name
// Replace 'FC Midtjylland' with your favorite team name
// ============================================================================

MATCH (c:Competition {name: 'superligaen'})<-[:PART_OF]-(g:Game)
MATCH (g)-[:HOME_TEAM|AWAY_TEAM]->(t:Team {name: 'FC Midtjylland'})
MATCH (p1:Player)-[pi1:PLAYED_IN {teamName: 'FC Midtjylland'}]->(g)
MATCH (p2:Player)-[pi2:PLAYED_IN {teamName: 'FC Midtjylland'}]->(g)
WHERE p1.position = 'Attack' 
  AND p2.position = 'Attack'
  AND p1.playerId < p2.playerId
WITH p1, p2, COUNT(DISTINCT g) AS gamesTogether
ORDER BY gamesTogether DESC
LIMIT 1
RETURN p1.name AS attacker1, 
       p2.name AS attacker2, 
       gamesTogether AS gamesPlayedTogether;

// Alternative using TEAMMATES relationship:
MATCH (team:Team {name: 'FC Midtjylland'})
MATCH (p1:Player)-[tm:TEAMMATES]-(p2:Player)
WHERE p1.position = 'Attack' 
  AND p2.position = 'Attack'
  AND p1.playerId < p2.playerId
  AND EXISTS {
    MATCH (p1)-[:PLAYED_IN {teamName: 'FC Midtjylland'}]->(g:Game)
    MATCH (p2)-[:PLAYED_IN {teamName: 'FC Midtjylland'}]->(g)
  }
RETURN p1.name AS attacker1, 
       p2.name AS attacker2, 
       tm.gamesTogether AS gamesPlayedTogether
ORDER BY tm.gamesTogether DESC
LIMIT 1;

// ============================================================================
// QUERY 7: Top 3 most connected players (played with most teammates)
// For a team in your favorite competition
// Replace 'superligaen' with your favorite competition name
// Replace 'FC Midtjylland' with your favorite team name
// ============================================================================

MATCH (c:Competition {name: 'superligaen'})<-[:PART_OF]-(g:Game)
MATCH (g)-[:HOME_TEAM|AWAY_TEAM]->(t:Team {name: 'FC Midtjylland'})
MATCH (p:Player)-[:PLAYED_IN {teamName: 'FC Midtjylland'}]->(g)
MATCH (p)-[tm:TEAMMATES]-(teammate:Player)
WHERE EXISTS {
  MATCH (teammate)-[:PLAYED_IN {teamName: 'FC Midtjylland'}]->(g2:Game)
  MATCH (g2)-[:PART_OF]->(c)
}
WITH p, COUNT(DISTINCT teammate) AS teammateCount
ORDER BY teammateCount DESC
LIMIT 3
RETURN p.name AS playerName, teammateCount AS numberOfTeammates;

// Alternative simpler version using TEAMMATES degree:
MATCH (p:Player)-[tm:TEAMMATES]-(teammate:Player)
WHERE EXISTS {
  MATCH (p)-[:PLAYED_IN {teamName: 'FC Midtjylland'}]->(g:Game)
  MATCH (g)-[:PART_OF]->(c:Competition {name: 'superligaen'})
}
WITH p, COUNT(DISTINCT teammate) AS teammateCount
ORDER BY teammateCount DESC
LIMIT 3
RETURN p.name AS playerName, teammateCount AS numberOfTeammates;

