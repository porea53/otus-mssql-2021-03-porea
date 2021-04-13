/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT	 Items.StockItemID
		,Items.StockItemName
FROM Warehouse.StockItems as Items
WHERE	Items.StockItemName LIKE '%urgent%' 
	 OR Items.StockItemName LIKE 'Animal%';

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT	 S.SupplierID
		,S.SupplierName 
FROM Purchasing.Suppliers AS S
LEFT JOIN Purchasing.PurchaseOrders AS O ON S.SupplierID = O.SupplierID
WHERE O.SupplierID IS NULL;

/*
	Вопрос: Было бы правильнее изспользовать 
	WHERE O.PurchaseOrderID IS NULL? Это основной ключ он точно не будет NULL.
	Проверил что SupplierID не NULL и взял его, предполагаю что это уменьщит выборку данных из PurchaseOrders
	Проверил что планы запросов имеют одинаковую стоимость
	видимо это тема следующих занятий
*/

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT	DISTINCT 
		 SO.OrderID
		,convert(varchar(12), SO.OrderDate, 104) AS OrderDate
		,DATENAME(month, SO.OrderDate) AS MonthName
		,DATEPART(quarter, SO.OrderDate) AS QuaterNum
		,CEILING(DATEPART(m, SO.OrderDate) / 4.0) AS YearThird
		,C.CustomerName		
FROM Sales.Orders AS SO
JOIN Sales.OrderLines AS SL ON SO.OrderID = SL.OrderID
JOIN Sales.Customers AS C ON SO.CustomerID = C.CustomerID
WHERE (SL.UnitPrice > 100 
   OR  SL.Quantity > 20)
   AND SO.PickingCompletedWhen IS NOT NULL
ORDER BY DATEPART(quarter, SO.OrderDate)
		,CEILING(DATEPART(m, SO.OrderDate) / 4.0)
		,convert(varchar(12), SO.OrderDate, 104);

/* следующий запрос пропускает первую 1000 записей, выводит следующие 100 */

SELECT	DISTINCT 
		 SO.OrderID
		,convert(varchar(12), SO.OrderDate, 104) AS OrderDate
		,DATENAME(month, SO.OrderDate) AS MonthName
		,DATEPART(quarter, SO.OrderDate) AS QuaterNum
		,CEILING(DATEPART(m, SO.OrderDate) / 4.0) AS YearThird
		,C.CustomerName		
FROM Sales.Orders AS SO
JOIN Sales.OrderLines AS SL ON SO.OrderID = SL.OrderID
JOIN Sales.Customers AS C ON SO.CustomerID = C.CustomerID
WHERE (SL.UnitPrice > 100 
   OR  SL.Quantity > 20)
   AND SO.PickingCompletedWhen IS NOT NULL
ORDER BY DATEPART(quarter, SO.OrderDate)
		,CEILING(DATEPART(m, SO.OrderDate) / 4.0)
		,convert(varchar(12), SO.OrderDate, 104)
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY;

/*
	FORMAT(SO.OrderDate, 'MMMM', 'ru-ru') - вариант вывода наименования частей даты в нужной локали
	в сортировке нужна дата в формате ДД.ММ.ГГГГ или значением? если второй вариант то нужно написать без подзапросов?
*/

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT   DM.DeliveryMethodName
		,PO.ExpectedDeliveryDate
        ,S.SupplierName 
        ,CP.FullName AS ContactPerson
FROM Purchasing.PurchaseOrders AS PO 
JOIN Purchasing.Suppliers AS S ON PO.SupplierID = S.SupplierID
JOIN Application.DeliveryMethods AS DM ON PO.DeliveryMethodId = DM.DeliveryMethodId
JOIN Application.People AS CP ON PO.ContactPersonID = CP.PersonId
WHERE PO.DeliveryMethodID IN (8, 10)
  AND PO.ExpectedDeliveryDate BETWEEN '20130101' AND '20130131'
  AND PO.IsOrderFinalized = 1;

/* 
 не стал в WHERE писать DM.DeliveryMethodName IN ('Air Freight','Refrigerated Air Freight'), обошелся константами ID
 надеюсь не нарушил условия задания
 ExpectedDeliveryDate - date поэтому применил between (нет риска когда будут данные вроде 20130331 12:00)
 */


/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10
			 SI.InvoiceID
			,SI.InvoiceDate
			,C.CustomerName
			,P.FullName AS SalesPerson
FROM Sales.Invoices AS SI
JOIN Sales.Customers AS C ON SI.CustomerID = C.CustomerID
JOIN Application.People AS P ON SI.SalespersonPersonID = P.PersonID 
ORDER BY SI.InvoiceDate DESC;

/* из текста задания не понятно - нужно ли было вывести идентификаторы продажи,
	поэтому вывел два поля - дату и ид */

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT DISTINCT
		 C.CustomerID
		,C.CustomerName
		,C.PhoneNumber		
FROM Sales.InvoiceLines AS SIL
JOIN Sales.Invoices AS SI ON SI.InvoiceID = SIL.InvoiceID
JOIN Sales.Customers AS C ON SI.CustomerID = C.CustomerID
JOIN Warehouse.StockItems AS I ON SIL.StockItemID = I.StockItemID
WHERE I.StockItemName = 'Chocolate frogs 250g';

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT YEAR(SI.InvoiceDate) AS [Year],
	   MONTH(SI.InvoiceDate) AS [Month],
	   AVG(SIL.UnitPrice) AS AvgUnitPriceByLine,
	   CASE
			WHEN SUM(SIL.Quantity) != 0 THEN SUM(SIL.Quantity * SIL.UnitPrice) / SUM(SIL.Quantity)
			ELSE 0 
	   END AS AvgUnitPrice,
	   SUM(SIL.Quantity * SIL.UnitPrice) AS Amount
FROM Sales.InvoiceLines AS SIL
JOIN Sales.Invoices AS SI ON SIL.InvoiceID = SI.InvoiceID
GROUP BY YEAR(SI.InvoiceDate),
		 MONTH(SI.InvoiceDate)
ORDER BY YEAR(SI.InvoiceDate),
		 MONTH(SI.InvoiceDate);

/* из текста запроса было непонятно как считать среднюю цену за месяц, поэтому сделал 2 варианта
	-	средняя цена с помощью стандартной функции AVG сумма UnitPrice всех строк деленная на количество строк
	-	средняя цена как сумма всех строк деленная на количество проданного товара. Проверка на нулевое количество 
		сделана на случай появления кредит нот Sales.Invoices.IsCreditNote
		если вдруг в кредит нотах кол-во будет отрицательным теоретически может получиться так что общее кол-во проданного товара не равно 0
	-	т.к. нет более подробных условий как считать продажи  - фильтры по тому же полю IsCreditNote не устанавливались
	-	сортировку добавил по своему усмотрению, надеюсь это не ошибка
*/

/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT YEAR(SI.InvoiceDate) AS [Year],
	   MONTH(SI.InvoiceDate) AS [Month],
	   SUM(SIL.Quantity * SIL.UnitPrice) AS SalesAmount
FROM Sales.InvoiceLines AS SIL
JOIN Sales.Invoices AS SI ON SIL.InvoiceID = SI.InvoiceID
GROUP BY YEAR(SI.InvoiceDate),
		 MONTH(SI.InvoiceDate)
HAVING SUM(SIL.Quantity * SIL.UnitPrice) > 10000
ORDER BY YEAR(SI.InvoiceDate),
		 MONTH(SI.InvoiceDate);

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT	 YEAR(SI.InvoiceDate) AS [Year]
		,MONTH(SI.InvoiceDate) AS [Month]
		,ST.StockItemName
		,SUM(SIL.Quantity * SIL.UnitPrice) AS SalesAmount
		,MIN(SI.InvoiceDate) AS FirstInvoiceDate
		,SUM(SIL.Quantity) AS Quantity
FROM Sales.InvoiceLines AS SIL
JOIN Sales.Invoices AS SI ON SIL.InvoiceID = SI.InvoiceID
JOIN Warehouse.StockItems AS ST ON SIL.StockItemID = ST.StockItemID
GROUP BY  YEAR(SI.InvoiceDate)
		 ,MONTH(SI.InvoiceDate)
		 ,ST.StockItemName
HAVING SUM(SIL.Quantity) < 50
ORDER BY YEAR(SI.InvoiceDate),
		 MONTH(SI.InvoiceDate);

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

/* Задание 8 опционально */

/* насколько я понимаю предполагалось что нужно сделать задание без подзапросов
   но иного способа не нашел кроме как задать константами табличку с периодами.
   Ведь все равно мы должны группировать данные по Sales.Invoices, нам неоткуда взять даты которые не попадут в выборку
   не знаю насколько ее применение тут корректно т.к. ранее требовали выполнять 
   ДЗ без подзапрсов.
   tc
*/

SELECT  Calendar.[Year]
	   ,Calendar.[Month]
	   ,SUM(ISNULL(SIL.Quantity * SIL.UnitPrice, 0)) AS SalesAmount
FROM (
	SELECT 2013 AS [Year], 1 AS [Month] UNION ALL
	SELECT 2013 AS [Year], 2 AS [Month] UNION ALL
	SELECT 2013 AS [Year], 3 AS [Month] UNION ALL
	SELECT 2013 AS [Year], 4 AS [Month] UNION ALL
	SELECT 2013 AS [Year], 5 AS [Month] UNION ALL
	SELECT 2013 AS [Year], 6 AS [Month] UNION ALL
	SELECT 2013 AS [Year], 7 AS [Month] UNION ALL
	SELECT 2013 AS [Year], 8 AS [Month] UNION ALL
	SELECT 2013 AS [Year], 9 AS [Month] UNION ALL
	SELECT 2013 AS [Year], 10 AS [Month] UNION ALL
	SELECT 2013 AS [Year], 11 AS [Month] UNION ALL
	SELECT 2013 AS [Year], 12 AS [Month] UNION ALL
	SELECT 2014 AS [Year], 1 AS [Month] UNION ALL
	SELECT 2014 AS [Year], 2 AS [Month] UNION ALL
	SELECT 2014 AS [Year], 3 AS [Month] UNION ALL
	SELECT 2014 AS [Year], 4 AS [Month] UNION ALL
	SELECT 2014 AS [Year], 5 AS [Month] UNION ALL
	SELECT 2014 AS [Year], 6 AS [Month] UNION ALL
	SELECT 2014 AS [Year], 7 AS [Month] UNION ALL
	SELECT 2014 AS [Year], 8 AS [Month] UNION ALL
	SELECT 2014 AS [Year], 9 AS [Month] UNION ALL
	SELECT 2014 AS [Year], 10 AS [Month] UNION ALL
	SELECT 2014 AS [Year], 11 AS [Month] UNION ALL
	SELECT 2014 AS [Year], 12 AS [Month] UNION ALL
	SELECT 2015 AS [Year], 1 AS [Month] UNION ALL
	SELECT 2015 AS [Year], 2 AS [Month] UNION ALL
	SELECT 2015 AS [Year], 3 AS [Month] UNION ALL
	SELECT 2015 AS [Year], 4 AS [Month] UNION ALL
	SELECT 2015 AS [Year], 5 AS [Month] UNION ALL
	SELECT 2015 AS [Year], 6 AS [Month] UNION ALL
	SELECT 2015 AS [Year], 7 AS [Month] UNION ALL
	SELECT 2015 AS [Year], 8 AS [Month] UNION ALL
	SELECT 2015 AS [Year], 9 AS [Month] UNION ALL
	SELECT 2015 AS [Year], 10 AS [Month] UNION ALL
	SELECT 2015 AS [Year], 11 AS [Month] UNION ALL
	SELECT 2015 AS [Year], 12 AS [Month] UNION ALL
	SELECT 2016 AS [Year], 1 AS [Month] UNION ALL
	SELECT 2016 AS [Year], 2 AS [Month] UNION ALL
	SELECT 2016 AS [Year], 3 AS [Month] UNION ALL
	SELECT 2016 AS [Year], 4 AS [Month] UNION ALL
	SELECT 2016 AS [Year], 5 AS [Month] UNION ALL
	SELECT 2016 AS [Year], 6 AS [Month] UNION ALL
	SELECT 2016 AS [Year], 7 AS [Month] UNION ALL
	SELECT 2016 AS [Year], 8 AS [Month] UNION ALL
	SELECT 2016 AS [Year], 9 AS [Month] UNION ALL
	SELECT 2016 AS [Year], 10 AS [Month] UNION ALL
	SELECT 2016 AS [Year], 11 AS [Month] UNION ALL
	SELECT 2016 AS [Year], 12 AS [Month]
) AS Calendar
LEFT JOIN Sales.Invoices AS SI ON  YEAR(SI.InvoiceDate) = Calendar.[Year] AND MONTH(SI.InvoiceDate) = Calendar.[Month]
LEFT JOIN Sales.InvoiceLines AS SIL ON SI.InvoiceID = SIL.InvoiceID
GROUP BY Calendar.[Year],
		 Calendar.[Month]
HAVING SUM(SIL.Quantity * SIL.UnitPrice) > 10000
ORDER BY Calendar.[Year],
		 Calendar.[Month];

/* Задание 9 опционально */

/* можно было решить аналогично 8 
   но я попробовал иной вариант - через полное пересечение возможных дат Invoices и товаров
   для этого пересечения ищем строки InvoiceLines
   
   возможные проблемы - пробелы в периодах если продаж не было пр всем товарам
*/

SELECT	 YEAR(SI.InvoiceDate) AS [Year]
		,MONTH(SI.InvoiceDate) AS [Month]
		,ST.StockItemID
		,ST.StockItemName
		,SUM(ISNULL(SIL.Quantity * SIL.UnitPrice, 0))  AS SalesAmount
		,MIN(SI_D.InvoiceDate) AS FirstInvoiceDate
		,SUM(ISNULL(SIL.Quantity, 0)) AS Quantity
FROM Sales.Invoices AS SI
JOIN Sales.InvoiceLines AS SIL_M ON SI.InvoiceID = SIL_M.InvoiceID
CROSS JOIN Warehouse.StockItems AS ST
LEFT JOIN Sales.InvoiceLines AS SIL ON SIL.InvoiceLineID = SIL_M.InvoiceLineID AND ST.StockItemID = SIL.StockItemID 
LEFT JOIN Sales.Invoices AS SI_D ON SIL.InvoiceID = SI_D.InvoiceID
GROUP BY  YEAR(SI.InvoiceDate)
		 ,MONTH(SI.InvoiceDate)
		 ,ST.StockItemID
		 ,ST.StockItemName
HAVING SUM(ISNULL(SIL.Quantity, 0)) < 50
ORDER BY YEAR(SI.InvoiceDate),
		 MONTH(SI.InvoiceDate);
