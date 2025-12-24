// ============================================================================
// QUERY 1: Στατιστικά ανά πρωτάθλημα (νίκες γηπεδούχων/φιλοξενούμενων/ισοπαλίες)
// ============================================================================

MATCH (g:Game)-[:PART_OF]->(c:Competition)
WITH c.name AS competition,
     sum(case when g.winner = 1 then 1 else 0 end) AS homeWins,
     sum(case when g.winner = 2 then 1 else 0 end) AS awayWins,
     sum(case when g.winner = 0 then 1 else 0 end) AS draws
RETURN competition, homeWins, awayWins, draws
ORDER BY competition;

// ============================================================================
// QUERY 2: Αγώνες ελληνικού πρωταθλήματος (ημ/νία, ομάδες, γκολ) ταξινομημένα
// ============================================================================

MATCH (g:Game)-[:PART_OF]->(c:Competition)-[:IN_COUNTRY]->(co:Country {name:'Greece'})
MATCH (g)-[:HOME_TEAM]->(ht:Team)
MATCH (g)-[:AWAY_TEAM]->(at:Team)
RETURN g.gameDate AS date,
       ht.name AS homeTeam,
       at.name AS awayTeam,
       g.homeGoals AS homeGoals,
       g.awayGoals AS awayGoals
ORDER BY date;

// ============================================================================
// QUERY 3: Παίκτες που έπαιξαν Ελλάδα και εξωτερικό
// ============================================================================

// Παίκτες με συμμετοχές σε ελληνικό πρωτάθλημα
MATCH (p:Player)-[pi:PLAYED_IN]->(g:Game)-[:PART_OF]->(cGr:Competition)-[:IN_COUNTRY]->(:Country {name:'Greece'})
WITH DISTINCT p, pi.teamName AS greekTeam

// Ίδιοι παίκτες με συμμετοχές σε μη ελληνικό πρωτάθλημα
MATCH (p)-[pi2:PLAYED_IN]->(g2:Game)-[:PART_OF]->(cFg:Competition)-[:IN_COUNTRY]->(coFg:Country)
WHERE coFg.name <> 'Greece'
WITH DISTINCT p.name AS player,
     greekTeam,
     pi2.teamName AS foreignTeam,
     cFg.name AS foreignCompetition
RETURN player, greekTeam, foreignTeam, foreignCompetition
ORDER BY greekTeam, foreignTeam;

// ============================================================================
// QUERY 4: Πρώτος σκόρερ κάθε ομάδας σε επιλεγμένο πρωτάθλημα ('super-league-1')
// ============================================================================

WITH 'super-league-1' AS compName
MATCH (c:Competition {name: compName})<-[:PART_OF]-(g:Game)
MATCH (p:Player)-[pi:PLAYED_IN]->(g)
WITH pi.teamName AS teamName, p.name AS player, SUM(pi.goals) AS totalGoals
ORDER BY teamName, totalGoals DESC
WITH teamName, COLLECT({player: player, goals: totalGoals})[0] AS topScorer
RETURN teamName,
       topScorer.player AS topScorerName,
       topScorer.goals AS totalGoals
ORDER BY totalGoals DESC;

// ============================================================================
// QUERY 5: Top 10 «σκληροί» αμυντικοί σε επιλεγμένο πρωτάθλημα ('super-league-1')
// ============================================================================

WITH 'super-league-1' AS compName   
MATCH (c:Competition {name: compName})<-[:PART_OF]-(g:Game)
MATCH (p:Player)-[pi:PLAYED_IN]->(g)
WHERE p.position = 'Defender'
WITH p.name AS playerName,
     pi.teamName AS teamName,
     SUM(pi.redCards) AS redCards,
     SUM(pi.yellowCards) AS yellowCards,
     SUM(pi.redCards + pi.yellowCards) AS totalCards
RETURN playerName, teamName, redCards, yellowCards, totalCards
ORDER BY redCards DESC, yellowCards DESC
LIMIT 10;

// ============================================================================
// QUERY 6: Βασικό επιθετικό δίδυμο ομάδας (TEAMMATES) σε επιλεγμένη ομάδα ('Panathinaikos Athens')
// ============================================================================

WITH 'Panathinaikos Athens' AS teamName   
MATCH (p1:Player)-[tm:TEAMMATES]-(p2:Player)
WHERE p1.position = 'Attack'
  AND p2.position = 'Attack'
  AND p1.playerId < p2.playerId
  AND tm.gamesTogether IS NOT NULL
  AND EXISTS {
    MATCH (p2)-[:PLAYED_IN {teamName: teamName}]->(g)
  }
RETURN p1.name AS attacker1,
       p2.name AS attacker2,
       tm.gamesTogether AS gamesTogether
ORDER BY tm.gamesTogether DESC
LIMIT 1;

// ============================================================================
// QUERY 7: 3 πιο κομβικοί παίκτες ομάδας (με τους περισσότερους συμπαίκτες) σε επιλεγμένη ομάδα ('Panathinaikos Athens')
// ============================================================================

WITH 'Panathinaikos Athens' AS teamName
MATCH (p)-[tm:TEAMMATES]-(teammate:Player)
WHERE EXISTS {
  MATCH (teammate)-[:PLAYED_IN {teamName: teamName}]->(:Game)-[:PART_OF]->(c)
}
WITH p, COUNT(DISTINCT teammate) AS teammateCount
RETURN p.name AS playerName, teammateCount AS numberOfTeammates
ORDER BY teammateCount DESC
LIMIT 3;

