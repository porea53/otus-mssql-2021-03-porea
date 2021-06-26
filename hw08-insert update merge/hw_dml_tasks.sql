/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

INSERT INTO [Purchasing].[Suppliers]
           ([SupplierID]
           ,[SupplierName]
           ,[SupplierCategoryID]
           ,[PrimaryContactPersonID]
           ,[AlternateContactPersonID]
           ,[DeliveryMethodID]
           ,[DeliveryCityID]
           ,[PostalCityID]
           ,[PaymentDays]
           ,[PhoneNumber]
           ,[FaxNumber]
           ,[WebsiteURL]
           ,[DeliveryAddressLine1]
           ,[DeliveryPostalCode]
           ,[PostalAddressLine1]
           ,[PostalPostalCode]
           ,[LastEditedBy])
     VALUES
           (NEXT VALUE FOR Sequences.SupplierId --SupplierID
           ,'Supplier HW-08 02'					--SupplierName
           ,1									--SupplierCategoryID
           ,2									--PrimaryContactPersonID
           ,3									--AlternateContactPersonID
           ,1									--DeliveryMethodID
           ,1									--DeliveryCityID
           ,1									--PostalCityID
           ,5									--PaymentDays
           ,'(335) 555-0103'					--PhoneNumber
           ,'(335) 555-0103'					--FaxNumber
           ,'http://www.supplier01.com'			--WebsiteURL
           ,'220 Supplier 01 Road'				--DeliveryAddressLine1
           ,'00001'								--DeliveryPostalCode
           ,'PO Box 0001'						--PostalAddressLine1
           ,'00001'								--[PostalPostalCode]
           ,'2'),
		   (NEXT VALUE FOR Sequences.SupplierId --SupplierID
           ,'Supplier HW-08 01'					--SupplierName
           ,2									--SupplierCategoryID
           ,3									--PrimaryContactPersonID
           ,4									--AlternateContactPersonID
           ,2									--DeliveryMethodID
           ,11									--DeliveryCityID
           ,11									--PostalCityID
           ,5									--PaymentDays
           ,'(345) 555-0103'					--PhoneNumber
           ,'(345) 555-0103'					--FaxNumber
           ,'http://www.supplier02.com'			--WebsiteURL
           ,'220 Supplier 02 Road'				--DeliveryAddressLine1
           ,'00002'								--DeliveryPostalCode
           ,'PO Box 0002'						--PostalAddressLine1
           ,'00002'								--[PostalPostalCode]
           ,'2'),
		   (NEXT VALUE FOR Sequences.SupplierId --SupplierID
           ,'Supplier HW-08 03'					--SupplierName
           ,3									--SupplierCategoryID
           ,4									--PrimaryContactPersonID
           ,5									--AlternateContactPersonID
           ,3									--DeliveryMethodID
           ,21									--DeliveryCityID
           ,21									--PostalCityID
           ,20									--PaymentDays
           ,'(355) 555-0103'					--PhoneNumber
           ,'(355) 555-0103'					--FaxNumber
           ,'http://www.supplier03.com'			--WebsiteURL
           ,'220 Supplier 03 Road'				--DeliveryAddressLine1
           ,'00003'								--DeliveryPostalCode
           ,'PO Box 0003'						--PostalAddressLine1
           ,'00003'								--[PostalPostalCode]
           ,'2'),
		   (NEXT VALUE FOR Sequences.SupplierId --SupplierID
           ,'Supplier HW-08 04'					--SupplierName
           ,4									--SupplierCategoryID
           ,5									--PrimaryContactPersonID
           ,6									--AlternateContactPersonID
           ,4									--DeliveryMethodID
           ,31									--DeliveryCityID
           ,31									--PostalCityID
           ,15									--PaymentDays
           ,'(375) 555-0103'					--PhoneNumber
           ,'(375) 555-0103'					--FaxNumber
           ,'http://www.supplier04.com'			--WebsiteURL
           ,'220 Supplier 04 Road'				--DeliveryAddressLine1
           ,'00004'								--DeliveryPostalCode
           ,'PO Box 0004'						--PostalAddressLine1
           ,'00004'								--[PostalPostalCode]
           ,'2'),
		   (NEXT VALUE FOR Sequences.SupplierId --SupplierID
           ,'Supplier HW-08 05'					--SupplierName
           ,5									--SupplierCategoryID
           ,6									--PrimaryContactPersonID
           ,7									--AlternateContactPersonID
           ,5									--DeliveryMethodID
           ,41									--DeliveryCityID
           ,41									--PostalCityID
           ,51									--PaymentDays
           ,'(385) 555-0103'					--PhoneNumber
           ,'(385) 555-0103'					--FaxNumber
           ,'http://www.supplier05.com'			--WebsiteURL
           ,'220 Supplier 05 Road'				--DeliveryAddressLine1
           ,'00005'								--DeliveryPostalCode
           ,'PO Box 0005'						--PostalAddressLine1
           ,'00005'								--[PostalPostalCode]
           ,'2');

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM Purchasing.Suppliers
	WHERE SupplierName = 'Supplier HW-08 05'; 


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE S
	SET S.PostalPostalCode = '00010'
FROM Purchasing.Suppliers AS S
WHERE S.SupplierName = 'Supplier HW-08 04';

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/
DECLARE @id1 int;
DECLARE @id2 int;
SET @id1 = 200;
SET @id2 = 401;

IF OBJECT_ID('tempdb..#TmpCustomers') IS NOT NULL DROP TABLE #TmpCustomers

SELECT * 
INTO #TmpCustomers
FROM 
(
SELECT [CustomerID]
      ,[CustomerName] + ' Updated' AS [CustomerName]
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
      ,[ValidFrom]
      ,[ValidTo]
  FROM [Sales].[Customers]
  WHERE CustomerID = @id1
  UNION ALL
  SELECT NULL AS [CustomerID]
      ,[CustomerName] + ' COPY'  AS [CustomerName]
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
      ,[ValidFrom]
      ,[ValidTo]
  FROM [Sales].[Customers]
  WHERE CustomerID = @id2
) AS T;

MERGE Sales.Customers AS dst
USING (SELECT [CustomerID]
			 ,[CustomerName]
			 ,[BillToCustomerID]
		     ,[CustomerCategoryID]
			 ,[BuyingGroupID]
			 ,[PrimaryContactPersonID]
			 ,[AlternateContactPersonID]
			 ,[DeliveryMethodID]
			 ,[DeliveryCityID]
			 ,[PostalCityID]
			 ,[CreditLimit]
			 ,[AccountOpenedDate]
			 ,[StandardDiscountPercentage]
			 ,[IsStatementSent]
			 ,[IsOnCreditHold]
			 ,[PaymentDays]
			 ,[PhoneNumber]
			 ,[FaxNumber]
			 ,[DeliveryRun]
			 ,[RunPosition]
			 ,[WebsiteURL]
			 ,[DeliveryAddressLine1]
			 ,[DeliveryAddressLine2]
			 ,[DeliveryPostalCode]
			 ,[DeliveryLocation]
			 ,[PostalAddressLine1]
			 ,[PostalAddressLine2]
			 ,[PostalPostalCode]
			 ,[LastEditedBy]
		FROM #TmpCustomers) AS src
ON (src.CustomerID = dst.CustomerID)
WHEN MATCHED THEN
	UPDATE SET CustomerName = src.CustomerName
WHEN NOT MATCHED 
	THEN INSERT (
			  [CustomerName]
			 ,[BillToCustomerID]
		     ,[CustomerCategoryID]
			 ,[BuyingGroupID]
			 ,[PrimaryContactPersonID]
			 ,[AlternateContactPersonID]
			 ,[DeliveryMethodID]
			 ,[DeliveryCityID]
			 ,[PostalCityID]
			 ,[CreditLimit]
			 ,[AccountOpenedDate]
			 ,[StandardDiscountPercentage]
			 ,[IsStatementSent]
			 ,[IsOnCreditHold]
			 ,[PaymentDays]
			 ,[PhoneNumber]
			 ,[FaxNumber]
			 ,[DeliveryRun]
			 ,[RunPosition]
			 ,[WebsiteURL]
			 ,[DeliveryAddressLine1]
			 ,[DeliveryAddressLine2]
			 ,[DeliveryPostalCode]
			 ,[DeliveryLocation]
			 ,[PostalAddressLine1]
			 ,[PostalAddressLine2]
			 ,[PostalPostalCode]
			 ,[LastEditedBy])
	VALUES (
			  src.[CustomerName]
			 ,src.[BillToCustomerID]
		     ,src.[CustomerCategoryID]
			 ,src.[BuyingGroupID]
			 ,src.[PrimaryContactPersonID]
			 ,src.[AlternateContactPersonID]
			 ,src.[DeliveryMethodID]
			 ,src.[DeliveryCityID]
			 ,src.[PostalCityID]
			 ,src.[CreditLimit]
			 ,src.[AccountOpenedDate]
			 ,src.[StandardDiscountPercentage]
			 ,src.[IsStatementSent]
			 ,src.[IsOnCreditHold]
			 ,src.[PaymentDays]
			 ,src.[PhoneNumber]
			 ,src.[FaxNumber]
			 ,src.[DeliveryRun]
			 ,src.[RunPosition]
			 ,src.[WebsiteURL]
			 ,src.[DeliveryAddressLine1]
			 ,src.[DeliveryAddressLine2]
			 ,src.[DeliveryPostalCode]
			 ,src.[DeliveryLocation]
			 ,src.[PostalAddressLine1]
			 ,src.[PostalAddressLine2]
			 ,src.[PostalPostalCode]
			 ,src.[LastEditedBy])
OUTPUT deleted.*, $action, inserted.*;
		
	



/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

-- C:\otus-mssql-2021-03-porea\hw08-insert update merge\Data

exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Customers" out  "C:\otus-mssql-2021-03-porea\hw08-insert update merge\Data\Customers.txt" -T -w -t; -S MSSQL-DEV\SQL2017'

drop table if exists [Sales].[Customers_BulkCopy]

CREATE TABLE [Sales].[Customers_BulkCopy](
	[CustomerID] [int] NOT NULL,
	[CustomerName] [nvarchar](100) NOT NULL,
	[BillToCustomerID] [int] NOT NULL,
	[CustomerCategoryID] [int] NOT NULL,
	[BuyingGroupID] [int] NULL,
	[PrimaryContactPersonID] [int] NOT NULL,
	[AlternateContactPersonID] [int] NULL,
	[DeliveryMethodID] [int] NOT NULL,
	[DeliveryCityID] [int] NOT NULL,
	[PostalCityID] [int] NOT NULL,
	[CreditLimit] [decimal](18, 2) NULL,
	[AccountOpenedDate] [date] NOT NULL,
	[StandardDiscountPercentage] [decimal](18, 3) NOT NULL,
	[IsStatementSent] [bit] NOT NULL,
	[IsOnCreditHold] [bit] NOT NULL,
	[PaymentDays] [int] NOT NULL,
	[PhoneNumber] [nvarchar](20) NOT NULL,
	[FaxNumber] [nvarchar](20) NOT NULL,
	[DeliveryRun] [nvarchar](5) NULL,
	[RunPosition] [nvarchar](5) NULL,
	[WebsiteURL] [nvarchar](256) NOT NULL,
	[DeliveryAddressLine1] [nvarchar](60) NOT NULL,
	[DeliveryAddressLine2] [nvarchar](60) NULL,
	[DeliveryPostalCode] [nvarchar](10) NOT NULL,
	[DeliveryLocation] [geography] NULL,
	[PostalAddressLine1] [nvarchar](60) NOT NULL,
	[PostalAddressLine2] [nvarchar](60) NULL,
	[PostalPostalCode] [nvarchar](10) NOT NULL,
	[LastEditedBy] [int] NOT NULL,
	[ValidFrom] [datetime2](7),
	[ValidTo] [datetime2](7)
 CONSTRAINT [PK_Sales_Customers_BulkCopy] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [USERDATA],
 CONSTRAINT [UQ_Sales_Customers_CustomerName_BulkCopy] UNIQUE NONCLUSTERED 
(
	[CustomerName] ASC
) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
) ON [USERDATA]


BULK INSERT [Sales].[Customers_BulkCopy]
				   FROM "C:\otus-mssql-2021-03-porea\hw08-insert update merge\Data\Customers.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						ROWTERMINATOR ='\n',
						FIELDTERMINATOR = ';',
						KEEPNULLS,
						TABLOCK        
					  );

select Count(*) from [Sales].[Customers_BulkCopy];

--для удаления таблицы после импорта
drop table [Sales].[Customers_BulkCopy];