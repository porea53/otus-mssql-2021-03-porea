/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

WITH Branches AS (
	SELECT C.CustomerId,
		   SUBSTRING(C.CustomerName, PATINDEX('%(%)',C.CustomerName) + 1,LEN(C.CustomerName) - PATINDEX('%(%)',C.CustomerName) - 1) AS Branch
	FROM Sales.Customers AS C
	WHERE C.CustomerID BETWEEN 2 AND 6
)
SELECT FORMAT(PVT.InvoiceMonth, 'dd.MM.yyyy') AS InvoiceMonth,
		PVT.[Gasport, NY],
		PVT.[Jessie, ND],
		PVT.[Medicine Lodge, KS],
		PVT.[Peeples Valley, AZ],
		PVT.[Sylvanite, MT]
FROM
(
	SELECT DATEFROMPARTS(YEAR(SI.InvoiceDate), MONTH(SI.InvoiceDate), 1) AS InvoiceMonth,
	B.Branch,
	SI.InvoiceID
	FROM Sales.Invoices AS SI
	JOIN Branches AS B ON B.CustomerID = SI.CustomerID
) AS InvoicesCount
PIVOT ( COUNT(InvoiceId)
FOR Branch IN ([Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Jessie, ND]))
AS PVT
ORDER BY PVT.InvoiceMonth;

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/
SELECT U.CustomerName, U.AddressLine
FROM 
(
	SELECT C.CustomerName, C.DeliveryAddressLine1, C.DeliveryAddressLine2, C.PostalAddressLine1, C.PostalAddressLine2
	FROM Sales.Customers AS C
	WHERE C.CustomerName LIKE '%Tailspin Toys%'
) AS P
UNPIVOT
(
	AddressLine FOR AddressType IN
		(DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)
) as U;


/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/
SELECT	 U.CountryID
		,U.CountryName
		,U.Code
FROM
(
	SELECT  CountryId
		   ,CountryName
		   ,CAST(IsoAlpha3Code AS nvarchar(10)) AS IsoAlpha3Code
		   ,CAST(IsoNumericCode AS nvarchar(10)) AS IsoNumericCode
	FROM Application.Countries
) AS P
UNPIVOT
(
	Code FOR CodeType IN
		(IsoAlpha3Code, IsoNumericCode)
) AS U;
/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

--Вариант 1 - если нужно было отобразить 2 строки с наибольшей цено товара по клиенту

SELECT C.CustomerID
		,C.CustomerName
		,S.StockItemID
		,S.UnitPrice
		,S.InvoiceDate
FROM Sales.Customers AS C
OUTER APPLY (
	SELECT TOP 2 
			 SI.InvoiceDate
			,SIL.UnitPrice
			,SIL.StockItemID
	FROM Sales.InvoiceLines AS SIL
	JOIN Sales.Invoices AS SI ON SI.InvoiceID = SIL.InvoiceID
	WHERE C.CustomerID = SI.CustomerID
	ORDER BY SIL.UnitPrice DESC
) AS S;
			
--Вариант 2 - если нужно было отобразить 2 товара с наибольшими ценами, для них взята первая дата покупки c макс. ценой
--необходимость подзапроса по дате накладной обусловлена предположением о возможности продаж одного и того-же товара одому клиенту
--по разной цене
WITH InvoiceLines AS (
	SELECT   SI.InvoiceDate
			,SI.CustomerID
			,SIL.StockItemID
			,SIL.UnitPrice
	FROM Sales.Invoices AS SI
	JOIN Sales.InvoiceLines AS SIL ON SI.InvoiceID = SIL.InvoiceID
)
SELECT C.CustomerID
		,C.CustomerName
		,S.StockItemID
		,S.UnitPrice
		,S.InvoiceDate
FROM Sales.Customers AS C
OUTER APPLY (
	SELECT TOP 2 
			 (
				SELECT MIN(InvoiceDate)
				FROM InvoiceLines AS IL
				WHERE IL.StockItemID =T.StockItemID 
				  AND IL.UnitPrice = T.UnitPrice 
				  AND IL.CustomerID = C.CustomerID
			 ) AS InvoiceDate
			,T.UnitPrice
			,T.StockItemID
	FROM (
	SELECT SIL.StockItemID,
		MAX(SIL.UnitPrice) AS UnitPrice

	FROM Sales.InvoiceLines AS SIL
	JOIN Sales.Invoices AS SI ON SI.InvoiceID = SIL.InvoiceID
	WHERE C.CustomerID = SI.CustomerID
	GROUP BY SIL.StockItemID
	) AS T
	ORDER BY T.UnitPrice DESC
) AS S;