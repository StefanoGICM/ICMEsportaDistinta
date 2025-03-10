USE [ADB_ICM]
GO
/****** Object:  StoredProcedure [dbo].[xSOLIDCancellaDistintaSp]    Script Date: 1/21/2025 6:02:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[xSOLIDCancellaDistintaSp] 
( @DedCodInput nvarchar(20))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	--N.B. la radice si può sempre cancellare

	SET NOCOUNT ON;

	DECLARE @Severity INT
	DECLARE @Id_DB int
	DECLARE @Id_DBMateriale int
	DECLARE @DedCodFiglio nvarchar(20)

	DECLARE @DBKit bit
	DECLARE @DBFantasma bit


	SET @Severity = 0

	SET @Id_DB = NULL


	SELECT TOP 1 @Id_DB = Id_DB
    FROM DB WITH (UPDLOCK)
	WHERE Cd_AR = @DedCodInput

	IF @@ROWCOUNT = 1 AND @Id_DB IS NOT NULL
	BEGIN

      --print '@Id_DB'
	  --print @Id_DB	  

	  DECLARE Z380DBMateriale CURSOR LOCAL STATIC FOR
	  SELECT 
	    Id_DBMateriale
	  , Cd_AR	       
	  FROM DBMateriale WITH (UPDLOCK)
	  WHERE DBMateriale.Id_DB = @Id_DB

	  OPEN Z380DBMateriale

	  WHILE (@Severity = 0)
	  BEGIN

	    FETCH Z380DBMateriale INTO
		  @Id_DBMateriale
		, @DedCodFiglio

		IF @@FETCH_STATUS <> 0
		  BREAK

		IF EXISTS (SELECT 1 FROM DBMateriale
		           WHERE Cd_AR =  @DedCodFiglio
				      AND Id_DB <> @Id_DB)
		BEGIN

		  DELETE FROM DBMateriale
		  WHERE Id_DBMateriale = @Id_DBMateriale

		  SET @Severity = @@ERROR
		  IF @Severity <> 0
		    RETURN @Severity

	      CONTINUE
		END
				     
		  
		EXEC @Severity = xSOLIDCancellaDistintaSp @DedCodInput = @DedCodFiglio

		
		IF @Severity = 0
		BEGIN
		                        		
          DELETE FROM DBMateriale
		  WHERE Id_DBMateriale = @Id_DBMateriale

		  SET @Severity = @@ERROR
		  IF @Severity <> 0
		    RETURN @Severity


		  -- DA NON FARE: Imposto a Kit e Fantasma se Esiste una distinta con 'SAL','SAS','ATM','SAM','SHD' come padre

		  --IF EXISTS (SELECT 1 FROM DBMateriale 
		                      --INNER JOIN DB ON DB.Id_DB = DBMateriale.Id_DB
			  				  --INNER JOIN AR ON AR.Cd_AR = DB.Cd_AR
							  --WHERE AR.Cd_ARGruppo1 IN ('SAL','SAS','ATM','SAM','SHD')
--							    AND DBMateriale.Cd_AR = @DedCodFiglio)
	      --BEGIN
  	        --SET @DBKit = 1
            --SET @DBFantasma = 1
		  --END
		  --ELSE
	      --BEGIN
  	        --SET @DBKit = 0
            --SET @DBFantasma = 0
		  --END

		  --UPDATE AR
		    --SET DBKit = @DBKit
			  --, DBFantasma = @DBFantasma
		  --WHERE Cd_AR = @DedCodFiglio

		  --SET @Severity = @@ERROR
		  --IF @Severity <> 0
		    --RETURN @Severity

		END
	  END

	  CLOSE Z380DBMateriale
	  DEALLOCATE Z380DBMateriale

	  
	  -- la radice (legata alla commessa) va sempre cancellata
	  
	  DELETE FROM DB
	  WHERE Cd_AR = @DedCodInput

	  SET @Severity = @@ERROR
	  IF @Severity <> 0
		RETURN @Severity

	END



	RETURN @Severity

END
