/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

set statistics time, io on;

DECLARE @FromInvoiceDate date;

SET @FromInvoiceDate = CAST('20150101' AS date);

WITH Sales AS (
	SELECT SI.InvoiceID, C.CustomerName, SI.InvoiceDate, SIL.UnitPrice * SIL.Quantity AS LineAmount
	FROM Sales.Invoices AS SI
	JOIN Sales.InvoiceLines AS SIL ON SIL.InvoiceID = SI.InvoiceId
	JOIN Sales.Customers AS C ON C.CustomerID = SI.CustomerID
	WHERE SI.InvoiceDate >= @FromInvoiceDate
)
SELECT   S.InvoiceID
		,S.CustomerName
		,S.InvoiceDate
		,SUM(S.LineAmount) AS Amount
		,(SELECT SUM(ST.LineAmount) FROM Sales AS ST WHERE ST.InvoiceDate <= EOMONTH(S.InvoiceDate))
FROM Sales AS S
GROUP BY S.InvoiceID, S.CustomerName, S.InvoiceDate
ORDER BY S.InvoiceDate;



/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

--DECLARE @FromInvoiceDate date;

SET @FromInvoiceDate = CAST('20150101' AS date);

WITH Sales AS (
	SELECT SI.InvoiceID, C.CustomerName, SI.InvoiceDate, SUM(SIL.UnitPrice * SIL.Quantity) AS Amount
	FROM Sales.Invoices AS SI
	JOIN Sales.InvoiceLines AS SIL ON SIL.InvoiceID = SI.InvoiceId
	JOIN Sales.Customers AS C ON C.CustomerID = SI.CustomerID
	WHERE SI.InvoiceDate >= @FromInvoiceDate
	GROUP BY SI.InvoiceID, C.CustomerName, SI.InvoiceDate
)
SELECT   S.InvoiceID
		,S.CustomerName
		,S.InvoiceDate
		,S.Amount
		,SUM(S.Amount) OVER (ORDER BY YEAR(S.InvoiceDate), MONTH(S.InvoiceDate))
FROM Sales AS S
ORDER BY S.InvoiceDate;

set statistics time, io off
/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

DECLARE @FromDate date;
DECLARE @ToDate	date;

SET @FromDate = CAST('20160101' as date);
SET @ToDate = CAST('20161231' as date);

WITH StockMonthlySales AS (
	SELECT SIL.StockItemID
		  ,DATEFROMPARTS(YEAR(SI.InvoiceDate), MONTH(SI.InvoiceDate), 1) AS MonthDate
	      ,SUM(Quantity) AS Qty
FROM Sales.InvoiceLines AS SIL
JOIN Sales.Invoices AS SI ON SI.InvoiceID = SIL.InvoiceID
WHERE SI.InvoiceDate BETWEEN @FromDate AND @ToDate
GROUP BY SIL.StockItemID
		,DATEFROMPARTS(YEAR(SI.InvoiceDate), MONTH(SI.InvoiceDate), 1)
),
StockMonthlyRank AS (
	SELECT   StockItemID
			,MonthDate
			,Qty
			,RANK() OVER (PARTITION BY MonthDate ORDER BY Qty DESC) AS MonthlyVolumesRank
	FROM StockMonthlySales
)
SELECT	 R.StockItemID
		,I.StockItemName
		,R.MonthDate
		,R.MonthlyVolumesRank
		,R.Qty
FROM StockMonthlyRank AS R
JOIN Warehouse.StockItems AS I ON I.StockItemID = R.StockItemID
WHERE R.MonthlyVolumesRank < 3
ORDER BY MonthDate, MonthlyVolumesRank;

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT	 I.StockItemID
		,I.StockItemName
		,I.Brand
		,I.UnitPrice
		,ROW_NUMBER() OVER (PARTITION BY LEFT(I.StockItemName, 1) ORDER BY I.StockItemName) AS AlphabeticRank
		,COUNT(*) OVER () AS TotalItemsCount
		,COUNT(*) OVER (PARTITION BY LEFT(I.StockItemName, 1)) AS AlphabeticItemsCount
		,LEAD(StockItemID) OVER (ORDER BY I.StockItemName) AS NextStockItemId
		,LAG(StockItemID) OVER (ORDER BY I.StockItemName) AS PreviousStockItemId
		,LAG(StockItemName, 2, 'No Items') OVER (ORDER BY I.StockItemName) AS PreviousStockItemId
		,NTILE(30) OVER (ORDER BY I.TypicalWeightPerUnit) AS WeightDistributionGroup
FROM Warehouse.StockItems AS I;

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

/* с оконными функциями */

WITH Sales AS (
	SELECT   SI.InvoiceID
			,SI.InvoiceDate
			,SI.SalespersonPersonID
			,SI.CustomerID
			,SUM(SIL.UnitPrice * SIL.Quantity) AS Amount
	FROM Sales.Invoices AS SI
	JOIN Sales.InvoiceLines AS SIL ON SIL.InvoiceID = SI.InvoiceID
	GROUP BY SI.InvoiceID, SI.InvoiceDate, SI.SalespersonPersonID, SI.CustomerID
),
SalesRanked AS (
	SELECT   Sales.SalespersonPersonID
			,Sales.CustomerID
			,Sales.InvoiceDate
			,Sales.Amount
			,ROW_NUMBER() OVER (PARTITION BY Sales.SalespersonPersonID ORDER BY InvoiceDate DESC, InvoiceID DESC) AS SaleNumberDesc
	FROM Sales	
)
SELECT	 P.PersonID
		,P.FullName
		,C.CustomerID
		,C.CustomerName
		,SalesRanked.InvoiceDate
		,SalesRanked.Amount
FROM SalesRanked
JOIN Application.People AS P ON P.PersonID = SalesRanked.SalespersonPersonID
JOIN Sales.Customers AS C ON C.CustomerID = SalesRanked.CustomerID
WHERE SalesRanked.SaleNumberDesc = 1;

/* без оконных функций */

SELECT P.PersonID
		,P.FullName
		,C.CustomerID
		,C.CustomerName
		,Sales.InvoiceDate
		,Sales.Amount
FROM Application.People AS P
CROSS APPLY (
	SELECT  TOP 1 
	         SI.InvoiceID
			,SI.InvoiceDate
			,SI.CustomerID
			,SUM(SIL.UnitPrice * SIL.Quantity) AS Amount
	FROM Sales.Invoices AS SI
	JOIN Sales.InvoiceLines AS SIL ON SIL.InvoiceID = SI.InvoiceID
	WHERE SI.SalespersonPersonID = P.PersonID
	GROUP BY SI.InvoiceID, SI.InvoiceDate, SI.SalespersonPersonID, SI.CustomerID
	ORDER BY SI.InvoiceDate DESC, SI.InvoiceID DESC
) AS Sales
JOIN Sales.Customers AS C ON C.CustomerID = Sales.CustomerID;

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

/*допустил вольность с интерпретацией задачи - т.к. клиент мог покупать несколько товаров 
у которых одинаковая стоимость в список по 1 клиенту может попадать более 2х товаров.
Т.к. четкого критерия определения как поступить подобным образом не было - оставил так.
*/


/* с оконными функциями */

WITH CustItemSalesRanked AS (
	SELECT SI.CustomerID
		   ,SIL.StockItemID
		   ,SIL.UnitPrice
		   ,DENSE_RANK() OVER (PARTITION BY SI.CustomerID ORDER BY SIL.UnitPrice DESC) AS ItemPriceRank
	FROM Sales.InvoiceLines AS SIL
	JOIN Sales.Invoices AS SI ON SI.InvoiceID = SIL.InvoiceID
)
SELECT DISTINCT
		 C.CustomerID
		,C.CustomerName
		,I.StockItemID
		,I.StockItemName
		,CustItemSalesRanked.UnitPrice
FROM CustItemSalesRanked
JOIN Sales.Customers AS C ON C.CustomerID = CustItemSalesRanked.CustomerID
JOIN Warehouse.StockItems AS I ON I.StockItemID = CustItemSalesRanked.StockItemID
WHERE CustItemSalesRanked.ItemPriceRank <= 2
ORDER BY C.CustomerID ASC, CustItemSalesRanked.UnitPrice DESC;

/*без оконных функций*/

WITH CustItemSales AS (
	SELECT SI.CustomerID
		   ,SIL.StockItemID
		   ,SIL.UnitPrice
	FROM Sales.InvoiceLines AS SIL
	JOIN Sales.Invoices AS SI ON SI.InvoiceID = SIL.InvoiceID
), 
TopCustUnitPrice AS (
	SELECT C.CustomerID
		   ,C.CustomerName
			,MIN(TC.UnitPrice) AS UnitPrice
	FROM Sales.Customers AS C
	CROSS APPLY (
		SELECT DISTINCT TOP 2 S.UnitPrice
		FROM CustItemSales AS S WHERE S.CustomerID = C.CustomerID
		ORDER BY S.UnitPrice DESC
	) AS TC
	GROUP BY C.CustomerID
		   ,C.CustomerName
)
SELECT DISTINCT 
		 P.CustomerID
		,P.CustomerName
		,I.StockItemID
		,I.StockItemName
		,S.UnitPrice
FROM TopCustUnitPrice AS P
JOIN CustItemSales AS S ON P.CustomerID = S.CustomerID AND P.UnitPrice <= S.UnitPrice
JOIN Warehouse.StockItems AS I ON I.StockItemID = S.StockItemID
ORDER BY P.CustomerID ASC, S.UnitPrice DESC;