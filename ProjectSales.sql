 --Use master database
USE master; 
GO 
--Create TutorialDB database it not exist
IF NOT EXISTS ( SELECT name FROM sys.databases WHERE name = N'Project_Sales' ) CREATE DATABASE [Project_Sales]; 
Go

--------------------------------

--Inspecting data

SELECT * FROM [dbo].[Sales]

--Checking unique values

SELECT DISTINCT status FROM [dbo].[Sales] -- nice one to plot
SELECT DISTINCT YEAR_ID FROM [dbo].[Sales]
SELECT DISTINCT PRODUCTLINE FROM [dbo].[Sales] -- nice to plot
SELECT DISTINCT COUNTRY FROM [dbo].[Sales] -- nice to plot
SELECT DISTINCT DEALSIZE FROM [dbo].[Sales] -- nice to plot
SELECT DISTINCT TERRITORY FROM [dbo].[Sales] -- nice to plot

--ANALYSIS

-- 1. Sales by productline

SELECT PRODUCTLINE, SUM(SALES) Revenue
FROM [dbo].[Sales]
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

-- 2. Sales by year

SELECT YEAR_ID, SUM(SALES) Revenue
FROM [dbo].[Sales]
GROUP BY YEAR_ID
ORDER BY 2 DESC

/*

SELECT DISTINCT MONTH_ID
FROM [dbo].[Sales]
WHERE YEAR_ID = 2003

SELECT DISTINCT MONTH_ID
FROM [dbo].[Sales]
WHERE YEAR_ID = 2004

SELECT DISTINCT MONTH_ID
FROM [dbo].[Sales]
WHERE YEAR_ID = 2005

--They had a full operations in two years (2003, 2004) and then 5 months in 2005 they operated

*/

-- 3. Sales by dealsize

SELECT DEALSIZE, SUM(SALES) Revenue
FROM [dbo].[Sales]
GROUP BY DEALSIZE
ORDER BY 2 DESC

/* Medium size generates the most revenue */

-- 4. Best month for sales per year

SELECT MONTH_ID, SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
FROM [dbo].[Sales]
WHERE YEAR_ID = 2003 --Change year to see the rest
GROUP BY MONTH_ID
ORDER BY 2 DESC

/* November seems to be the month, what product do they sell in November? */

-- 5. What product line sells most in best month?

SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
FROM [dbo].[Sales]
WHERE YEAR_ID = 2003 AND MONTH_ID = 11 
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC

/* Classic Cars are the most sold product */

-- 6. Who is our best customer? (This could be best answered with RFM)

/*
Recency - last order date
Frequency - count of total orders
Monetary value - total spend
*/

DROP TABLE IF EXISTS #RFM;
WITH RFM AS
(
    SELECT
        CUSTOMERNAME,
        SUM(SALES) MonetaryValue,
        AVG(SALES) AvgMonetaryValue,
        COUNT(ORDERNUMBER) Frequency,
        MAX(ORDERDATE) LastOrderDate,
        (SELECT MAX(ORDERDATE) FROM [dbo].[Sales]) MaxOrderDate,
        DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM [dbo].[Sales])) Recency
    FROM [dbo].[Sales]
    GROUP BY CUSTOMERNAME
),
RFM_Calc AS 
(
    SELECT R.*,
        NTILE(4) OVER (ORDER BY Recency DESC) RFM_Recency,
        NTILE(4) OVER (ORDER BY Frequency DESC) RFM_Frequency,
        NTILE(4) OVER (ORDER BY MonetaryValue DESC) RFM_Monetary
    FROM RFM R
)
SELECT 
    C.*,
    RFM_Recency + RFM_Frequency + RFM_Monetary AS RFM_Cell,
    CAST(RFM_Recency AS varchar) + CAST(RFM_Frequency AS varchar) + CAST(RFM_Monetary AS varchar) RFM_CellString
INTO #RFM
FROM RFM_Calc C

SELECT 
    CUSTOMERNAME, RFM_Recency, RFM_Frequency, RFM_Monetary,
    CASE
        WHEN RFM_CellString in (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) THEN 'Lost Customers' --Lost customers 
        WHEN RFM_CellString in (133, 134, 143, 244, 334, 343, 344) THEN 'Slipping Away, Cannot Lose' --Big spenders who haven't purchased lately) 
        WHEN RFM_CellString in (311, 411, 331) THEN 'New Customers' 
        WHEN RFM_CellString in (222, 223, 233, 322) THEN 'Potential Churners' 
        WHEN RFM_CellString in (323, 333, 321, 422, 332, 432) THEN 'Active' --Customers who buy often & recently, but at low price points
        WHEN RFM_CellString in (433, 434, 443, 444) THEN 'Loyal' 
    END RFM_Segment
FROM #RFM

-- 7.What products are most often sold together?

--select * from [dbo].[Sales] where ORDERNUMBER = 10411

SELECT DISTINCT ORDERNUMBER, STUFF(    
    
    (SELECT ',' + PRODUCTCODE
    FROM [dbo].[Sales] A
    WHERE ORDERNUMBER IN
    (
        SELECT ORDERNUMBER
        FROM
        (
            SELECT ORDERNUMBER, COUNT(*) RN
            FROM [dbo].[Sales]
            WHERE [STATUS] = 'Shipped'
            GROUP BY ORDERNUMBER
        ) O
        WHERE RN = 2
    )
    AND A.ORDERNUMBER = S.ORDERNUMBER
    FOR XML PATH (''))
    , 1, 1, '') ProductCodes
    
FROM [dbo].[Sales] S
ORDER BY 2 DESC

--There are 19 items where there were only 2 items ordered
--Stuff: xml to string

/* This is an easy way to track which products are usually sold together. If you are trying to run promotions/campaign, 
you can advertise those things together. Because there is a higher chance customers buying those things together. */




