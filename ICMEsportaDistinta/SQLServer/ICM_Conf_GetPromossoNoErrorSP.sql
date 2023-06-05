-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ICM_Conf_GetPromossoNoErrorSP (
	-- Add the parameters for the stored procedure here
	@DocumentID AS int
  , @Conf nvarchar(200)
  , @RevisionNo int
  , @Promosso int OUTPUT  
  , @Founded int OUTPUT
  )
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET @Founded = 0;

    -- Insert statements for procedure here
	DECLARE 
	  @ConfigurationID AS int

	DECLARE @CheckPromossoChanged int

	DECLARE 
	  @iOldPromosso AS int
	  
	DECLARE @IsLastRevision smallint

	SET @CheckPromossoChanged = 0
	

	SELECT TOP 1
	    @Promosso = drc.ShowChildComponentsInBOM	  
	FROM 
	  SandBox2.dbo.DocumentRevisionConfiguration drc
	INNER JOIN SandBox2.dbo.DocumentConfiguration conf ON drc.ConfigurationID = conf.ConfigurationID
	WHERE drc.DocumentID = @DocumentID
	  AND drc.RevisionNo = @RevisionNo
	  AND conf.ConfigurationName = @Conf
	ORDER BY drc.RevisionNo DESC

	IF @@ROWCOUNT <> 1
	BEGIN;

	  --THROW 51000, 'Errore nel verificare assieme promosso: il record non esiste.', 16
	  RETURN

	END

	SET @Founded = 1

END
GO
