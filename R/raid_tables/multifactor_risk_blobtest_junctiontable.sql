USE [FileTableDB]
GO

ALTER TABLE [dbo].[tMultiFactorRiskBlobTest] DROP CONSTRAINT [FK_FileTableDB_ModelTypeID_Betas_ModelType]
GO

/****** Object:  Table [dbo].[tMultiFactorRiskBlobTest]    Script Date: 31/08/2016 14:14:05 ******/
DROP TABLE [dbo].[tMultiFactorRiskBlobTest]
GO

/****** Object:  Table [dbo].[tMultiFactorRiskBlobTest]    Script Date: 31/08/2016 14:14:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[tMultiFactorRiskBlobTest](
	[lTraderID] [bigint] NOT NULL,
	[dtStartDate] [datetime] NOT NULL,
	[dtEndDate] [datetime] NOT NULL,
	[hPathLocator] [hierarchyid] NOT NULL,
	[dtCreatedDate] [datetime] NULL,
	[sCreatedByUserID] [varchar](50) NULL,
 CONSTRAINT [AK_FileTableDB_BlobTest_TraderIDStartEndCreatedUserFactor] UNIQUE NONCLUSTERED 
(
	[lTraderID] ASC,
	[dtStartDate] ASC,
	[dtEndDate] ASC,
	[dtCreatedDate] ASC,
	[sCreatedByUserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[tMultiFactorRiskBlobTest]  WITH CHECK ADD  CONSTRAINT [FK_FileTableDB_PathLocator] FOREIGN KEY([hPathLocator])
REFERENCES [dbo].[ftMultiFactorRiskBlobTest] ([path_locator])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[tMultiFactorRiskBlobTest] CHECK CONSTRAINT [FK_FileTableDB_PathLocator]
GO


