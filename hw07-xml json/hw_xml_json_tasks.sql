/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/

/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Опционально - если вы знакомы с insert, update, merge, то загрузить эти данные в таблицу Warehouse.StockItems.
Существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 
*/

DECLARE @xmlDocument  xml;

SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'C:\otus-mssql-2021-03-porea\hw07-xml json\StockItems-188-f89807.xml', 
 SINGLE_CLOB)
as data;

DECLARE @docHandle int
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument


MERGE INTO [Warehouse].[StockItems] AS t
USING (
		SELECT	[StockItemName],
				[SupplierID],
				[UnitPackageID],
				[OuterPackageID],
				[QuantityPerOuter], 
				[TypicalWeightPerUnit],
				[LeadTimeDays],
				[IsChillerStock],
				[TaxRate],
				[UnitPrice]
		FROM OPENXML(@docHandle, N'/StockItems/Item')
		WITH ( 
				[StockItemName]			nvarchar(100)			'@Name',
				[SupplierID]			int						'SupplierID',
				[UnitPackageID]			int						'Package/UnitPackageID',
				[OuterPackageID]		int						'Package/OuterPackageID',
				[QuantityPerOuter]		int						'Package/QuantityPerOuter',
				[TypicalWeightPerUnit]	decimal(18, 3)			'Package/TypicalWeightPerUnit',
				[LeadTimeDays]			int						'LeadTimeDays',
				[IsChillerStock]		bit						'IsChillerStock',
				[TaxRate]				decimal(18, 3)			'TaxRate',
				[UnitPrice]				decimal(18, 2)			'UnitPrice'
		)
	) as s
ON (t.StockItemName = s.StockItemName)
WHEN MATCHED THEN UPDATE 
	SET [SupplierID] = s.SupplierID,
		[UnitPackageID] = s.[UnitPackageID],
		[OuterPackageID] = s.[OuterPackageID],
		[QuantityPerOuter] = s.[QuantityPerOuter],
		[TypicalWeightPerUnit] = s.[TypicalWeightPerUnit],
		[LeadTimeDays] = s.[LeadTimeDays],
		[IsChillerStock] = s.[IsChillerStock],
		[TaxRate] = s.[TaxRate],
		[UnitPrice] = s.[UnitPrice]
WHEN NOT MATCHED BY TARGET THEN
	INSERT ([StockItemName],
			[SupplierID],
			[UnitPackageID],
			[OuterPackageID],
			[QuantityPerOuter],
			[TypicalWeightPerUnit],
			[LeadTimeDays],
			[IsChillerStock],
			[TaxRate],
			[UnitPrice],
			[LastEditedBy])
	VALUES ([StockItemName],
			[SupplierID],
			[UnitPackageID],
			[OuterPackageID],
			[QuantityPerOuter],
			[TypicalWeightPerUnit],
			[LeadTimeDays],
			[IsChillerStock],
			[TaxRate],
			[UnitPrice],
			1)
OUTPUT $action, inserted.*;

EXEC sp_xml_removedocument @docHandle;
/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

SELECT Item.StockItemName AS [@Name],
		Item.SupplierID AS [SupplierID],
		Item.[UnitPackageID] AS [Package/UnitPackageID],
		Item.[OuterPackageID] AS [Package/OuterPackageID],
		Item.[QuantityPerOuter] AS [Package/QuantityPerOuter],
		Item.[TypicalWeightPerUnit] AS [Package/TypicalWeightPerUnit],
		Item.[LeadTimeDays] AS [LeadTimeDays],
		Item.[IsChillerStock] AS [IsChillerStock],
		Item.[TaxRate] AS [TaxRate],
		Item.[UnitPrice] AS [UnitPrice]
FROM Warehouse.StockItems AS Item
FOR  XML PATH('Item'), ROOT('StockItems');


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/
SELECT	 Item.StockItemID
		,Item.StockItemName
		,J.*
FROM Warehouse.StockItems AS Item
CROSS APPLY (
	SELECT *
	FROM OPENJSON(Item.CustomFields)
	WITH (
		CountryOfManufacture nvarchar(50)	'$.CountryOfManufacture',
		FirstTag nvarchar(200)				'$.Tags[0]'
	)
) AS J;

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

;WITH StockItemsTags AS ( 
	SELECT	 Item.StockItemID
			,Item.StockItemName
			,TagValues.Val AS TagValue
	FROM Warehouse.StockItems AS Item
	CROSS APPLY (
		SELECT *
		FROM OPENJSON(Item.CustomFields)
		WITH (	
			Tag nvarchar(max)				'$.Tags' AS JSON
		)
	) AS J
	CROSS APPLY (
		SELECT *
		FROM OPENJSON(J.Tag)
		WITH (
			Val nvarchar(200)				'$'
		)
	) AS TagValues
),
StockItemTagAgg AS (
	SELECT I.StockItemID
			,STRING_AGG(I.TagValue,',') AS Tags
	FROM StockItemsTags AS I
	GROUP BY I.StockItemID
)
SELECT SI.StockItemID
		,SI.StockItemName
		,Agg.Tags
FROM StockItemsTags AS SI
JOIN StockItemTagAgg AS Agg ON Agg.StockItemID = SI.StockItemID
WHERE SI.TagValue = 'Vintage';