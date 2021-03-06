-- Raw Data
SELECT * FROM Cost$
SELECT * FROM Total$ ORDER BY Year, State;
SELECT * FROM Region$
SELECT * FROM Safety$

-- ID Column Add/Remove
--Alter Table Total$ ADD Id INT IDENTITY;
--Alter Table Total$ DROP COLUMN Id;

-- Grouped
--SELECT Id, Year, COUNT(Year) over (Order By Id) as grp, Mechanism, Intent, [Age in years (85+ is collapsed)], [Average Medical Costs], [Average Work Loss Costs], [Death Count Used for Averages] FROM Cost$

-- Cleaned Data --
--SELECT Id, 
--ISNULL(Year, (SELECT TOP 1 Year FROM Cost$ WHERE Id < t.Id AND Year IS NOT NULL ORDER BY ID DESC)) AS Year_Updated, 
--ISNULL(Mechanism, (SELECT TOP 1 Mechanism FROM Cost$ WHERE Id < t.Id AND Mechanism IS NOT NULL ORDER BY ID DESC)) AS Mechanism_Updated, 
--ISNULL(Intent, (SELECT TOP 1 Intent FROM Cost$ WHERE Id < t.Id AND Intent IS NOT NULL ORDER BY ID DESC)) AS Intent_Updated, 
--ISNULL([Age in years (85+ is collapsed)], 85) AS "Age in Years", 
--SUBSTRING([Average Medical Costs], 0, LEN([Average Medical Costs])) AS 'Average Medical Costs', 
--SUBSTRING([Average Work Loss Costs], 0, LEN([Average Work Loss Costs])) AS 'Average Work Loss Costs', 
--SUBSTRING([Death Count Used for Averages], 0, LEN([Death Count Used for Averages])) AS 'Death Count Used for Averages' FROM Cost$ t;

-- Regional Comparsion
SELECT Region$.Census_Bureau_Regions, AVG(Safety$.[GUN LAW STRENGTH (RANKED)]) AS 'Average Gun Safety Rank', SUM(Population) AS Population, SUM(Deaths) AS Deaths, FORMAT(SUM(Deaths)/SUM(Population), 'P4') AS 'Death Rate 2000-2017' From Total$
JOIN Region$
ON (Region$.State = Total$.State)
JOIN Safety$
ON (Safety$.State = Total$.State)
GROUP BY Region$.Census_Bureau_Regions
ORDER BY AVG(Safety$.[GUN LAW STRENGTH (RANKED)]) ASC

-- State Comparison 2000-2017 to 2020
SELECT Region$.State, AVG(Safety$.[GUN LAW STRENGTH (RANKED)]) AS 'Average Gun Safety Rank', 
SUM(Population) AS 'Population (2000-2017)', 
SUM(Deaths) AS 'Deaths (2000-2017)', 
Region$.Census_Bureau_Regions,
FORMAT(SUM(Deaths)/SUM(Population), 'P4') AS 'Death Rate (2000-2017)', 
FORMAT(Safety$.[GUN DEATH RATE 2020 (PER 100K)]/100000,'P4') AS 'Death Rate (2020)', 
FORMAT(Safety$.[GUN DEATH RATE 2020 (PER 100K)]/100000 - SUM(Total$.Deaths)/SUM(Population), 'P4') AS '2000-2017 Comparison to 2020' From Total$
JOIN Region$
ON (Region$.State = Total$.State)
JOIN Safety$
ON (Safety$.State = Total$.State)
GROUP BY Region$.State, Safety$.[GUN DEATH RATE 2020 (PER 100K)], Region$.Census_Bureau_Regions
ORDER BY AVG(Safety$.[GUN LAW STRENGTH (RANKED)]), Region$.State ASC

-- Region Comparison 2000-2017 to 2020
SELECT Region$.Census_Bureau_Regions,
SUM(Population) AS 'Population (2000-2017)', 
SUM(Deaths) AS 'Deaths (2000-2017)', 
FORMAT(SUM(Deaths)/SUM(Population), 'P4') AS 'Death Rate (2000-2017)', 
FORMAT(Safety$.[GUN DEATH RATE 2020 (PER 100K)]/100000,'P4') AS 'Death Rate (2020)', 
FORMAT(Safety$.[GUN DEATH RATE 2020 (PER 100K)]/100000 - SUM(Total$.Deaths)/SUM(Population), 'P4') AS '2000-2017 Comparison to 2020' From Total$
JOIN Region$
ON (Region$.State = Total$.State)
JOIN Safety$
ON (Safety$.State = Total$.State)
GROUP BY Region$.Census_Bureau_Regions,Safety$.[GUN DEATH RATE 2020 (PER 100K)]

-- Yearly Comparison
SELECT Year, SUM(Population) AS Population, SUM(Deaths) AS Deaths, FORMAT(SUM(Deaths)/SUM(Population), 'P4') AS 'Death Rate 2000-2017' From Total$
GROUP BY Year
ORDER BY Year ASC

-- Sum of Average Work Loss per Year
-- Create Table First --
CREATE TABLE #Cost_Updated (
Id int,
Updated_Year int,
Updated_Mechanism varchar(100),
Updated_Intent varchar(100),
Updated_Age_in_Years int,
Updated_Average_Medical_Costs int,
Updated_Average_Work_Loss_Costs int,
Updated_Death_Count_Used_For_Averages int
)
-- Input Data --
INSERT INTO #Cost_Updated SELECT Id, 
ISNULL(Year, (SELECT TOP 1 Year FROM Cost$ WHERE Id < t.Id AND Year IS NOT NULL ORDER BY ID DESC)) AS Year_Updated, 
ISNULL(Mechanism, (SELECT TOP 1 Mechanism FROM Cost$ WHERE Id < t.Id AND Mechanism IS NOT NULL ORDER BY ID DESC)) AS Mechanism_Updated, 
ISNULL(Intent, (SELECT TOP 1 Intent FROM Cost$ WHERE Id < t.Id AND Intent IS NOT NULL ORDER BY ID DESC)) AS Intent_Updated, 
ISNULL([Age in years (85+ is collapsed)], 85) AS "Age in Years", 
REPLACE(REPLACE(SUBSTRING([Average Medical Costs], 0, LEN([Average Medical Costs])), ',', ''), '$', '') AS 'Average Medical Costs', 
REPLACE(REPLACE(SUBSTRING([Average Work Loss Costs], 0, LEN([Average Work Loss Costs])), ',', ''), '$', '') AS 'Average Work Loss Costs',
SUBSTRING([Death Count Used for Averages], 0, LEN([Death Count Used for Averages])) AS 'Death Count Used for Averages' FROM Cost$ t;
-- Updated Data -- 
SELECT * FROM #Cost_Updated;
-- Drop Table -- 
-- DROP TABLE #Cost_Updated

-- Top 10 Crude Rate Based off of State Yearly Population and Death # (Excluding District of Columbia)
SELECT TOP 10 Year, State, Deaths, [Age in Years], Population, SUM(Deaths) OVER(PARTITION BY Year) AS 'Yearly National Deaths', FORMAT([Crude Rate]/100000, 'P4') AS 'Crude Rate - Yearly State Population', FORMAT(Deaths/SUM(Deaths) OVER(PARTITION BY Year), 'P4') AS '% of Death Rate - Yearly National' FROM Total$
WHERE [Age in Years] IS NOT NULL AND [Age in Years] != 85 AND Deaths >= 10 AND State != 'District of Columbia'
ORDER BY 'Crude Rate - Yearly State Population' DESC



