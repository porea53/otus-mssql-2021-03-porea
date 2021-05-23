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
DECLARE @MaxInvoiceDate date;
DECLARE @FromInvoiceDate date;
DECLARE @n_recursion int;

SET @FromInvoiceDate = CAST('20150101' AS date);

WITH Sales AS (
	SELECT SI.InvoiceID, C.CustomerName, SI.InvoiceDate, SIL.UnitPrice * SIL.Quantity AS LineAmount
	FROM Sales.Invoices AS SI
	JOIN Sales.InvoiceLines AS SIL ON SIL.InvoiceID = SI.InvoiceId
	JOIN Sales.Customers AS C ON C.CustomerID = SI.CustomerID
	WHERE SI.InvoiceDate >= '20150101'
)
SELECT   S.InvoiceID
		,S.CustomerName
		,S.InvoiceDate
		,SUM(S.LineAmount) AS Amount
		,(SELECT SUM(ST.LineAmount) FROM Sales AS ST WHERE ST.InvoiceDate <= EOMONTH(S.InvoiceDate))
FROM Sales AS S
GROUP BY S.InvoiceID, S.CustomerName, S.InvoiceDate
ORDER BY S.InvoiceDate

SET @MaxInvoiceDate = ISNULL((SELECT MAX(InvoiceDate) FROM Sales.Invoices), CAST(GETDATE() AS date));

WITH Dates(InvoiceDate) AS (
	SELECT @FromInvoiceDate AS InvoiceDate
	UNION ALL
	SELECT DATEADD(dd, 1, Dates.InvoiceDate) FROM Dates
	WHERE Dates.InvoiceDate <= @MaxInvoiceDate
),
Sales AS (
	SELECT T.BMonthDate, T.EMonthDate, SUM(T.Amount) AS Amount
	FROM
	(
		SELECT DATEFROMPARTS(YEAR(SI.InvoiceDate),MONTH(SI.InvoiceDate),1) AS BMonthDate,EOMONTH(SI.InvoiceDate) AS EMonthDate, SUM(SIL.Quantity * SIL.UnitPrice) AS Amount
		FROM Sales.Invoices AS SI
		JOIN Sales.InvoiceLines AS SIL ON SIL.InvoiceID = SI.InvoiceID
		WHERE SI.InvoiceDate >= @FromInvoiceDate
		GROUP BY SI.InvoiceDate
	) AS T
	GROUP BY T.BMonthDate, T.EMonthDate
)
SELECT T.InvoiceDate, SUM(T.Amount) AS [Нарастающий итог по месяцу]
FROM (
	SELECT Dates.InvoiceDate
			,Sales.Amount
	FROM Dates
	LEFT JOIN Sales ON Sales.BMonthDate <= Dates.InvoiceDate
) AS T
GROUP BY T.InvoiceDate
ORDER BY T.InvoiceDate
OPTION (maxrecursion 0);