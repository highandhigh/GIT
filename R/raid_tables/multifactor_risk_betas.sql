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
CREATE TABLE dbo.tMultiFactorRiskBetas
	(
	lModelTypeID bigint NOT NULL,
	dtDate datetime NOT NULL,
	lInstrumentID bigint NOT NULL,
	lFactorID bigint NOT NULL,
	dblBeta float NULL DEFAULT NULL,
	CONSTRAINT AK_ModelDateInstrumentFactor UNIQUE(lModelTypeID,dtDate,lInstrumentID,lFactorID),
	CONSTRAINT FK_ModelTypeID_Betas_ModelType FOREIGN KEY (lModelTypeID) REFERENCES dbo.tMultiFactorRiskModelTypes (lModelTypeID),
	CONSTRAINT FK_FactorID_Betas_Factor FOREIGN KEY (lFactorID) REFERENCES dbo.tMultiFactorRiskFactors (lFactorID)
	)

GO
ALTER TABLE dbo.tMultiFactorRiskBetas SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
