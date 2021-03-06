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
CREATE TABLE dbo.tMultiFactorRiskFactorCorrelation
	(
	lModelID bigint NOT NULL,
	lFactorCoupleID bigint NOT NULL,
	dblVariance float NULL DEFAULT NULL,
	CONSTRAINT AK_FactorCorrelation_ModelID_FactorCoupleID UNIQUE(lModelID,lFactorCoupleID),
	CONSTRAINT FK_FactorCorrelation_ModelID_Models FOREIGN KEY (lModelID) REFERENCES dbo.tMultiFactorRiskModels (lModelID),
	CONSTRAINT FK_FactorCorrelation_FactorCoupleID_FactorCouples FOREIGN KEY (lFactorCoupleID) REFERENCES dbo.tMultiFactorRiskFactorCouples (lFactorCoupleID)
	)

GO
ALTER TABLE dbo.tMultiFactorRiskFactorCorrelation SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
