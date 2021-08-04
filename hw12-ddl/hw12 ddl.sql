-- 1. Скрипт создания базы данных 

CREATE DATABASE [ElectricSchemes]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'electricschemes', FILENAME = N'C:\SQLDATA\electricschemes.mdf' , SIZE = 16MB , FILEGROWTH = 4MB )
 LOG ON 
( NAME = N'electricschemes_log', FILENAME = N'C:\SQLDATA\electricschemes_log.ldf' , SIZE = 8MB , FILEGROWTH = 4MB )

-- 2. Скрипт для создания основных таблиц

USE [ElectricSchemes];

CREATE TABLE [dbo].[Connections]
(
 [ConnectionId]   bigint NOT NULL ,
 [ConnectionType] int NOT NULL ,
 [ProjectID]      int NOT NULL ,
 [ConnectionMode] int NOT NULL 
);

CREATE TABLE [dbo].[Projects]
(
 [ProjectID]   int NOT NULL ,
 [Name]        nvarchar(50) NOT NULL ,
 [Description] nvarchar(200) NULL ,
 [Created]     datetime2(7) NOT NULL ,
 [Modified]    datetime2(7) NULL ,
 [UserID]      int NOT NULL ,
 [FrameItemID] int NOT NULL );

 CREATE TABLE [dbo].[Users]
(
 [UserID]    int NOT NULL ,
 [Name]      nvarchar(50) NOT NULL ,
 [AuthType]  int NOT NULL ,
 [Email]     nvarchar(50) NOT NULL ,
 [Phone]     varchar(20) NULL ,
 [LogonTime] datetime2(7) NULL ,
 [Location]  geography NULL
 );

 CREATE TABLE [dbo].[Items]
(
 [ItemID]      int NOT NULL ,
 [ItemType]    int NOT NULL ,
 [Name]        nvarchar(50) NOT NULL ,
 [Description] nvarchar(200) NULL ,
 [Properties]  nvarchar(max) NULL ,
 [Image]       varbinary(max) NULL  
);

-- 3.Создать первичные и внешние ключи

CREATE SEQUENCE ConnectionSeq
  AS int
  START WITH 1
  INCREMENT BY 1
  CYCLE;

ALTER TABLE dbo.Connections ADD CONSTRAINT
	DF_Connections_ConnectionId DEFAULT NEXT VALUE FOR ConnectionSeq FOR ConnectionId;

ALTER TABLE dbo.Connections ADD CONSTRAINT
	PK_Connections PRIMARY KEY CLUSTERED 
	(
		ConnectionId
	);


CREATE SEQUENCE ItemSeq
  AS int
  START WITH 1
  INCREMENT BY 1
  CYCLE;

ALTER TABLE dbo.Items ADD CONSTRAINT
	DF_Items_ItemId DEFAULT NEXT VALUE FOR ItemSeq FOR ItemId;

ALTER TABLE dbo.Items ADD CONSTRAINT
	PK_Items PRIMARY KEY CLUSTERED 
	(
		ItemId
	);

  CREATE SEQUENCE ProjectSeq
  AS int
  START WITH 1
  INCREMENT BY 1
  CYCLE;

ALTER TABLE dbo.Projects ADD CONSTRAINT
	DF_Projects_ProjectId DEFAULT NEXT VALUE FOR ProjectSeq FOR ProjectId;

ALTER TABLE dbo.Projects ADD CONSTRAINT
	PK_Projects PRIMARY KEY CLUSTERED 
	(
		ProjectId
	);

  CREATE SEQUENCE UserSeq
  AS int
  START WITH 1
  INCREMENT BY 1
  CYCLE;

ALTER TABLE dbo.Users ADD CONSTRAINT
	DF_Users_UserId DEFAULT NEXT VALUE FOR UserSeq FOR UserId;

ALTER TABLE dbo.Users ADD CONSTRAINT
	PK_Users PRIMARY KEY CLUSTERED 
	(
		UserId
	);

-- связи между таблицами
ALTER TABLE dbo.Connections  ADD  CONSTRAINT FK_Connections_Projects FOREIGN KEY(ProjectId)
REFERENCES Projects (ProjectId);

ALTER TABLE dbo.Projects  ADD  CONSTRAINT FK_Projects_Users FOREIGN KEY(UserID)
REFERENCES Users (UserID);

-- 4.Добавить 1-2 индекса

CREATE NONCLUSTERED INDEX UserProjectIdx ON [dbo].[Projects]
(
	[UserID] ASC,
	[ProjectID] ASC
)
INCLUDE([Name],[Description]);

--5. Наложите по одному ограничению в каждой таблице на ввод данных

ALTER TABLE dbo.Items ADD CONSTRAINT CK_Items_ItemType CHECK(ItemType BETWEEN 0 AND 3);

ALTER TABLE dbo.Connections ADD CONSTRAINT CK_Connections_ConnectionMode CHECK((ConnectionType=0 AND ConnectionMode<>1) OR ConnectionType<>0);

ALTER TABLE dbo.Users ADD CONSTRAINT CK_Users_Email CHECK(Email LIKE '_%@__%.__%');

ALTER TABLE dbo.Projects ADD CONSTRAINT DF_Projects_Created DEFAULT GETDATE() FOR Created;