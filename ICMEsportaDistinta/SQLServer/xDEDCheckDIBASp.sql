USE [ADB_ICM]
GO
/****** Object:  StoredProcedure [dbo].[xDEDCheckDIBASp]    Script Date: 6/23/2023 8:46:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[xDEDCheckDIBASp]
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
	, @DedCodFiglioCatMerc varchar(20)
	, @DedCodFiglioDescrizione varchar(150)
	, @DedCodFiglioNotadiTaglio varchar(150)
    , @DedCodPadreCatMerc varchar(20)
	, @DedCodPadreDescrizione varchar(150)
	, @DedCodPadreNotadiTaglio varchar(150)
	, @DedCodPadreARCA nvarchar(50)
    , @DedCodFiglioCatMercCheck varchar(20)
	, @DedCodFiglioDescrizioneCheck varchar(150)
	, @DedCodFiglioNotadiTaglioCheck varchar(150)
	, @DedCodFiglioCheck nvarchar(50)

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


	SELECT TOP 1 @DedCodPadre = DED_DIS 
		  	   , @DedCodPadreCatMerc = CAT_MERC
			   , @DedCodPadreDescrizione = DEDDESC
			   , @DedCodPadreNotadiTaglio = NOTA_DI_TAGLIO			   
			   FROM GESTIONALE.[QS_DED_PLUS].dbo.DED_DATA			              
		       WHERE DEDID = @DEDID
				 AND DEDREV = @DEDREV

	SET @xStatoDED = 100

	SET @DedCodPadreARCA = @DedCodPadre

	IF EXISTS (SELECT 1 FROM xCodifica WHERE codice = @DedCodFiglio)
	BEGIN

	  SELECT TOP 1 @DedCodPadreARCA = codifica FROM xCodifica WHERE codice = @DedCodPadreARCA

    END

	SELECT @xStatoDED = xStatoDED FROM AR WHERE CD_AR = @DedCodPadreARCA

	IF @xStatoDED IS NULL
	  SET @xStatoDED = 100



    IF (((@DedCodPadreCatMerc = 'GOM') AND LTRIM(RTRIM(@DedCodPadreNotadiTaglio)) LIKE 'Bavetta%' AND LTRIM(RTRIM(@DedCodPadreDescrizione)) LIKE 'Bavetta%') OR
      ((LTRIM(RTRIM(@DedCodPadreDescrizione)) LIKE 'TUBO%CORRIMANO%') AND @DedCodPadreCatMerc = 'TUB') OR
	  ((@DedCodPadreCatMerc = 'BUL') AND LTRIM(RTRIM(@DedCodPadreNotadiTaglio)) LIKE 'Barra Filettata%'))

    RETURN @Severity

	SET @CountDED = 0
	SET @CountARCA = 0

	SELECT @CountDED = COUNT(*) FROM GESTIONALE.[QS_DED_PLUS].dbo.DED_BOM
	                   WHERE DED_BOM.DEDIDP = @DEDID
	                     AND DED_BOM.DEDREVP = @DEDREV
                 	     AND ISNULL(DED_BOM.DEDIDC, '') <> ''														
		                 AND ISNULL(DED_BOM.CREATIONDATE , (@DistDate + 1)) < @DistDate
		                 AND ISNULL(DED_BOM.VALIDDATE, (@DistDate - 1)) >= @DistDate

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

	    IF ISNULL(@Message, '') <> ''
		  INSERT INTO #TTLog (lMessage) VALUES (@Message)


	    SET @Message = 'ATTENZIONE: In importazione progetto ' + @StoreRadice + ' la distinta di ' + @DEDID + ' Rev.' + @DEDREV +
		               ' differisce nel numero di componenti'

		
		IF ISNULL(@Message, '') <> ''
		  INSERT INTO #TTLog (lMessage) VALUES (@Message)
		--EXEC dbo.xWriteLog @Message = @Message, @NomeFile = @NomeFile



	    SET @CheckDIBA = 0
	    --RETURN @Severity  continua per scrivere il log

	END

    DECLARE DedBomCrs CURSOR LOCAL STATIC FOR
	  SELECT
	  	DEDIDC
	  , DEDREVC
	  , man
	  , DEDIDP
	  , DEDREVP
      , QTA
	  FROM GESTIONALE.[QS_DED_PLUS].dbo.DED_BOM
	  WHERE DED_BOM.DEDIDP = @DEDID
	    AND DED_BOM.DEDREVP = @DEDREV
	    AND ISNULL(DED_BOM.DEDIDC, '') <> ''														
		AND ISNULL(DED_BOM.CREATIONDATE , (@DistDate + 1)) < @DistDate
		AND ISNULL(DED_BOM.VALIDDATE, (@DistDate - 1)) >= @DistDate
		ORDER BY DEDIDC

	OPEN DedBomCrs

	WHILE (@Severity = 0)
    BEGIN


	  FETCH DedBomCrs INTO
      	@DEDIDC
	  , @DEDREVC	          
	  , @man
	  , @DEDIDP
	  , @DEDREVP
	  , @Q  

	  IF @@FETCH_STATUS <> 0
		BREAK
          
	  SET @DedCodFiglio = NULL

	  IF @UltRev = 1
	  BEGIN


	    SELECT TOP 1 @DedCodFiglio = DED_DIS
			       , @DedCodFiglioCatMerc = CAT_MERC
			       , @DedCodFiglioDescrizione = DEDDESC
				   , @DedCodFiglioNotadiTaglio = NOTA_DI_TAGLIO 
	    FROM GESTIONALE.[QS_DED_PLUS].dbo.DED_DATA WHERE 
	    (DEDID = @DEDIDC) --AND (DED_DIS NOT LIKE 'ZZ%')	
	    AND ISNULL(DEDREVDATE, @DistDate - 1) < @DistDate
	    ORDER BY CAST(DEDREV AS Int) DESC


      

  	  END
	  ELSE
	  BEGIN


        SELECT TOP 1 @DedCodFiglio = DED_DIS 
		  	       , @DedCodFiglioCatMerc = CAT_MERC
			       , @DedCodFiglioDescrizione = DEDDESC
				   , @DedCodFiglioNotadiTaglio = NOTA_DI_TAGLIO
			       FROM GESTIONALE.[QS_DED_PLUS].dbo.DED_DATA			              
		           WHERE DEDID = @DEDIDC
				     AND DEDREV = @DEDREVC	       
					    
	  END

  	  IF LTRIM(RTRIM(ISNULL(@DedCodFiglio,''))) = ''
		CONTINUE

      SET @DedCodFiglio = upper(@DedCodFiglio)

	  -- guic: confronto per variazione delle revisioni (e scrittura nel log)

/*	  guic: spostato 

    SELECT TOP 1 
	        @DedCodFiglioCheck = DED_COD 
		  , @DedCodFiglioCatMercCheck = CAT_MERC
		  , @DedCodFiglioDescrizioneCheck = DEDDESC
		  , @DedCodFiglioNotadiTaglioCheck = NOTA_DI_TAGLIO
		  FROM [QS_DED_PLUS].dbo.DED_DATA			              
		  WHERE DEDID = @DEDIDC
		    AND DEDREV = @DEDREVC	       

	  IF @DedCodFiglio <> @DedCodFiglioCheck
	  BEGIN
	    

	  END

*/

	  IF (ISNULL(@DedCodPadreCatMerc, '') IN ('SAL','SAS','ATM','SAM','SHD','TAM')) AND
	     (ISNULL(@DedCodFiglioCatMerc, '') IN('BUL', 'OLE', 'COM', 'GOM'))
	    SET @DedCodFiglio = @DedCodFiglio + '_K'


	  --guic: codifica
	  IF EXISTS (SELECT 1 FROM xCodifica WHERE codice = @DedCodFiglio)
	  BEGIN

		SELECT TOP 1 @DedCodFiglio = codifica FROM xCodifica WHERE codice = @DedCodFiglio

      END


	  SET @UMMateriale = 'NR'			

	  --IF (@DedCodFiglio LIKE 'Bavetta%' OR @DedCodFiglio LIKE 'Tubo')
	  --BEGIN
			  
	    -- calcolo lunghezza

		--SET @LGFIGLIO = NULL

	    --SELECT TOP 1 @LGFIGLIO = LG FROM [QS_DED_PLUS].dbo.DED_DATA WHERE DEDID = @DEDIDC			      
	    --             	                                          ORDER BY DEDREV DESC
	                                                              --AND DEDREV = @DEDREVC	
																	
        --SET @NEWLGFIGLIO = ''

	    --SET @iCount = 1

	    --WHILE (@iCount <= len(@LGFIGLIO))
	    --BEGIN


		   --IF SUBSTRING(@LGFIGLIO, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
		     --SET @NEWLGFIGLIO = @NEWLGFIGLIO + SUBSTRING(@LGFIGLIO, @iCount, 1)

		   --SET @iCount = @iCount + 1

	    --END

	    --SET @LGFIGLIO = @NEWLGFIGLIO

	    --SET @LgNumeroFiglio = NULL

	    --IF @LGFIGLIO IS NULL
		  --SET @LgNumeroFiglio = 0
	    --ELSE
	      --IF ISNUMERIC(@LGFIGLIO) = 1
		    --SET @LgNumeroFiglio = CAST(REPLACE(@LGFIGLIO, ',' , '.') AS numeric(18,4))
		  --ELSE
		    --SET @LgNumeroFiglio = 0


	    --SET @Q = @Q * @LgNumeroFiglio / 1000.0

		--SET @UMMateriale = 'MT'

      --END


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
	    --print 'pippoInizio'
	    --print @DedCodFiglio
	    --print @Q		
		--print @IDDBCheck
		--print @DedCodFiglio
		--print @Q
		--print @UMMateriale
		--print 'pippoFine'		

		-- guic: scrittura nel log

	    SET @Message = '---'

	    IF ISNULL(@Message, '') <> ''
		  INSERT INTO #TTLog (lMessage) VALUES (@Message)


		SET @Message = 'ATTENZIONE: In importazione progetto ' + @StoreRadice + ' la distinta di ' + @DEDID + ' Rev.' + @DEDREV +
		               ' differisce nel componente ' + @DedCodFiglio


  		IF ISNULL(@Message, '') <> ''
		  INSERT INTO #TTLog (lMessage) VALUES (@Message)


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