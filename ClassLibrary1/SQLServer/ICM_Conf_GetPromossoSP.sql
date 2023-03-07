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
ALTER PROCEDURE ICM_Conf_GetPromossoSP (
	-- Add the parameters for the stored procedure here
	@DocumentID AS int
  , @Conf nvarchar(200)
  , @RevisionNo int
  , @Promosso int OUTPUT  
  )
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE 
	  @ConfigurationID AS int

	DECLARE @CheckPromossoChanged int

	DECLARE 
	  @iOldPromosso AS int
	  
	DECLARE @IsLastRevision smallint

	SET @CheckPromossoChanged = 0
	
	SELECT TOP 1 
	  @ConfigurationID = ConfigurationID
	FROM SandBox.dbo.DocumentConfiguration
	WHERE ConfigurationName = @Conf

	IF @@ROWCOUNT <> 1
	BEGIN;

	  THROW 51000, 'Errore nel verificare assieme promosso: il record non esiste.', 16

	END

	SELECT TOP 1
	    @Promosso = ShowChildComponentsInBOM	  
	FROM 
	  SandBox.dbo.DocumentRevisionConfiguration
	WHERE DocumentID = @DocumentID
	  AND RevisionNo = @RevisionNo
	  AND ConfigurationID = @ConfigurationID
	ORDER BY RevisionNo DESC

	IF @@ROWCOUNT <> 1
	BEGIN;

	  THROW 51000, 'Errore nel verificare assieme promosso: il record non esiste.', 16

	END

	IF EXISTS (SELECT 1 FROM DocumentRevisionConfiguration 
	           WHERE DocumentID = @DocumentID
			     AND ConfigurationID = @ConfigurationID
				 AND RevisionNo > @RevisionNo)
	  SET @IsLastRevision = 0
	ELSE
	  SET @IsLastRevision = 1

    IF @IsLastRevision = 1
	BEGIN
	  SELECT TOP 1
	      @iOldPromosso = Promosso	  
	    FROM XPORT_Pro
	    WHERE DocumentID = @DocumentID
	    --AND RevisionNo = @RevisionNo
	    AND Configuration = @Conf
	  ORDER BY RevisionNo DESC
	END 
	ELSE
	BEGIN

	  SELECT TOP 1
	      @iOldPromosso = Promosso	  
	    FROM XPORT_Pro
	    WHERE DocumentID = @DocumentID
	    AND RevisionNo = @RevisionNo
	    AND Configuration = @Conf

	END

	IF @@ROWCOUNT = 1
	BEGIN

	  IF @Promosso <> @iOldPromosso
	    SET @CheckPromossoChanged = 1


	END

	IF EXISTS (SELECT 1 FROM XPORT_Pro
	           WHERE DocumentID = @DocumentID
			     AND Configuration = @Conf
				 AND RevisionNo = @RevisionNo)
	BEGIN

	  UPDATE XPORT_Pro
	  SET Changed = @CheckPromossoChanged
	    , Promosso = @Promosso
	  WHERE DocumentID = @DocumentID
	    AND Configuration = @Conf
	    AND RevisionNo = @RevisionNo

	END
	ELSE 
	BEGIN

	  INSERT INTO XPORT_Pro
	  (  DocumentID
	   , Configuration
	   , RevisionNo
	   , Promosso
	   , Changed)
	  VALUES
	  (  @DocumentID
	  ,  @Conf
	  ,  @RevisionNo
	  ,  @Promosso
	  ,  @CheckPromossoChanged )

	END





END
GO
