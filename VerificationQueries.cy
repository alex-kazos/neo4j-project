// ============================================================================
// Verification Queries
// ============================================================================
// Run these queries to verify the data was loaded correctly

// 5.1: Count nodes by type
MATCH (n)
RETURN labels(n) AS nodeType, COUNT(n) AS count
ORDER BY nodeType;

// 5.2: Count relationships by type
MATCH ()-[r]->()
RETURN type(r) AS relationshipType, COUNT(r) AS count
ORDER BY relationshipType;

// 5.3: Sample game data verification
MATCH (g:Game)-[:HOME_TEAM]->(ht:Team), (g)-[:AWAY_TEAM]->(at:Team)
MATCH (g)-[:PART_OF]->(c:Competition)
RETURN g.gameId, g.gameDate, ht.name AS homeTeam, at.name AS awayTeam, 
       g.homeGoals, g.awayGoals, c.name AS competition
LIMIT 5;

// 5.4: Sample player participation verification
MATCH (p:Player)-[pi:PLAYED_IN]->(g:Game)
RETURN p.name AS playerName, p.position, pi.teamName, 
       g.gameId, pi.goals, pi.assists, pi.yellowCards, pi.redCards
LIMIT 5;

// 5.5: Sample TEAMMATES relationship verification
MATCH (p1:Player)-[tm:TEAMMATES]-(p2:Player)
RETURN p1.name AS player1, p2.name AS player2, tm.gamesTogether
ORDER BY tm.gamesTogether DESC
LIMIT 5;

// 5.6: Verify Country-Competition structure
MATCH (c:Competition)-[:IN_COUNTRY]->(co:Country)
RETURN co.name AS country, COLLECT(c.name) AS competitions
ORDER BY country
LIMIT 10;