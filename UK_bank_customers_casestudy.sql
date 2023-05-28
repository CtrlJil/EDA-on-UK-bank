
----check for duplicate values
SELECT *, ROW_NUMBER() over (partition by Customer_ID, Age Order by Date_Joined)dup_check
FROM Bank..customers
---no duplicate values

---total number of customers
SELECT	*
FROM Bank..customers
WHERE Date_Joined BETWEEN '01-01-2015' AND '12-31-2022'
ORDER BY Balance desc;

---Replace dates that do not yet exist 

UPDATE Bank..customers
SET Date_Joined = DATEADD(YEAR, -2, Date_Joined)
WHERE YEAR(Date_Joined) = 2023 AND YEAR(Date_Joined) = 2024 AND YEAR(Date_Joined)=2025


---Distribution of Customers by Job & Region

SELECT Region, Job_Classification,
		COUNT(*) as JobCount, AVG(Balance) as Average_Bal
FROM Bank..customers
GROUP BY Region, Job_Classification
ORDER BY Average_Bal;

---Classification of customers by age groups & Gender per region

SELECT 
	Region,
	SUM(CASE WHEN Age BETWEEN 13 AND 19 THEN 1 ELSE 0 END) as Teenager,
	SUM(CASE WHEN Age BETWEEN 20 AND 29 THEN 1 ELSE 0 END) as YoungAdult,
	SUM(CASE WHEN Age BETWEEN 30 AND 59 THEN 1 ELSE 0 END) as Adult,
	SUM(CASE WHEN Age >= 60 THEN 1 ELSE 0 END) as Elder,
	SUM(CASE WHEN Gender = 'Male' THEN 1 ELSE 0 END) as Male,
	SUM(CASE WHEN Gender = 'Female' THEN 1 ELSE 0 END) as Female
FROM
	Bank..customers
GROUP BY
	Region


 ----Average Balance per age group
SELECT 
	CASE 
		WHEN Age < 20 THEN 'Teenager'
		WHEN Age BETWEEN 20 AND 29 THEN 'YoungAdult'
		WHEN Age BETWEEN 30 AND 59 THEN 'MiddleAge'
		ELSE 'Elder'
	END AS AgeGroup,
	AVG(Balance) as AVGBal
FROM
	Bank..customers
GROUP BY
	CASE
		WHEN Age < 20 THEN 'Teenager'
		WHEN Age BETWEEN 20 AND 29 THEN 'YoungAdult'
		WHEN Age BETWEEN 30 AND 59 THEN 'MiddleAge'
		ELSE 'Elder'
	END
ORDER BY AVGBal;


---Group customers by Job Classification
SELECT Region, Job_Classification, COUNT(Region) as Job_count
FROM Bank..customers
GROUP BY Region, Job_Classification

----check number of customers by region & average balance
SELECT	
	Region, COUNT(*) as customer_count, AVG(Balance) as average_balance
FROM Bank..customers
GROUP BY Region
ORDER BY customer_count;


---Average balance per Job classification
SELECT Job_Classification, AVG(Balance) as AVGBalance, COUNT(*) as count
FROM Bank..customers
GROUP BY Job_Classification




---Calculate growth percentage over the last ten years

SELECT	
	COUNT(Customer_ID) as total_customers_gained,
	((COUNT(Customer_ID)-First_Customers) / First_Customers*100) as growth_percentage
FROM Bank..customers,
	(SELECT COUNT(Customer_ID) First_Customers
	FROM Bank..customers
	WHERE Date_Joined BETWEEN '01-01-2015' AND '12-31-2015') FCC
	GROUP BY First_Customers



---Calculating credit risk score to check for loan eligibility
---Three factors are used to determine credit risk(Balance, Age and Job Classification)
 SELECT
Customer_ID,
Gender,
Age
INTO #creditRisk
FROM (
	 SELECT
		Customer_ID,
		Customer_Name,
		Gender,
		Age,
		Region,
		Job_Classification,
		Date_Joined,
		Balance,
	(Balance * 0.5 + Age * 0.3 +
	CASE
	WHEN Job_Classification = 'Blue Collar' THEN 1
	WHEN Job_Classification = 'White Collar' THEN 2
	ELSE 3
	END
	* 0.2) AS CreditRiskScore
	FROM
	Bank..customers) as crs
ORDER BY CreditRiskScore;

---Average account balance by Region and Job Classification
SELECT Job_Classification, Region,AVG(Balance) as AverageBalance, MAX(Balance) as Maxi, MIN(Balance)
FROM Bank..customers
GROUP BY Job_Classification, Region
ORDER BY AverageBalance;

---Customer Loyalty
SELECT Customer_ID, Customer_Name, Region, Job_Classification, Date_Joined, Balance,
		DaysSinceJoin, AverageBalance
--INTO #customer_loyalty
FROM (
	SELECT Customer_ID, Customer_Name, Region, Job_Classification, Date_Joined, Balance,
			DATEDIFF(DAY, Date_Joined, GETDATE()) AS DaysSinceJoin,
			CASE
				WHEN DATEDIFF(DAY, Date_Joined, GETDATE()) = 0 THEN NULL
				ELSE Balance / DATEDIFF(DAY, Date_Joined, GETDATE())
			END as AverageBalance
	FROM Bank..customers) as sq1
ORDER BY COALESCE(AverageBalance, 0) DESC;


---Ranking customers by their Balance
SELECT Customer_ID,
		Customer_Type
INTO #customer_ranking
FROM
	(
	SELECT Customer_ID,
		Customer_Name,
		Region,
		Job_Classification,
		CASE 
			WHEN Balance >= 100000 THEN 'Platinum'
			WHEN Balance >= 50000 THEN 'Gold'
			WHEN Balance BETWEEN  10000 AND 49999 THEN 'Silver'
			WHEN Balance >= 1000 THEN 'Bronze'
		ELSE 'Ivory'
		END as Customer_Type
	FROM Bank..customers) as v1
ORDER BY Customer_Type;

---TOTAL SUMMARY
SELECT Region, COUNT(*) no_of_customers, AVG(Age)  average_age,
		AVG(Balance) average_balance, MAX(Balance) max_bal, 
		SUM(Balance) total_sum_per_region
FROM Bank..customers
GROUP BY Region
ORDER BY total_sum_per_region;


---Join the results 
SELECT *
INTO UKBankcustomers
FROM
(
	SELECT cl.Customer_ID, 
			Customer_Name, 
			Region, 
			Job_Classification,
			cr.Gender, 
			Age,
			Date_Joined, 
			Balance,
			DaysSinceJoin,  
			AverageBalance,
			crr.Customer_Type
	FROM #customer_loyalty cl
	LEFT JOIN #creditRisk cr
	ON cl.Customer_ID = cr.Customer_ID
	LEFT JOIN #customer_ranking crr
	ON cl.Customer_ID = crr.Customer_ID) as Joined