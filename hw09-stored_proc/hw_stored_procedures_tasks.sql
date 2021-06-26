/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID ( 'Sales.udfMaxInvoiceClient', 'IF' ) IS NOT NULL   
    DROP FUNCTION Sales.udfMaxInvoiceClient;
GO

--Интерпретировал разовую сумму покупки как сумму по отдельному инвойсу
CREATE FUNCTION Sales.udfMaxInvoiceClient()
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT TOP 1 C.CustomerID, C.CustomerName
	FROM Sales.CustomerTransactions AS TR
	JOIN Sales.Customers AS C ON C.CustomerID = TR.CustomerID
	ORDER BY TR.TransactionAmount DESC
);
GO

SELECT CustomerID, CustomerName FROM Sales.udfMaxInvoiceClient();

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

--интерпретировал сумму покупки как общую сумму инвойсов по клиенту

IF OBJECT_ID ( 'Sales.spCustomerInvoicesAmount', 'P' ) IS NOT NULL   
    DROP PROCEDURE Sales.spCustomerInvoicesAmount;
GO

CREATE PROCEDURE Sales.spCustomerInvoicesAmount 
	-- Add the parameters for the stored procedure here
	@CustomerID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT SUM(SIL.ExtendedPrice)  --ExtendedPrice = Quantity * UnitPrice * (1 + TaxRate/100) 
	FROM Sales.Customers AS C
	JOIN Sales.Invoices AS SI ON SI.CustomerID = C.CustomerID
	JOIN Sales.InvoiceLines AS SIL ON SIL.InvoiceID = SI.InvoiceID
	WHERE C.CustomerID = @CustomerId
END;
GO

DECLARE @CustomerID int;
SET @CustomerID = 832;

EXEC Sales.spCustomerInvoicesAmount @CustomerID = @CustomerID;

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

IF OBJECT_ID ( 'Sales.udfCustomerInvoicesAmount', 'FN' ) IS NOT NULL   
    DROP FUNCTION Sales.udfCustomerInvoicesAmount;
GO

--Интерпретировал разовую сумму покупки как сумму по отдельному инвойсу
CREATE FUNCTION Sales.udfCustomerInvoicesAmount
(
	-- Add the parameters for the function here
	@CustomerId int
)
RETURNS decimal(18,2)
AS
BEGIN
	DECLARE @amount decimal(18,2)

	SELECT @amount = SUM(SIL.ExtendedPrice)  --ExtendedPrice = Quantity * UnitPrice * (1 + TaxRate/100) 
	FROM Sales.Customers AS C
	JOIN Sales.Invoices AS SI ON SI.CustomerID = C.CustomerID
	JOIN Sales.InvoiceLines AS SIL ON SIL.InvoiceID = SI.InvoiceID
	WHERE C.CustomerID = @CustomerId

	-- Return the result of the function
	RETURN @amount;
END;
GO



DBCC FREEPROCCACHE WITH NO_INFOMSGS;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
SET NOCOUNT ON;

DECLARE @CustomerID int;
SET @CustomerID = 832;

SET STATISTICS TIME, IO ON

EXEC Sales.spCustomerInvoicesAmount @CustomerID = @CustomerID;

SELECT Sales.udfCustomerInvoicesAmount(@CustomerID);

SET STATISTICS TIME, IO OFF

/* План для скалярной функции просмотреть не получилось, 
Estimated Subtree Cost значительно меньше для функции
CPU Time и Elapsed Time для функции ниже, предполагаю что она работает быстрее
*/


/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

SELECT C.CustomerID
	  ,C.CustomerName
	  ,Sales.udfCustomerInvoicesAmount(C.CustomerID) AS TotalInvoicesAmount
FROM Sales.Customers AS C;

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/

/*

Во всех процедурах использовал бы стандартный READCOMMITTED т.к. в процедурах отсутуют операции по вставке/изменению данных
значит есть риск столкнуться с аномалией Dirty Read от которого мы защитимся указанным уровнем.

*/