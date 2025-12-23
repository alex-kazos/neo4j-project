// Load Data ( one row example )

LOAD CSV WITH HEADERS from
"file:///Consumer_Complaints.csv" AS LINE
RETURN LINE
limit 1

// Create Constraints ( Node Indexes )
// Uniqueness constraints.
CREATE CONSTRAINT FOR (c:Complaint) REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT FOR (c:Company) REQUIRE c.name IS UNIQUE;
CREATE CONSTRAINT FOR (r:Response) REQUIRE r.name IS UNIQUE;
CREATE CONSTRAINT FOR (p:Product) REQUIRE p.name IS UNIQUE;
CREATE CONSTRAINT FOR (i:Issue) REQUIRE i.name IS UNIQUE;
CREATE CONSTRAINT FOR (s:SubProduct) REQUIRE s.name IS UNIQUE;
CREATE CONSTRAINT FOR (s:SubIssue) REQUIRE s.name IS UNIQUE;

// Load Nodes with properties 
// Load Complaint Nodes.
LOAD CSV WITH HEADERS
FROM "file:///Consumer_Complaints.csv" AS line 
WITH DISTINCT line, SPLIT(line.`Date received`,'/') AS date

CREATE (complaint:Complaint {id: TOINTEGER(line.`Complaint ID`)})
SET complaint.year = TOINTEGER(date[2]),
    complaint.month = TOINTEGER(date[0]),
    complaint.day = TOINTEGER(date[1]);

// Create nodes with MERGE
// Load Company, Response Nodes.
LOAD CSV WITH HEADERS
FROM "file:///Consumer_Complaints.csv" AS line
MERGE (company:Company { name:TOUPPER( line.Company) })
MERGE (response:Response { name:TOUPPER( line .`Company response to consumer`) });

// Create relationship between nodes (with properties)
// Load AGAINST, TO relationships
LOAD CSV WITH HEADERS
FROM "file:///Consumer_Complaints.csv" AS line
MATCH (complaint:Complaint { id:TOINTEGER( line .`Complaint ID`) })
MATCH (response:Response { name:TOUPPER( line .`Company response to consumer`) })
MATCH (company:Company { name: TOUPPER( line.Company ) })
CREATE (complaint)-[:AGAINST]->(company)
CREATE (response)-[r:TO]->(complaint)
SET r.timely = CASE line.`Timely response?` WHEN 'Yes' THEN true ELSE false END,
    r.disputed = CASE line.`Consumer disputed?` WHEN 'Yes' THEN true ELSE false END;

// Create Nodes and relationshops
//Load Product, Issue Nodes, ABOUT, WITH relationship
LOAD CSV WITH HEADERS
FROM "file:///Consumer_Complaints.csv" AS line
MATCH (complaint:Complaint { id: TOINTEGER( line .`Complaint ID`) })
MERGE (product:Product { name:TOUPPER( line.Product ) })
MERGE (issue:Issue {name:TOUPPER( line.Issue ) })
CREATE (complaint)-[:ABOUT]->(product)

// Sub-issue node and relationship (remove empty nodes)
//Load sub-issue nodes and relationship
LOAD CSV WITH HEADERS
FROM "file:///Consumer_Complaints.csv" AS line WITH line
WHERE line.`Sub-issue` <> '' AND line.`Sub-issue` IS NOT NULL
MATCH (complaint:Complaint {id:TOINTEGER(line.`Complaint ID`)})
MATCH (complaint)-[:WITH]->(issue:Issue)
MERGE (subIssue:SubIssue { name:TOUPPER(line.`Sub-issue`)})
MERGE (subIssue)-[:IN_ISSUE_CATEGORY]->(issue)
CREATE (complaint)-[:WITH]->(subIssue);

// sub-product node and relationship
// Load Sub product nodes and relations.
LOAD CSV WITH HEADERS
FROM "file:///Consumer_Complaints.csv" AS line WITH line
WHERE line.`Sub-product` <> '' AND line .`Sub-product` IS NOT NULL
MATCH (complaint:Complaint { id:TOINTEGER( line .`Complaint ID`) })
MATCH (complaint)-[: ABOUT]->(product:Product)
MERGE (subProduct:SubProduct { name:TOUPPER( line .`Sub-product`) })
MERGE (subProduct)-[:IN_PRODUCT_CATEGORY ]->(product)
CREATE (complaint)-[: ABOUT]->(subProduct);


// Queries

// 1. Top types of responses that are disputed
MATCH (r:Response)-[:TO {disputed: true}]->(:Complaint)
RETURN r.name AS response, COUNT(*) AS count
ORDER BY count DESC

// 2. Companies with the most disputed responses
MATCH (:Response)-[:TO {disputed: true}]->(complaint:Complaint)
MATCH (complaint)-[: AGAINST]->(company:Company)
RETURN company.name AS company, COUNT(*) AS count
ORDER BY count DESC
LIMIT 10;

// 3. All Issues
MATCH (i:Issue)
RETURN i.name as issue
ORDER BY issue;

// 4. All sub-issues within the 'communication tactics' issue
MATCH (i:Issue {name:'COMMUNICATION TACTICS'})
MATCH (sub:SubIssue)-[:IN_ISSUE_CATEGORY]-> (i)
RETURN sub.name AS subissue 
ORDER BY subissue;

// 5. Top products and sub products associated with the obscene / 
// abusive language sub issue
MATCH (subIssue:SubIssue {name:'USED OBSCENE/PROFANE/ABUSIVE LANGUAGE'})
MATCH (complaint:Complaint)-[:WITH]->(subIssue)
MATCH (complaint)-[:ABOUT]->(p:Product)
OPTIONAL MATCH (complaint)-[:ABOUT]->(sub:SubProduct)
RETURN p.name AS product, sub.name AS subproduct, COUNT(*) AS count 
ORDER BY count DESC;


// 6. Top company associated with the obscene / abusive language sub issue
MATCH (subIssue:SubIssue {name:'USED OBSCENE/PROFANE/ABUSIVE LANGUAGE'})
MATCH (complaint:Complaint)-[: WITH]->(subIssue)
MATCH (complaint)-[: AGAINST]->(company:Company)
RETURN company.name AS company, COUNT(*) AS count
ORDER BY count DESC
LIMIT 10;

// 7. Sub products that belong to multiple product categories
MATCH (sub:SubProduct)-[:IN_PRODUCT_CATEGORY ]->(p:Product)
WITH sub, COLLECT(p) AS products
WHERE SIZE(products ) > 1
RETURN sub, products;