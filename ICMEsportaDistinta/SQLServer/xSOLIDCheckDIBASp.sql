USE [ADB_ICM]
GO
/****** Object:  StoredProcedure [dbo].[xSOLIDCheckDIBASp]    Script Date: 1/21/2025 5:08:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[xSOLIDCheckDIBASp]
( @DEDID varchar(50)
, @DEDREV varchar(50)
, @IDDBCheck int
, @CheckDIBA int OUTPUT
, @DistDate smalldatetime 
, @UltRev smallint
, @StoreRadice varchar(50)
)
AS
BEGIN

    DECLARE 
	  @Message nvarchar(4000)
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	

	--N.B. la radice si può sempre cancellare

	SET NOCOUNT ON;

	DECLARE @Severity INT
	DECLARE @Id_DB int
	DECLARE @Id_DBMateriale int
	DECLARE @DedCodFiglio nvarchar(50)
	DECLARE @DedCodPadre nvarchar(50)

	DECLARE @DBKit bit
	DECLARE @DBFantasma bit

	DECLARE @MessageLog nvarchar(4000)

	DECLARE 
	  @CountDED int
	, @CountARCA int
	, @DedCodFiglioDescrizione varchar(150)
	, @DedCodFiglioNotadiTaglio varchar(150)
    --, @DedCodPadreCatMerc varchar(20)
	, @DedCodPadreDescrizione varchar(150)
	, @DedCodPadreNotadiTaglio varchar(150)
	, @DedCodPadreARCA nvarchar(50)
    , @DedCodFiglioCatMercCheck varchar(20)
	, @DedCodFiglioDescrizioneCheck varchar(150)
	, @DedCodFiglioNotadiTaglioCheck varchar(150)
	, @DedCodFiglioCheck nvarchar(50)
	--, @DedCodFiglioCatMerc nvarchar(20)

	, @UMMateriale varchar(2)
	, @LGFIGLIO varchar(15)
	, @NEWLGFIGLIO varchar(15)
	, @iCount int
	, @LgNumeroFiglio numeric (18,4)
	, @Q float
	, @DEDIDC varchar(50)
	, @DEDREVC	varchar(50)           
	, @man varchar(1)
	, @DEDIDP varchar(50)
	, @DEDREVP varchar(50)
	, @xStatoDED int


	DECLARE @IDMATTABLE TABLE
	( Id_DBMateriale int PRIMARY KEY)
	

	SET @Severity = 0

	SET @CheckDIBA = 1


	SELECT TOP 1 @DedCodPadre = DED_COD --DED_DIS + '_' + DEDREV
		  	   --, @DedCodPadreCatMerc = CAT_MER
			   , @DedCodPadreDescrizione = DescCommercialeITA --DEDDESC
			   , @DedCodPadreNotadiTaglio = NOTA_DI_TAGLIO			   
			   FROM [PDMDATABASE].[ICM_Custom].[dbo].[XPORT_ANAG]			              
		       WHERE DEDID = @DEDID
				 AND DEDREV = @DEDREV

	SET @xStatoDED = 100

	SET @DedCodPadreARCA = @DedCodPadre

	


	SELECT @xStatoDED = xStatoDED FROM AR WHERE CD_AR = @DedCodPadreARCA

	IF @xStatoDED IS NULL
	  SET @xStatoDED = 100




	SET @CountDED = 0
	SET @CountARCA = 0

	SELECT @CountDED = COUNT(*) FROM [PDMDATABASE].[ICM_Custom].[dbo].[XPORT_DIST]
	                   WHERE DEDIDP = @DEDID
	                     AND DEDREVP = @DEDREV
                 	     AND ISNULL(DEDIDC, '') <> ''														

	IF @CountDED IS NULL
	  SET @CountDED = 0


	SELECT @CountARCA = COUNT(*) FROM DBMateriale WHERE Id_DB = @IDDBCheck
                                                     --AND InizioValidita = '01/01/2001'
                                                     --AND FineValidita = NULL

    IF @CountARCA IS NULL
	  SET @CountARCA = 0

	IF @CountDED = 0 OR @CountARCA = 0 OR @CountDED <> @CountARCA
	BEGIN

	  --print 'minni'
	  --print @CountDED
	  --print @CountARCA

	    SET @Message = '---'


	    SET @CheckDIBA = 0
	    --RETURN @Severity  continua per scrivere il log

	END

    DECLARE DedBomCrs CURSOR LOCAL STATIC FOR
	  SELECT
	  	DEDIDC
	  , DEDREVC
	  --, man
	  , DEDIDP
	  , DEDREVP
      , CONSUMO
	  , UM
	  FROM [PDMDATABASE].[ICM_Custom].[dbo].[XPORT_DIST]
	  WHERE DEDIDP = @DEDID
	    AND DEDREVP = @DEDREV
	    AND ISNULL(DEDIDC, '') <> ''														
		ORDER BY DEDIDC

	OPEN DedBomCrs

	WHILE (@Severity = 0)
    BEGIN


	  FETCH DedBomCrs INTO
      	@DEDIDC
	  , @DEDREVC	          
	  --, @man
	  , @DEDIDP
	  , @DEDREVP
	  , @Q  
	  , @UMMateriale
	  IF @@FETCH_STATUS <> 0
		BREAK
          
	  SET @DedCodFiglio = NULL

	  IF @UltRev = 1
	  BEGIN


	    SELECT TOP 1 @DedCodFiglio = DED_COD --DED_DIS + '_' + DEDREV
			       --, @DedCodFiglioCatMerc = CAT_MER
			       , @DedCodFiglioDescrizione = DescCommercialeITA --DEDDESC
				   , @DedCodFiglioNotadiTaglio = NOTA_DI_TAGLIO 
	    FROM [PDMDATABASE].[ICM_Custom].[dbo].[XPORT_ANAG] WHERE 
	    (DEDID = @DEDIDC) --AND (DED_DIS NOT LIKE 'ZZ%')	
	    AND ISNULL(DEDREVDATE, @DistDate - 1) < @DistDate
	    ORDER BY CAST(DEDREV AS Int) DESC


      

  	  END
	  ELSE
	  BEGIN


        SELECT TOP 1 @DedCodFiglio = DED_COD --DED_DIS + '_' + DEDREV
		  	       --, @DedCodFiglioCatMerc = CAT_MER
			       , @DedCodFiglioDescrizione = DescCommercialeITA --DEDDESC
				   , @DedCodFiglioNotadiTaglio = NOTA_DI_TAGLIO
			       FROM [PDMDATABASE].[ICM_Custom].[dbo].[XPORT_ANAG]			              
		           WHERE DEDID = @DEDIDC
				     AND DEDREV = @DEDREVC	       
					    
	  END

  	  IF LTRIM(RTRIM(ISNULL(@DedCodFiglio,''))) = ''
		CONTINUE

      SET @DedCodFiglio = upper(@DedCodFiglio)



      SELECT TOP 1 @Id_DBMateriale = Id_DBMateriale FROM DBMateriale
	  WHERE Id_DB = @IDDBCheck
	    AND Cd_AR = @DedCodFiglio
	    AND Consumo = @Q
	    AND DivisoreConsumo = 1.0
	    AND Cd_ARMisura = @UMMateriale
	    AND FattoreToUM1 = 1.0
	    AND InizioValidita <= '01/01/2002'
	    AND FineValidita IS NULL
        AND NOT EXISTS (SELECT 1 FROM @IDMATTABLE AS IDMT WHERE IDMT.Id_DBMateriale = DBMateriale.Id_DBMateriale)

	  IF @@ROWCOUNT <> 1
	  BEGIN

		SET @CheckDIBA = 0
	    --RETURN @Severity  continuare per scrivere il log anche se si sa già che la distinta è diversa

		CONTINUE

	  END

	  INSERT INTO @IDMATTABLE (Id_DBMateriale) VALUES (@Id_DBMateriale)

    END

	CLOSE DedBomCrs
	DEALLOCATE DedBomCrs

	RETURN @Severity

END
