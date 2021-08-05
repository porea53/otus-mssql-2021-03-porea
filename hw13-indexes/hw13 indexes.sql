USE [ElectricSchemes]
GO

--1. индекс для представления списка запросов над которыми работал пользователь 

/****** Object:  Index [PK_UserProjects]    Script Date: 8/6/2021 12:49:18 AM ******/
CREATE NONCLUSTERED INDEX [UserIdLastAccesTimeIdx] ON [dbo].[UserProjects]
(
	[UserID] ASC,
	[LastAccessTime] DESC
)
INCLUDE (
	[RelationType]
);

/* Индекс для использования в запросе
выводящим список проектов над которыми работал пользовавтель

DECLARE @UserID int
SET @UserID = 52

SELECT UP.RelationType,
		UP.LastAccessTime,
		P.ProjectID,
		P.Name,
		P.Description
FROM dbo.UserProjects AS UP
JOIN dbo.Projects AS P ON P.ProjectID = UP.ProjectID
WHERE UP.UserID = 52
ORDER BY UP.LastAccessTime DESC

Плаг запроса демонстрирует использование Index Seek по созданному ключу
*/


--2. Запрос для поиска продуктов с наименьшей стоимостью по проекту
/*
DECLARE @ProjectID int
SET @ProjectID = 2

SELECT PrI.ItemID,
		I.Name AS ItemName,
		I.ItemType,
		PMin.Name AS ProductName,
		PMin.PartNumber,
		PMin.BrandID,
		PMin.AveragePrice
FROM dbo.ProjectItems AS PrI
JOIN dbo.Items AS I ON I.ItemID = PrI.ItemID
OUTER APPLY ( 
	SELECT TOP 1 P.Name,
				 P.PartNumber,
				 P.BrandID,
				 P.AveragePrice
	FROM dbo.Products AS P WHERE P.ItemID = I.ItemID
	ORDER BY P.AveragePrice
) AS PMin
WHERE PrI.ProjectID = @ProjectID
*/

CREATE NONCLUSTERED INDEX [ItemIDAveragePriceIdx] ON [dbo].[Products]
(
	[ItemID] ASC,
	[AveragePrice] ASC
)
INCLUDE([Name],[PartNumber],[BrandID]);

/*
план запроса отмечает использование индекса
*/