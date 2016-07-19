BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.tMultiFactorRiskMarketStyle
	(
	lModelID bigint NOT NULL,
	lFactorID bigint NOT NULL,
	dblZScore float NULL DEFAULT NULL,
	CONSTRAINT AK_MarketStyle_ModelFactor UNIQUE(lModelID,lFactorID),
	CONSTRAINT FK_ModelID_MarketStyle_ModelType FOREIGN KEY (lModelID) REFERENCES dbo.tMultiFactorRiskModels (lModelID),
	CONSTRAINT FK_FactorID_MarketStyle_Factor FOREIGN KEY (lFactorID) REFERENCES dbo.tMultiFactorRiskFactors (lFactorID)
	)
GO
ALTER TABLE dbo.tMultiFactorRiskMarketStyle SET (LOCK_ESCALATION = TABLE)
GO
COMMIT