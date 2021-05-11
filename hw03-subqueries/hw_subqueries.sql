/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT	 P.PersonID
		,P.FullName
FROM Application.People AS P 
WHERE		P.IsSalesperson = 1
		AND NOT EXISTS(SELECT * FROM Sales.Invoices AS SI WHERE SI.InvoiceDate = '20150704' AND SI.SalespersonPersonID = P.PersonID);

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

SELECT	 I.StockItemID
		,I.StockItemName
		,I.UnitPrice 
FROM Warehouse.StockItems AS I
WHERE I.UnitPrice = (SELECT MIN(UnitPrice) FROM Warehouse.StockItems);

SELECT	 I.StockItemID
		,I.StockItemName
		,I.UnitPrice 
FROM Warehouse.StockItems AS I
WHERE I.UnitPrice <= ALL(SELECT UnitPrice FROM Warehouse.StockItems);

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

SELECT DISTINCT
       C.CustomerID
	  ,C.CustomerName
FROM Sales.Customers AS C WHERE C.CustomerID IN (SELECT TOP 5 TR.CustomerID FROM Sales.CustomerTransactions AS TR ORDER BY TR.TransactionAmount DESC);

SELECT DISTINCT
       C.CustomerID
	  ,C.CustomerName
FROM Sales.Customers AS C
JOIN (SELECT TOP 5 TR.CustomerID FROM Sales.CustomerTransactions AS TR ORDER BY TR.TransactionAmount DESC) AS T 
	ON T.CustomerID = C.CustomerID;


WITH TopTransactions AS (
	SELECT TOP 5 TR.CustomerID FROM Sales.CustomerTransactions AS TR ORDER BY TR.TransactionAmount DESC
)
SELECT DISTINCT
	   C.CustomerID
	  ,C.CustomerName
FROM Sales.Customers AS C
JOIN TopTransactions AS T ON T.CustomerID = C.CustomerID;

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

WITH TopPriceItems AS (
	SELECT TOP 3 I.StockItemID FROM Warehouse.StockItems AS I ORDER BY I.UnitPrice
),
SalesLines AS (
	SELECT SI.PackedByPersonID, SIL.StockItemID, C.PostalCityID
	FROM Sales.Invoices AS SI
	JOIN Sales.InvoiceLines AS SIL ON SIL.InvoiceID = SI.InvoiceID
	JOIN Sales.Customers AS C ON SI.CustomerID = C.CustomerID
)
SELECT DISTINCT 
	   Cities.CityID
	  ,Cities.CityName
	  ,P.FullName AS PackedBePersonName
FROM TopPriceItems
JOIN SalesLines ON SalesLines.StockItemID = TopPriceItems.StockItemID
JOIN Application.Cities AS Cities ON Cities.CityID = SalesLines.PostalCityID
JOIN Application.People AS P ON P.PersonID = SalesLines.PackedByPersonID;

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

/*
	Запрос выводит дату накладной, номер накладной, полное имя продавца по накладной,
	общую сумму накладной, сумму скомплектованных строк заказа, для текущией накладной.

	В запрос попадают накладные, сумма которых > 27000 (считается сумммированием произведения и количества и цены строк накладной с группировкой по заказам).
	Сортировка по общей сумме накладнйо в порядку убывания.
*/

SET STATISTICS IO, TIME ON;

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC;

--Оптимизация по синтаксису
WITH BigInvoices AS (
	SELECT  SIL.InvoiceId
		   ,SUM(SIL.Quantity * SIL.UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines AS SIL
	GROUP BY SIL.InvoiceId			 
	HAVING SUM(SIL.Quantity * SIL.UnitPrice) > 27000
),
PickedOrders AS (
	SELECT   SOL.OrderID
			,SUM(SOL.PickedQuantity * SOL.UnitPrice) AS TotalSumm
	FROM Sales.OrderLines AS SOL
	JOIN Sales.Orders AS SO ON SO.OrderId = SOL.OrderId
	WHERE SO.PickingCompletedWhen IS NOT NULL
	GROUP BY SOL.OrderID
)
SELECT   BigInvoices.InvoiceID
		,SI.InvoiceDate
		,P.FullName
		,BigInvoices.TotalSumm
		,PickedOrders.TotalSumm AS TotalSummForPickedItems
FROM  BigInvoices
JOIN  Sales.Invoices AS SI ON SI.InvoiceID = BigInvoices.InvoiceID
JOIN Application.People AS P ON P.PersonID = SI.SalespersonPersonID
LEFT JOIN PickedOrders ON PickedOrders.OrderID = SI.OrderID
ORDER BY BigInvoices.TotalSumm DESC
OPTION (MAXDOP 1);

SET STATISTICS IO, TIME OFF;
