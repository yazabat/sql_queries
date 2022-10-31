USE SB
GO;


INSERT INTO DimCustomer([CustomerName],[CustomerStatus], [StatusDate])
VALUES ( 'Daniela Huerta', 'OK', '04-10-1988');

INSERT INTO FactInvoice(CustomerID, InvoiceDateKey, InvoiceAmount, InvoiceStatus)
VALUES ( 5, 111222, 1000,'DEACTIVATED');

UPDATE DimCustomer
SET CustomerName='Cinthia Lucar', CustomerStatus='PENDING'
WHERE CustomerID=6
/*Create the following queries: */

--1		List of invoices with customer not found in the Customer Table
-----------------------------------------------------------------------
SELECT * 
	FROM [dbo].[FactInvoice] i
		LEFT JOIN [dbo].[DimCustomer] c
			ON i.CustomerID = c.CustomerID
WHERE c.CustomerID is null

---
SELECT * 
FROM [dbo].[FactInvoice] i
	LEFT JOIN [dbo].[DimCustomer] c
		ON i.CustomerID = c.CustomerID
	WHERE c.CustomerID is null

--2		Number of invoices with customer not found in the customer table, by customer---
--		=>> List oldest and newest invoice data for each customer
----------------------------------------------------------------------------------------
--https://www.youtube.com/watch?v=HYeZKS9F2b0
SELECT i.[InvoiceID], i.[CustomerID] 
	FROM [dbo].[FactInvoice] i
		LEFT JOIN [dbo].[DimCustomer] c
			ON i.CustomerID = c.CustomerID
WHERE i.[InvoiceID] NOT IN (
	SELECT c.[CustomerID] FROM [dbo].[DimCustomer]
	)
GROUP BY i.[CustomerID]
ORDER BY i.[InvoiceDateKey] desc

--2		Number of invoices with customer not found in the customer table, by customer---
--		=>> List oldest and newest invoice data for each customer

WITH PartitionsperCustomerID as
(
SELECT [InvoiceID], CustomerID, [InvoiceDateKey],
ROW_NUMBER() over (order by [CustomerID]) as Rownumber
FROM [dbo].[FactInvoice]
)
SELECT [InvoiceID], i.CustomerID, i.[InvoiceDateKey]
FROM partitionedorders AS P LEFT JOIN [dbo].[DimCustomer] c
ON p.CustomerID = c.CustomerID
WHERE c.CustomerID is null;

-- TROUBLESHOOTING

--3		Write a query that will find the duplicate CustomerIds in table DimCustomer
--		i.e the same Customer ID is present in more than one row
-			--number three you need write a group query by customerid, 
--			and then put a conditional with having for find duplicates, similar to having count(1)>1
-----------------------------------------------------------------------------------------------
SELECT [CustomerName]
FROM [dbo].[DimCustomer] 
GROUP BY [CustomerName]
HAVING COUNT(*)>1

--------------
SELECT C.[CustomerID], ROW_NUMBER() OVER (PARTITION BY [CustomerID] ORDER BY [CustomerID] DESC) AS [ITEMNUMBER] 
		FROM [dbo].[DimCustomer]

WHERE ITEMNUMBER>1



--4		Unpaid amounts by month
--			imagine that the table has a field associated with a payment status and
--			you could do a group query too with a filter for this field


SELECT D.CALENDARMONTHNAME, FI.[InvoiceID]
FROM [dbo].[DimDate] D 
	INNER JOIN [dbo].[FactInvoice] FI ON D.DateKey=FI.InvoiceDateKey
	INNER JOIN [dbo].[DimCustomer] C on FI.CustomerID= C.CustomerID
GROUP BY D.CALENDARMONTHNAME
HAVING FI.InvoiceStatus='DEACTIVATED'


-----------------------------------------------------------------------------------------------
--5		Number of invoices and Total amount per month, by Invoice Status
 --			five you should use a group query by month and status, and in your select 
 --			You would put a count for number of invoices and sum for total amount

SELECT FI.INVOICESTATUS status_invoice, SUM(FI.INVOICEAMOUNT) Total_Amount,
DD.CALENDARMONTHNAME Month_Name, 
RANK() OVER( ORDER BY COUNT(FI.INVOICEID)desc)  number_invoices
FROM FactInvoice FI 
INNER JOIN DimCustomer C ON FI.CustomerID=C.CustomerID
INNER JOIN DimDate DD ON DD.DateKey=FI.InvoiceDateKey 
GROUP BY DD.CALENDARMONTHNAME, FI.INVOICESTATUS;


-----------------------------------------------------------------------------------------------
--6		What is wrong with the code below?

			--Query for listing customers that do not have invoices in april 2020
	
			Select distinct C.CustomerID
				from [dbo].[DimCustomer] C
					left join [dbo].[FactInvoice] i
						on c.CustomerID= i.CustomerID
			where i.InvoiceDateKey between 20200401 and 20200430
			and i.InvoiceID is null

			
			-- In the number 6, your select doesn't indicate the field for extract, 
			-- only say c. and i. , but should say c.name_field or c.* 


-- TROUBLESHOOTING
--7		What is wrong with the code below?

			--Query for finding the customers that have at least one invoice that is 
			OPEN and for those customers, we want to show the customer and ALL their
			invoices	
		
			select c.*, i.*
				from [dbo].[DimCustomer] c
					join [dbo].[FactInvoice] i
						on c.CustomerID=i.CustomerID
			where i.InvoiceStatus = 'OPEN'


			
SELECT c.*, i.*
from [dbo].[DimCustomer] c
		join [dbo].[FactInvoice] i
			on c.CustomerID=i.CustomerID
where i.InvoiceStatus = 'OPEN'
GROUP BY i.CustomerID, i.[InvoiceID]


-- TROUBLESHOOTING
--8		What is wrong with the code below?

		select c.CustomerID, c.CustomerName
				, case when [CustomerStatus] = 'Active' and
				[InvoiceStatus]='Open' then 'Active'
				when [CustomerStatus] = 'Closed' and [InvoiceStatus]='Open' then
				'Incomplete'
				else 'Closed' end as [Status]
				, sum ([InvoiceAmount]) as [Amount]
		from [dbo].[DimCustomer] c
		join [dbo].[FactInvoice] i
		on c.CustomerID=i.CustomerID
		group by c.CustomerID, c.CustomerName
		*********************************************/


-----------------------------------------------------------------------------------
--9		Customers with more than two invoices per month



SELECT C.[CustomerID]
	FROM [dbo].[DimCustomer] C
		INNER JOIN ( SELECT * FROM [dbo].[FactInvoice] FI
					LEFT JOIN [dbo].[DimDate] D 
						ON FI.[InvoiceDateKey] = D.[DateKey]
							GROUP BY MONTHNAME[CalendarMonthName]
							HAVING MONTHNAME[CalendarMonthName]>1) 
					ON on FI.CustomerID= C.CustomerID



--10	Customers with Status = Closed
--		and who have invoices created after the customer became Closed

SELECT c.[CustomerID], i.[InvoiceDateKey] 
	FROM [dbo].[FactInvoice] i
		INNER JOIN [dbo].[DimDate] d on i.[InvoiceDateKey]=d.[DateKey]
		INNER JOIN [dbo].[DimCustomer] c on c.[CustomerID]=i.[CustomerID]
		WHERE i.[InvoiceDateKey]>
			(SELECT [StatusDate] FROM [dbo].[DimCustomer] WHERE [CustomerStatus] = 'CLOSED')


--11. Customer with the highest amount invoiced during any given month
--		=>> list all of the invoices and amounts for that customer,
--		most recent first

SELECT EXTRACT(YEAR FROM d.[DateKey]) AS year, 
d.[CalendarMonthName] AS month, 
i.[CustomerID], 
SUM([InvoiceAmount]) as sum_order_cost, 
MAX(sum_of_order_cost) FROM [dbo].[FactInvoice]

FROM [dbo].[FactInvoice] i
		INNER JOIN [dbo].[DimDate] d on i.[InvoiceDateKey]=d.[DateKey]
		INNER JOIN [dbo].[DimCustomer] c on c.[CustomerID]=i.[CustomerID]

GROUP BY MONTH(date), i.[CustomerID]
order by d.[CalendarMonthName] DESC
LIMIT 1


--12. Customer with at least one month without any invoice 
SELECT i.[CustomerID], DD.CALENDARMONTHNAME
	FROM FactInvoice FI 
		INNER JOIN DimCustomer C ON FI.CustomerID=C.CustomerID
		INNER JOIN DimDate DD ON DD.DateKey=FI.InvoiceDateKey 
WHERE DD.CALENDARMONTHNAME NOT IN
	(SELECT  DD.CALENDARMONTHNAME FROM
		FactInvoice FI 
		INNER JOIN DimCustomer C ON FI.CustomerID=C.CustomerID
		INNER JOIN DimDate DD ON DD.DateKey=FI.InvoiceDateKey 
	)
GROUP BY FI.[CustomerID], DD.CALENDARMONTHNAME;



