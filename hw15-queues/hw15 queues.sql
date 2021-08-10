USE WideWorldImporters
-- Секция с настройками БД пропущена
--1. Создание типов сообщений и контракта 

-- Запрос отчета
CREATE MESSAGE TYPE
	WWI_Reports_CustInvoicesCount_Request
VALIDATION=WELL_FORMED_XML;

-- Ответ по запросу на отчет
CREATE MESSAGE TYPE
	WWI_Reports_CustInvoicesCount_Response
VALIDATION=WELL_FORMED_XML; 

GO

--контракт
CREATE CONTRACT WWI_Reports_CustInvoicesCount_Contract
      (WWI_Reports_CustInvoicesCount_Request
         SENT BY INITIATOR,
       WWI_Reports_CustInvoicesCount_Response
         SENT BY TARGET
      );
GO

--2. Очереди и сервисы

CREATE QUEUE WWI_Reports_TargetQueue;


CREATE SERVICE WWI_Reports_CustInvoicesCount_TargetService
       ON QUEUE WWI_Reports_TargetQueue
       (WWI_Reports_CustInvoicesCount_Contract);
GO


CREATE QUEUE WWI_Reports_InitiatorQueue;

CREATE SERVICE WWI_Reports_CustInvoicesCount_InitiatorService
       ON QUEUE WWI_Reports_InitiatorQueue
       (WWI_Reports_CustInvoicesCount_Contract);
GO

--3. Процедура для отправки сообщения

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE Reports.Request_CustInvoicesCount
	@CustomerID INT,
	@FromDate date,
	@ToDate date
AS
BEGIN
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER; --open init dialog
	DECLARE @RequestMessage NVARCHAR(4000); --сообщение, которое будем отправлять
	
	BEGIN TRAN --начинаем транзакцию

	--Prepare the Message  !!!auto generate XML
	SELECT @RequestMessage = (SELECT @CustomerID AS CustomerID,
									 @FromDate AS FromDate,
									 @ToDate AS ToDate
							  FOR XML RAW('ReportRequest'), root('RequestMessage')); 
	
	--Determine the Initiator Service, Target Service and the Contract 
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
		WWI_Reports_CustInvoicesCount_InitiatorService
	TO SERVICE
		'WWI_Reports_CustInvoicesCount_TargetService'
	ON CONTRACT
		WWI_Reports_CustInvoicesCount_Contract
	WITH ENCRYPTION = OFF; 

	--Send the Message
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
		WWI_Reports_CustInvoicesCount_Request(@RequestMessage);
	
	COMMIT TRAN; 
END
GO

--4. Таблица с данными отчета

CREATE SEQUENCE [Sequences].[CustInvoicesCountReportID] 
 AS [int]
 START WITH 1
 INCREMENT BY 1;

 CREATE TABLE Reports.CustInvoicesCount(
	[ReportID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[FromDate] [date] NULL,
	[ToDate] [date] NULL,
	[InvoicesCount] [int] NOT NULL,
 CONSTRAINT [PK_Reports.CustInvoicesCount] PRIMARY KEY CLUSTERED 
(
	[ReportID] ASC
)
) 
GO

ALTER TABLE Reports.CustInvoicesCount ADD  CONSTRAINT [DF_Reports.CustInvoicesCount_ReportID]  DEFAULT (NEXT VALUE FOR [Sequences].[CustInvoicesCountReportID]) FOR [ReportID]
GO


--5. Процедура обработки сообщения
CREATE OR ALTER PROCEDURE Reports.Process_CustInvoicesCount
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER, --идентификатор диалога
			@Message NVARCHAR(4000),--полученное сообщение
			@MessageType Sysname,--тип полученного сообщения
			@ReplyMessage NVARCHAR(4000),--ответное сообщение
			@CustomerID INT,
			@FromDate date,
			@ToDate date,
			@xml XML,
			@ReportID int;
	
	BEGIN TRAN; 

	RECEIVE TOP(1)
		@TargetDlgHandle = Conversation_Handle,
		@Message = Message_Body,
		@MessageType = Message_Type_Name
	FROM dbo.[WWI_Reports_TargetQueue]
	


	SET @xml = CAST(@Message AS XML); -- получаем xml из мессаджа

	--получаем InvoiceID из xml
	SELECT  @CustomerID = Request.Line.value('@CustomerID','INT'),
			@FromDate = Request.Line.value('@FromDate','date'),
			@ToDate = Request.Line.value('@ToDate','date')
	FROM @xml.nodes('/RequestMessage/ReportRequest') as Request(Line);

	DECLARE @RepIdTable table(ReportID int);

	INSERT INTO [Reports].[CustInvoicesCount]
           ([CustomerID]
           ,[FromDate]
           ,[ToDate]
           ,[InvoicesCount])
	OUTPUT  inserted.ReportID INTO @RepIdTable		   
	SELECT	 @CustomerID
			,@FromDate
			,@ToDate
			,(SELECT COUNT(*)
			FROM Sales.Invoices AS Inv
			WHERE Inv.CustomerID = @CustomerID
			AND (@FromDate IS NULL OR @FromDate <= Inv.InvoiceDate)
			AND (@ToDate IS NULL OR @ToDAte >= Inv.InvoiceDate)
			) AS InvoicesCount

	-- Confirm and Send a reply
	IF @MessageType=N'WWI_Reports_CustInvoicesCount_Request'
	BEGIN
		SET @ReplyMessage = (SELECT ReportID FROM @RepIdTable AS Report 
							  FOR XML AUTO, root('ResponseMessage')); 
	
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
			WWI_Reports_CustInvoicesCount_Response(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle;--закроем диалог со стороны таргета
	END 

	COMMIT TRAN;
END;
GO

-- 6. процедура для обработки ответов

CREATE OR ALTER PROCEDURE Reports.GetResponse_CustInvoicesCount
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER, --хэндл диалога
			@Response NVARCHAR(4000),
			@ReportID int,
			@xml XML;

	
	BEGIN TRAN; 

	--получим сообщение из очереди инициатора
		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle = Conversation_Handle
			,@Response = Message_Body
		FROM [dbo].[WWI_Reports_InitiatorQueue]; 

		SET @xml = CAST(@Response AS XML);

		--получаем ReportID из xml
		SELECT  @ReportID = Response.Line.value('@ReportID','INT')
		FROM @xml.nodes('/ResponseMessage/Report') as Response(Line);

		END CONVERSATION @InitiatorReplyDlgHandle; 
		
		SELECT	[ReportID]
			   ,[CustomerID]
			   ,[FromDate]
			   ,[ToDate]
			   ,[InvoicesCount]
		FROM [Reports].[CustInvoicesCount]
		WHERE ReportID = @ReportID;

	COMMIT TRAN; 
END

-- 7. Привязываем процедуры к очередям

ALTER QUEUE [dbo].[WWI_Reports_TargetQueue] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF) 
	, ACTIVATION (   STATUS = ON ,
        PROCEDURE_NAME = [Reports].[Process_CustInvoicesCount], MAX_QUEUE_READERS = 100, EXECUTE AS OWNER) ; 

GO
ALTER QUEUE [dbo].[WWI_Reports_InitiatorQueue] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF)
	, ACTIVATION (  STATUS = ON ,
        PROCEDURE_NAME = [Reports].[GetResponse_CustInvoicesCount], MAX_QUEUE_READERS = 100, EXECUTE AS OWNER) ; 

-- 8. Отправка тестового запроса, проверка отстуствия незакрытых диалогов

exec [Reports].[Request_CustInvoicesCount] @CustomerID = 1, @FromDate = '20130101', @ToDate = '20131011'

SELECT	conversation_handle, 
		is_initiator, 
		s.name as 'local service', 
		far_service, 
		sc.name 'contract', 
		ce.state_desc
FROM sys.conversation_endpoints ce
LEFT JOIN sys.services s
	ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts sc
	ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;
