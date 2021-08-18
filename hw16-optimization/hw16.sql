Данные по оптимизации сохранены в файл Excel

1. Лист "Запрос до изменений" - до начала работы по оригинальному скрипту

1.а. если к исходному запросу добавить option (hash join) то снижается Logical Reads с 45 671 до 13 550.

2. При анализе плана запроса виден кусочер в котором для получения списка полей
CustomerId, BillToCustomerId, InvoiceDate,InvoiceId, OrderId таблицы Sales.Invoices система выполняет Index Seek 
по ключу FK_Sales_Invoices_OrderID. Добавляем в Included Columns этого ключа [InvoiceID],[CustomerID],[BillToCustomerID],[InvoiceDate]

Улучшили Logical Reads с 45 671 до 1 367.

3. Оптимизация логическая. Если она допустима. 

В запросе есть строки :

--JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID 
--JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID 

Причем Trans и ItemTrans потом нигде не используется.
Такая конструкция может использоваться чтобы гарантировать что в запрос попадают выборки длся которых есть соответствующие строки в таблицах.

Пишем 2 запроса

SELECT OrdLines.*
FROM Sales.OrderLines as OrdLines
WHERE NOT EXISTS(SELECT * FROM [Warehouse].[StockItemTransactions] as Trans WHERE Trans.StockItemID = OrdLines.StockItemID) 


 SELECT Inv.*
 FROM Sales.Invoices AS Inv 
 WHERE not exists (SELECT * FROM Sales.CustomerTransactions AS Trans WHERE Trans.InvoiceID = Inv.InvoiceID)

 видим что такое условие выполняется всегда.
 Да и структура базы это подразумевает.
 Предполагаю что от этих условий можно смело избавиться. В жизни конечно нужно уточнить с закачиком.
 Комментируем их.

 значительно уменьшилось время выполнения, снизилось число операций по логическому чтению.

 4. Попытки использования хинтов для использования прочих результатов соединеня (merge, loop) как в целом по заказу так и для отдельных join 
 улучшения не принесли. Проверил отдельные ветви плана на предмет возможной оптимизации по hintам на индексы, также не нашел вариантов по улучшению.
Возможно поле для улучшений есть в использовании временных таблиц. Эту теорию не проверял.




