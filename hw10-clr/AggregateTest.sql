USE [WideWorldImporters]
GO

--Проверка использования аггрегата для вычисления средней цены продажи

SELECT YEAR(SI.InvoiceDate) AS InvoiceYear,
	AVG(SIL.UnitPrice*(1+SIL.TaxRate/100)) AS DefaultAvgPrice,
	SUM(SIL.Quantity) AS QtyTotal,
	SUM(SIL.ExtendedPrice) AS AmountTotal,
	SUM(SIL.ExtendedPrice)/SUM(SIL.Quantity) AS AvgPriceSQL,
	dbo.AvgPrice(SIL.ExtendedPrice, SIL.Quantity) AS AvgPriceCLR
FROM [Sales].[InvoiceLines] AS SIL
  JOIN Sales.Invoices AS SI ON SI.InvoiceID = SIL.InvoiceID
  GROUP BY YEAR(SI.InvoiceDate)
  HAVING SUM(SIL.Quantity) <> 0


