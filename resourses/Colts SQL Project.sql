-- 1. Ticket Sales for 2021 Regular Season 

-- 	1.1 Revenue and Seat Count by Event Date
SELECT 
ts.event_name 
,ts.event_date 
,SUM(ts.Price) AS 'Total Revenue'
,COUNT(DISTINCT ts.SeatUniqueID) AS 'Total Seats Sold'
FROM TicketSales ts
WHERE ts.Season = '2021' AND ts.status = 'SOLD'
GROUP BY ts.event_name, ts.event_date 
ORDER BY SUM(ts.Price) DESC

-- 	1.2 Revenue and Seat Count for New Full Seasons, and Renewal Full Seasons (separate columns for each)
SELECT 
ts.TicketType
,SUM(ts.Price) AS 'Total Revenue'
,COUNT(DISTINCT ts.SeatUniqueID) AS 'Total Seats Sold'
FROM TicketSales ts
WHERE ts.Season = '2021' AND ts.status = 'SOLD' AND ts.plan_event_name IN ('21FS','21FS9') AND ts.TicketType IN ('New','Renewal')
GROUP BY ts.TicketType 
ORDER BY SUM(ts.Price) DESC

-- 	1.3 Revenue and Seat Count for each Stadium Manifest Description
SELECT 
m.Description 
,SUM(ts.Price) AS 'Total Revenue'
,COUNT(DISTINCT ts.SeatUniqueID) AS 'Total Seats Sold'
FROM TicketSales ts 
LEFT JOIN Manifest m ON ts.section_name = m.[Section] 
WHERE ts.Season = '2021' AND ts.status = 'SOLD'
GROUP BY m.Description 
ORDER BY SUM(ts.Price) DESC

-- 	1.4 Revenue and Seats Sold per Day Leading Up to the Game (Use event date 11/4/2021)
SELECT 
CAST(ts.sale_datetime AS DATE)
,SUM(ts.Price) AS 'Total Revenue'
,COUNT(DISTINCT ts.SeatUniqueID) AS 'Total Seats Sold'
FROM TicketSales ts
WHERE ts.event_date = '2021-11-04' AND ts.sale_datetime < '2021-11-05' AND ts.status = 'SOLD'
GROUP BY CAST(ts.sale_datetime AS DATE)
ORDER BY SUM(ts.Price) DESC

-- 	Tables: TicketSales, Manifest


-- 2. Email Stats 

-- 	2.1 Percentage of 2021 ticket buyers who opened and clicked an email
SELECT 
COUNT(DISTINCT ts.acct_id) AS '2021 ticket buyers'
,COUNT(DISTINCT CASE WHEN ce.Opened > '0' AND ce.ClickedOn > '0' THEN ce.ID END) AS '2021 ticket buyers who opened and clicked an email'
,ROUND(COUNT(DISTINCT CASE WHEN ce.Opened > '0' AND ce.ClickedOn > '0' THEN ce.ID END) * 100 / (SELECT COUNT(DISTINCT ts.acct_id) FROM TicketSales ts),2) AS 'Percentage of 2021 ticket buyers who opened and clicked an email'
FROM TicketSales ts
LEFT JOIN CampaignEngagement ce ON ts.acct_id = cast(ce.ID AS VARCHAR(100))
WHERE ts.Season = '2021' AND ts.Price > '0'

-- 	2.2 Total number of Group buyers who opened or clicked an email
SELECT 
COUNT(DISTINCT ts.acct_id) AS 'Total number of Group buyers who opened or clicked an email'
FROM TicketSales ts
LEFT JOIN CampaignEngagement ce ON ts.acct_id = ce.ID  
WHERE ts.acct_type = 'Group' AND (ce.Opened > '0' OR ce.ClickedOn > '0')

-- or for email details
SELECT 
ts.acct_id
,SUM(ts.Price) AS 'Total Spend'
,ce.Delivered 
,ce.Opened 
,ce.ClickedOn 
FROM TicketSales ts
LEFT JOIN CampaignEngagement ce ON ts.acct_id = ce.ID  
WHERE ts.acct_type = 'Group' AND (ce.Opened > '0' OR ce.ClickedOn > '0')
GROUP BY ts.acct_id, ce.Delivered, ce.Opened, ce.ClickedOn 

-- 	Tables: CampaignEngagement, TicketSales


-- 3. Manifest
-- 	3.1 Overall Sell-Through Rate by Section in 2021 (Top 10 and Bottom 10 sections)
SELECT TOP(10)
a2.[Section] 
,a1.[Seats Sold]
,a2.[Seat Inventory Per Game]*10 AS 'Total Seat Inventory'
,ROUND(a1.[Seats Sold]*100/(a2.[Seat Inventory Per Game]*10), 2) AS 'Overall Sell-Through Rate'
FROM
	(SELECT 
	ts.section_name
	,COUNT(ts.SeatUniqueID) AS 'Seats Sold'
	FROM TicketSales ts
	WHERE ts.Season = '2021' AND ts.status = 'SOLD'
	GROUP BY ts.section_name
	) a1
LEFT JOIN 
	(SELECT 
	ma.[Section]
	,SUM(ma.Capacity) AS 'Seat Inventory Per Game' 
	FROM 
		(SELECT 
		DISTINCT *
		FROM Manifest m
		) ma
	GROUP BY ma.[Section]
	) a2 
ON a1.section_name = a2.[Section]
ORDER BY ROUND(a1.[Seats Sold]*100/(a2.[Seat Inventory Per Game]*10), 2) DESC, a1.[Seats Sold] DESC

SELECT TOP(10)
a2.[Section] 
,a1.[Seats Sold]
,a2.[Seat Inventory Per Game]*10 AS 'Total Seat Inventory'
,ROUND(a1.[Seats Sold]*100/(a2.[Seat Inventory Per Game]*10), 2) AS 'Overall Sell-Through Rate'
FROM
	(SELECT 
	ts.section_name
	,COUNT(ts.SeatUniqueID) AS 'Seats Sold'
	FROM TicketSales ts
	WHERE ts.Season = '2021' AND ts.status = 'SOLD'
	GROUP BY ts.section_name
	) a1
LEFT JOIN 
	(SELECT 
	ma.[Section]
	,SUM(ma.Capacity) AS 'Seat Inventory Per Game' 
	FROM 
		(SELECT 
		DISTINCT *
		FROM Manifest m
		) ma
	GROUP BY ma.[Section]
	) a2 
ON a1.section_name = a2.[Section]
ORDER BY ROUND(a1.[Seats Sold]*100/(a2.[Seat Inventory Per Game]*10), 2)

-- 	3.2 Sell-Through for Bottom 10 sections by Game Date in 2021
SELECT 
ts.event_name
,ts.event_date 
,COUNT(CASE WHEN ts.status = 'Sold' THEN ts.SeatUniqueID END) AS 'Seats Sold'
,COUNT(ts.SeatUniqueID) AS 'Seat Inventory'
,ROUND(COUNT(CASE WHEN ts.status = 'Sold' THEN ts.SeatUniqueID END)*100/COUNT(ts.SeatUniqueID),2) AS 'Sell-Through for Bottom 10 sections'
FROM TicketSales ts 
WHERE ts.Season = '2021' AND ts.section_name IN ('350','US16A','US16B','US11B','US17A','529','US15A','524','617','LS31A')
GROUP BY ts.event_name, ts.event_date 
ORDER BY ROUND(COUNT(CASE WHEN ts.status = 'Sold' THEN ts.SeatUniqueID END)*100/COUNT(ts.SeatUniqueID),2)

-- 	Tables: Manifest, TicketSales



-- 4. F&B
-- 	4.1 Overall Revenue by Item in 2021 (Top 5 and Bottom 5 items)
SELECT TOP(5)
f.Item 
,SUM(f.Sales)
FROM FNB f 
GROUP BY f.Item 
ORDER BY SUM(f.Sales) DESC

SELECT TOP(5)
f.Item 
,SUM(f.Sales)
FROM FNB f 
GROUP BY f.Item 
ORDER BY SUM(f.Sales)

-- 	4.2 Section with highest ratio of Tickets Sold to Overall F&B Quantity Sold (Numbered Sections Only)
SELECT 
b1.[Section]
,b1.[Tickets Sold]
,b2.[F&B Sold]
,ROUND(b1.[Tickets Sold]/b2.[F&B Sold],2) AS 'Ratio of Tickets Sold to Overall F&B Quantity Sold '
FROM
	(SELECT 
	ts.section_name AS 'Section'
	,COUNT(ts.SeatUniqueID) AS 'Tickets Sold'
	FROM TicketSales ts 
	WHERE ts.Season = '2021' AND ts.status = 'Sold'
	GROUP BY ts.section_name 
	) b1
LEFT JOIN
	(SELECT 
	LEFT(TRIM('LOCATION: 'FROM f.Location_Name),3) AS 'Section'
	,SUM(cast(f.Qty AS INT)) AS 'F&B Sold'
	FROM FNB f 
	GROUP BY LEFT(TRIM('LOCATION: 'FROM f.Location_Name),3)
	) b2
ON b1.[Section] = b2.[Section]
ORDER BY ROUND(b1.[Tickets Sold]/b2.[F&B Sold],2) DESC

SELECT 
b1.[Section]
,b1.[Tickets Sold]
FROM
	(SELECT 
	ts.section_name AS 'Section'
	,COUNT(ts.SeatUniqueID) AS 'Tickets Sold'
	FROM TicketSales ts 
	WHERE ts.Season = '2021' AND ts.status = 'Sold'
	GROUP BY ts.section_name 
	) b1
LEFT JOIN
	(SELECT 
	LEFT(TRIM('LOCATION: 'FROM f.Location_Name),3) AS 'Section'
	FROM FNB f 
	GROUP BY LEFT(TRIM('LOCATION: 'FROM f.Location_Name),3)
	) b2
ON b1.[Section] = b2.[Section]
ORDER BY b1.[Section]


-- 	Tables: FNB, TicketSales, Manifest