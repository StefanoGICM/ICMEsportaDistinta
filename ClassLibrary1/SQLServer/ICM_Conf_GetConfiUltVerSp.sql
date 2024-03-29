USE [EPDMSuite]
GO
/****** Object:  StoredProcedure [dbo].[ICM_Conf_GetPromossoSP]    Script Date: 2/15/2023 8:41:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[ICM_Conf_GetConfiUltVerSp] (
	-- Add the parameters for the stored procedure here
	@DocumentID int
  , @ICMRefBOMGUID AS nvarchar(1000)
  , @ConfName nvarchar(200) OUTPUT
  , @UltRevisionNo int  OUTPUT
  )
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE 
	  @ProjectID int
	, @VariableID int
	, @ErrorMessage nvarchar(1000)


	SELECT TOP 1
	  @ConfName = dc.ConfigurationName
	, @UltRevisionNo = vv.RevisionNo
	, @ProjectID = vv.ProjectID
	, @VariableID = vv.VariableID
	FROM ICM.dbo.VariableValue vv
	INNER JOIN ICM.dbo.Variable v ON v.VariableID = vv.VariableID
	INNER JOIN ICM.dbo.DocumentConfiguration dc ON dc.ConfigurationID = vv.ConfigurationID
	WHERE v.VariableName = 'ICMBOMGUID'
	  AND vv.ValueText = @ICMRefBOMGUID
	  AND vv.DocumentID = @DocumentID
	ORDER BY RevisionNo DESC

	IF @@ROWCOUNT = 0
	BEGIN

	  SET @ErrorMessage = 'Errore: Valore configurazione costruttiva ' + @ICMRefBOMGUID + ' non trovata per Documento con ID: ' + CAST(@DocumentID AS nvarchar(100)) + '.';

	  THROW 51000, @ErrorMessage, 16

	END

	IF EXISTS (SELECT 1 FROM ICM.dbo.VariableValue vv WHERE vv.VariableID = @VariableID
	                                                    AND vv.DocumentID = @DocumentID
														AND vv.ProjectID <> @ProjectID)
    BEGIN


	  SET @ErrorMessage = 'Errore: trovato documento in più directories per Documento con ID: ' + CAST(@DocumentID AS nvarchar(100)) + '.';

	  THROW 51000, @ErrorMessage, 16


	END
	
END
