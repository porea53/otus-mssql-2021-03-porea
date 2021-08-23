USE WideWorldImporters
/* 1. Выбрать таблицу для секционирования
Возьмем запрос и выберем таблицы с мак количеством строк
*/

SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows AS RowCounts
    
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255
	AND p.partition_number = 1
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    p.rows desc, t.name


/* Выберем таблицу Sales.OrderLines, предположим что ее чаще всего используют совместно с Sales.Orders
и секционируем ее по OrderId
*/

/* 2 копии таблицы + анализ диапазонов номеров*/

SELECT [OrderLineID]
      ,[OrderID]
      ,[StockItemID]
      ,[Description]
      ,[PackageTypeID]
      ,[Quantity]
      ,[UnitPrice]
      ,[TaxRate]
      ,[PickedQuantity]
      ,[PickingCompletedWhen]
      ,[LastEditedBy]
      ,[LastEditedWhen]
INTO Sales.OrderLines_Copy
  FROM [Sales].[OrderLines];

SELECT [OrderLineID]
      ,[OrderID]
      ,[StockItemID]
      ,[Description]
      ,[PackageTypeID]
      ,[Quantity]
      ,[UnitPrice]
      ,[TaxRate]
      ,[PickedQuantity]
      ,[PickingCompletedWhen]
      ,[LastEditedBy]
      ,[LastEditedWhen]
INTO Sales.OrderLines_CopyS
  FROM [Sales].[OrderLines];

SELECT YEAR(SO.OrderDate) AS OrderDateYear, MIN(SO.OrderID)
FROM Sales.Orders AS SO
GROUP BY YEAR(SO.OrderDate)
ORDER BY YEAR(SO.OrderDate);

/* 3. создаем файловую группу, файл БД, функцию и схему партиционирования*/

--создадим файловую группу
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [OrderIdData]
GO

--добавляем файл БД
ALTER DATABASE [WideWorldImporters] ADD FILE 
( NAME = N'OrderIdData', FILENAME = N'C:\SQLDATA\OrderIdData.ndf' , 
SIZE = 100MB , FILEGROWTH = 64MB ) TO FILEGROUP [OrderIdData];
GO

--функция партиционирования
CREATE PARTITION FUNCTION [PF_OrderId](INT) AS RANGE RIGHT FOR VALUES
(1, 19443, 40642, 63968);																																																									
GO

-- схема партиционирования
CREATE PARTITION SCHEME [PS_OrderId] AS PARTITION [PF_OrderId] 
ALL TO ([OrderIdData]);
GO

/* 4. Создаем кластеные ключи для таблиц копий с секционированием и без
*/

ALTER TABLE Sales.OrderLines_Copy ADD CONSTRAINT PK_Sales_OrderLines_Copy
PRIMARY KEY CLUSTERED  (OrderID, OrderLineID);
GO

ALTER TABLE Sales.OrderLines_CopyS ADD CONSTRAINT PK_Sales_OrderLines_CopyS
PRIMARY KEY CLUSTERED  (OrderID, OrderLineID)
ON [PS_OrderId]([OrderID]);
GO

/* 5. Проверка эффекта от секционирования при прочих равных

- выборка по конкретному заказу*/

SET STATISTICS TIME, IO ON

SELECT [OrderLineID]
      ,[OrderID]
      ,[StockItemID]
      ,[Description]
      ,[PackageTypeID]
      ,[Quantity]
      ,[UnitPrice]
      ,[TaxRate]
      ,[PickedQuantity]
      ,[PickingCompletedWhen]
      ,[LastEditedBy]
      ,[LastEditedWhen]
  FROM [Sales].[OrderLines_Copy]
  WHERE OrderID = 52000;

  SELECT [OrderLineID]
      ,[OrderID]
      ,[StockItemID]
      ,[Description]
      ,[PackageTypeID]
      ,[Quantity]
      ,[UnitPrice]
      ,[TaxRate]
      ,[PickedQuantity]
      ,[PickingCompletedWhen]
      ,[LastEditedBy]
      ,[LastEditedWhen]
  FROM [Sales].[OrderLines_CopyS]
  WHERE OrderID = 52000;

SET STATISTICS TIME, IO OFF

/* нет разницы */

SET STATISTICS TIME, IO ON

SELECT SOL.[StockItemID]
	  ,SI.StockItemName
      ,SUM(SOL.[Quantity]) AS Quantity
      ,SUM(SOL.[UnitPrice] * SOL.[Quantity]) AS Amount
  FROM [Sales].[OrderLines_Copy] AS SOL
  JOIN Sales.Orders AS SO ON SO.OrderID = SOL.OrderID
  JOIN Warehouse.StockItems AS SI ON SI.StockItemID = SOL.StockItemID
  WHERE SO.OrderDate BETWEEN '20140701' AND '20141030'
  GROUP BY SOL.StockItemID, SI.StockItemName

SELECT SOL.[StockItemID]
	  ,SI.StockItemName
      ,SUM(SOL.[Quantity]) AS Quantity
      ,SUM(SOL.[UnitPrice] * SOL.[Quantity]) AS Amount
  FROM [Sales].[OrderLines_CopyS] AS SOL
  JOIN Sales.Orders AS SO ON SO.OrderID = SOL.OrderID
  JOIN Warehouse.StockItems AS SI ON SI.StockItemID = SOL.StockItemID
  WHERE SO.OrderDate BETWEEN '20140701' AND '20141030'
  GROUP BY SOL.StockItemID, SI.StockItemName

SET STATISTICS TIME, IO OFF

/* во втором примере с чтением диапазона данных логических операций чтения меньше */

SET STATISTICS TIME, IO ON

SELECT SOL.[StockItemID]
	  ,SI.StockItemName
      ,SUM(SOL.[Quantity]) AS Quantity
      ,SUM(SOL.[UnitPrice] * SOL.[Quantity]) AS Amount
  FROM [Sales].[OrderLines_Copy] AS SOL
  JOIN Sales.Orders AS SO ON SO.OrderID = SOL.OrderID
  JOIN Warehouse.StockItems AS SI ON SI.StockItemID = SOL.StockItemID
  WHERE SOL.OrderID BETWEEN 44000 AND 51000
  GROUP BY SOL.StockItemID, SI.StockItemName

SELECT SOL.[StockItemID]
	  ,SI.StockItemName
      ,SUM(SOL.[Quantity]) AS Quantity
      ,SUM(SOL.[UnitPrice] * SOL.[Quantity]) AS Amount
  FROM [Sales].[OrderLines_CopyS] AS SOL
  JOIN Sales.Orders AS SO ON SO.OrderID = SOL.OrderID
  JOIN Warehouse.StockItems AS SI ON SI.StockItemID = SOL.StockItemID
  WHERE SOL.OrderID BETWEEN 44000 AND 51000
  GROUP BY SOL.StockItemID, SI.StockItemName

SET STATISTICS TIME, IO OFF

/* в третьем примере одинаковое число операций логического чтения
  план запроса для секционированной таблицы чуть дешевле
  
  Вывод - выйгрыш можно будет увидеть на больших таблицах после тщательного подбора ключа.
*/