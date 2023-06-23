USE [ADB_ICM]
GO
/****** Object:  StoredProcedure [dbo].[xDEDCreaArticoloSp]    Script Date: 6/23/2023 8:46:35 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[xDEDCreaArticoloSp]
( @DedId varchar(50),
  @DedRev varchar(50),
  @Transaction smallint,
  @Azione char(1),
  @ForzaFantaKit smallint,
  @CodPadre varchar(30),
--  @LivelloMax int,
--  @Livello int,
--  @ParDove varchar(3),
  @XErrore varchar(1000) OUTPUT,
  @DistDate smalldatetime,
  @UltRev smallint,
  @UltBBT smallint,
  @DedIdPadre varchar(50) = NULL,
  @Livello int = 0
)     -- 'A' Add, 'U' Update, 'D' Delete
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	DECLARE 
	  @Severity INT
	, @DedCodInput nvarchar(20)
	, @DedCodInputAll nvarchar(50)
	, @DedBavBaTubSave nvarchar(50)
	, @NewDedCodInputAll nvarchar(50)
	, @Codifica tinyint
	, @CodificaCodice varchar(30)
	, @CodificaCodifica varchar(20)
	, @LastCodificaCodifica varchar(20)
	, @NumeroCodifica int
	, @CarNumeroCodifica varchar(20)
	, @DedNewRev varchar(50)
	, @CAT_MERC varchar(20)
	, @NOTA_DI_TAGLIO varchar(150)
	, @DedCodFiglioCatMerc varchar(20)
	, @DedCodInputLike nvarchar(50)
	, @DedCodInputLikeFound nvarchar(50)
	, @DedCodFount int
	, @RowCount int
	, @PreDescr varchar(40)	
    , @PreCodificaCodice varchar(30)
	, @PreCodificaCodifica varchar(20)
	, @IWhilePreCodifica int
	, @PreCodifica int
	, @DESCRIZION varchar(150)
	, @SplitData varchar(1000)
    , @TipoBavetta varchar(1000)
	, @iBavetta int
	, @TipoBarraFilettata varchar(1000)
	, @iBarraFilettata int
	, @iLBavetta int
	, @iLTubo int
	, @iLBarraFilettata int
    , @iLBavetta2 int
	, @iLTubo2 int
	, @iLBarraFilettata2 int
	, @UMMateriale varchar(2)
	, @xItem varchar(20)
	, @xStatoDED int
	, @DedCodFiglioDescrizione varchar(150)
	, @DedCodFiglioNotadiTaglio varchar(150)
	, @FattoreTuboBavetta numeric(18,8)
	, @LottoRiordinoTuboBavetta numeric(18,8)
	, @CheckDIBA int
	, @IDDBCheck int
	, @StoreRadice varchar(50)
	, @NomeFileLog varchar(200)
	, @Ciclo int
	, @LogMessage varchar(4000)
	, @QTemp numeric(18,8)
	, @NewLivello int
	, @xRevisione Char(2)

	SET @NomeFileLog = REPLACE(REPLACE(REPLACE('ImpDistinta' + '#' + @DedId + '_' + @DedRev + '#' + CONVERT(varchar(40), GETDATE(), 20),' ', '_'), '-', '_'), ':', '_')


	SET @Severity = 0

	SET @Codifica = 0
	SET @iLBavetta = 0
	SET @iLTubo = 0
	SET @iLBarraFilettata = 0

	SET @iLBavetta2 = 0
	SET @iLTubo2 = 0
	SET @iLBarraFilettata2 = 0

	

	IF @Transaction = 1
	BEGIN

	  IF OBJECT_ID(N'tempdb..#TTLog', N'U') IS NOT NULL 
        DROP TABLE #TTLog

	  CREATE TABLE #TTLog (
	    lIndex int primary key identity
      , lMessage nvarchar(4000) 
	  )

	  INSERT INTO #TTLog (lMessage) VALUES (' --- ')
      INSERT INTO #TTLog (lMessage) VALUES ('Importazione progetto: ' + @DedId + ' Rev: ' + @DedRev)

	END

	
--	DECLARE @TTLog AS TABLE (
--	  lIndex int primary key identity
--    , lMessage nvarchar(4000) 
--	)

	

	--IF @Transaction = 1
	--BEGIN

	  --EXEC master.dbo.sp_configure 'show advanced options', 1
      --RECONFIGURE
      --EXEC master.dbo.sp_configure 'xp_cmdshell', 1
      --RECONFIGURE

	--END

	IF @Transaction = 1
	  BEGIN TRANSACTION

	IF @Transaction = 1
	BEGIN
	  SET @StoreRadice = @DedId
	  SET @DedIdPadre = @DedId
	END
	ELSE
	BEGIN
	  SET @StoreRadice = @DedIdPadre
	END

	SET @DistDate = DATEADD(Day, 1, DATEDIFF(Day, 0, @DistDate))

	


	-- prende l'ultima revisione

	IF @UltRev = 1
	BEGIN

	  SET @DedNewRev = NULL

	  SELECT TOP 1 @DedNewRev = DEDREV FROM GESTIONALE.[QS_DED_PLUS].dbo.DED_DATA WHERE 
	  (DEDID = @DedId) --AND (DED_DIS NOT LIKE 'ZZ%')	
	  AND ISNULL(DEDREVDATE, @DistDate - 1) < @DistDate
	  ORDER BY CAST(DEDREV AS Int) DESC

	  IF @DedNewRev IS NOT NULL
	    SET @DedRev = @DedNewRev

      

	END

	--print @DedId + ' --- ' + @DedRev


	SELECT 
	  -- @DedCodInputAll = DED_DIS
	  @DedCodInputAll = DED_COD
	--, @xRevisione = CASE WHEN LEFT(RIGHT(DED_DIS, 2), 1) = '_' THEN RIGHT(DED_DIS, 1) ELSE NULL END
	, @xRevisione = CASE WHEN LEFT(RIGHT(DED_DIS, 2), 1) = '_' THEN RIGHT(DED_DIS, 1) ELSE CASE WHEN LEFT(RIGHT(DED_DIS, 3), 1) = '_' THEN RIGHT(DED_DIS, 2) ELSE NULL END END
	, @CAT_MERC = CAT_MERC  
	, @NOTA_DI_TAGLIO = NOTA_DI_TAGLIO
	, @DESCRIZION  = DEDDESC
	FROM GESTIONALE.[QS_DED_PLUS].dbo.DED_DATA WHERE DEDID = @DedId     
     AND DEDREV = @DedRev

    SET @DedCodInputAll = UPPER(@DedCodInputAll)    

     IF ISNULL(@DESCRIZION, '') = ''
	  SET @DESCRIZION = 'Senza Descrizione'


	-- guic: gestione bavette
	
	IF (@CAT_MERC = 'GOM') AND LTRIM(RTRIM(@NOTA_DI_TAGLIO)) LIKE 'Bavetta%' AND LTRIM(RTRIM(@DESCRIZION)) LIKE 'Bavetta%'
	BEGIN

	  --print @NOTA_DI_TAGLIO

	  DECLARE spliDataCrs CURSOR LOCAL STATIC
	  FOR SELECT splitData
	  FROM dbo.xSplitString(@NOTA_DI_TAGLIO, ' ' )
	  ORDER BY iIndex

	  OPEN spliDataCrs

	  SET @TipoBavetta = ''
	  SET @iBavetta = 0	  

	  WHILE (@Severity = 0)
	  BEGIN

	    FETCH spliDataCrs INTO
		  @SplitData		

		IF @@FETCH_STATUS <> 0
		  break		

		SET @iBavetta = @iBavetta + 1

		IF @iBavetta = 2
		BEGIN

		  SET @TipoBavetta = @SplitData
		  SET @iLBavetta2 = 1
		  break

		END
	  END

      CLOSE spliDataCrs
	  DEALLOCATE spliDataCrs

	  --print @TipoBavetta	  

	  --SET @Severity = 16

	  --IF @Transaction = 1
	  --  GOTO labelExit
	  --ELSE
	  --  GOTO labelExit2

	END
	
	-- guic: gestione bavette

	-- guic: gestione barra filettata

    IF (@CAT_MERC = 'BUL') AND LTRIM(RTRIM(@NOTA_DI_TAGLIO)) LIKE 'Barra Filettata%'
	BEGIN

	  --print 'inizio'
      --print @DedId
	  --print @DedRev

	  --print @NOTA_DI_TAGLIO

	  DECLARE spliDataBarraCrs CURSOR LOCAL STATIC
	  FOR SELECT splitData
	  FROM dbo.xSplitString(@NOTA_DI_TAGLIO, ' ' )
	  ORDER BY iIndex

	  OPEN spliDataBarraCrs

	  SET @TipoBarraFilettata = ''
	  SET @iBarraFilettata = 0	  

	  WHILE (@Severity = 0)
	  BEGIN

	    FETCH spliDataBarraCrs INTO
		  @SplitData		

		IF @@FETCH_STATUS <> 0
		  break		

		SET @iBarraFilettata = @iBarraFilettata + 1

		--print @iBarraFilettata
		--print @SplitData

		IF @iBarraFilettata = 3
		BEGIN

		  SET @TipoBarraFilettata = @SplitData
		  SET @iLBarraFilettata2 = 1
		  break

		END
	  END

      CLOSE spliDataBarraCrs
	  DEALLOCATE spliDataBarraCrs
	  
	  --SET @Severity = 16

	  --IF @Transaction = 1
	  --  GOTO labelExit
	  --ELSE
	  --  GOTO labelExit2

	END


	-- guic: gestione barra filettata

	-- guic: gestione tubi

	IF (LTRIM(RTRIM(@DESCRIZION)) LIKE 'TUBO%CORRIMANO%') AND @CAT_MERC = 'TUB'
	BEGIN

      SET @iLTubo2 = 1

	END
	

	IF @UltBBT = 1
	BEGIN

	  SET @iLBavetta = @iLBavetta2
	  SET @iLTubo = @iLTubo2
	  SET @iLBarraFilettata = @iLBarraFilettata2


	END

	-- guic: gestione tubi

	-- guic: ############### cambio di codice
	
	IF @DedCodInputAll = 'UNI 5739 M12X30 8,8'
	  SET @DedCodInputAll = 'UNI 5739 M12X30 10,9'

	
	-- I bulloni dentro assiemi saldati, tamburi, ecc. sono divisi da quelli liberi e creati con codice con suffisso _K
	IF  @CAT_MERC IN('BUL', 'OLE', 'COM', 'GOM') AND @ForzaFantaKit = 1
	  SET @DedCodInputAll = @DedCodInputAll + '_K'

	-- guic: ############### cambio di codice

	SET @PreDescr = ''

	-- guic: ############### precodifica
	SET @PreCodificaCodice = ''
	SET @PreCodificaCodifica = ''
	SET @IWhilePreCodifica = 0
	SET @PreCodifica = 0

    
	IF @iLBavetta2 = 1
	  SET @DedBavBaTubSave = UPPER('BAVETTA' + @TipoBavetta)

	IF @iLBarraFilettata2 = 1
	  SET @DedBavBaTubSave = UPPER('BARRAFILETTATA' + @TipoBarraFilettata)

	IF @iLTubo2 = 1 
	  SET @DedBavBaTubSave = 'TUBOCORRIMANO'

	IF @iLBavetta = 1 
	  SET @DedCodInputAll = UPPER('BAVETTA' + @TipoBavetta)

	IF @iLBarraFilettata = 1
	BEGIN
	  SET @DedCodInputAll = UPPER('BARRAFILETTATA' + @TipoBarraFilettata)	  
	END
	  
	IF @iLTubo = 1 
	  SET @DedCodInputAll = 'TUBOCORRIMANO'

	
	IF @DedCodInputAll = 'ANSI B18.2.1 5/8X1 3/4 UNC IF'
	BEGIN

	  SET @PreCodificaCodice = 'UNC-5/8X1-3/4 IF'
	  SET @PreDescr = ' --- ANSI B18.2.1 --- '
	  SET @PreCodifica = 1		  

    END
	
	IF @DedCodInputAll = 'MR CI 100 UO3A 132 MB4 B3'
	BEGIN

	  SET @PreCodificaCodice = 'TMR-000001'
	  --SET @PreDescr = 'ANSI B18.2.1 --- '
	  SET @PreCodifica = 1
		  
	END

	IF LTRIM(RTRIM(@DedCodInputAll)) = 'ANSI B.18.2.2 3_4-10 UNC - AB'
	BEGIN	

	  SET @PreCodificaCodice = 'ANSIB18223410UNCAB'
	  --SET @PreDescr = 'ANSI B18.2.1 --- '
	  SET @PreCodifica = 1

	END

    IF @DedCodInputAll = 'MR CI 140 UO2A 160 L4'
	BEGIN

	  SET @PreCodificaCodice = 'TMR-000002'
	  --SET @PreDescr = 'ANSI B18.2.1 --- '
	  SET @PreCodifica = 1
		  
	END

	IF @DedCodInputAll = 'MR CI 140 UO2A 180 L4 B3'
	BEGIN

	  SET @PreCodificaCodice = 'TMR-000003'
	  --SET @PreDescr = 'ANSI B18.2.1 --- '
	  SET @PreCodifica = 1
		  
	END

	IF @DedCodInputAll = 'MR CI 160 UO2A 200 L4 B3'
	BEGIN

	  SET @PreCodificaCodice = 'TMR-000004'
	  --SET @PreDescr = 'ANSI B18.2.1 --- '
	  SET @PreCodifica = 1
		  
	END

    IF @DedCodInputAll = 'MR CI 160 UO2A 225 S4 B3'
	BEGIN

	  SET @PreCodificaCodice = 'TMR-000005'
	  --SET @PreDescr = 'ANSI B18.2.1 --- '
	  SET @PreCodifica = 1
		  
	END

	IF @DedCodInputAll = 'UNI EN 14399-3  M20X70 10.9'
	BEGIN

	  SET @PreCodificaCodice = 'UNIE143993M20X7010.9'
	  --SET @PreDescr = 'ANSI B18.2.1 --- '
	  SET @PreCodifica = 1
		  
	END

	IF @DedCodInputAll = 'ANSI B.18.2.2 5_16-18 UNC'
	BEGIN

	  SET @PreCodificaCodice = 'ANSIB18225_16-18UNC'
	  --SET @PreDescr = 'ANSI B18.2.1 --- '
	  SET @PreCodifica = 1


	END

	
	IF @DedCodInputAll = 'PSV1 20F17 108NL 1158'
	BEGIN

	  SET @PreCodificaCodice = 'PSV1 20F17 108NL1158'
	  --SET @PreDescr = 'ANSI B18.2.1 --- '
	  SET @PreCodifica = 1


	END

	IF @DedCodInputAll = 'PSV1 20F17 133NL 1158'
	BEGIN
	  SET @PreCodificaCodice = 'PSV1 20F17 133NL1158'
	  SET @PreCodifica = 1
	END



    -- guic: ############### precodifica

	IF @PreCodifica = 1
	BEGIN

	  IF NOT EXISTS (SELECT 1 FROM xCodifica WHERE codice = @DedCodInputAll)
	  BEGIN

	    INSERT INTO xCodifica
	    (
	      codice
        , codifica
	    )
	    VALUES
	    (
	      @DedCodInputAll
	    , @PreCodificaCodice
	    )

	  END

	  SET @CodificaCodice = @DedCodInputAll
	  SET @DedCodInputAll = @PreCodificaCodice	  
	  SET @Codifica = 1 


	END
	ELSE
	BEGIN

	  SET @CodificaCodice = @DedCodInputAll

	  IF NOT EXISTS (SELECT 1 FROM AR WHERE Cd_AR = @DedCodInputAll)
	  BEGIN

	    IF EXISTS (SELECT 1 FROM xCodifica WHERE codice = @DedCodInputAll)
	    BEGIN
	      SELECT @CodificaCodifica = codifica FROM xCodifica WHERE codice = @DedCodInputAll

		  SET @CodificaCodice = @DedCodInputAll
	      SET @DedCodInputAll = @CodificaCodifica

		  SET @Codifica = 1
	    END
	    ELSE
	    BEGIN

	      SET @DedCodFount = 0

          IF @CAT_MERC = 'BUL'
	      BEGIN
		 
		    SET @DedCodInputLike = REPLACE(REPLACE(@DedCodInputAll, ' ', '%'), ',' , '.')

		    SET @DedCodInputLike = REPLACE(@DedCodInputLike, '%%', '%')
		    SET @DedCodInputLike = REPLACE(@DedCodInputLike, '%%', '%')
		    SET @DedCodInputLike = REPLACE(@DedCodInputLike, '%%', '%')
		    SET @DedCodInputLike = REPLACE(@DedCodInputLike, '%%', '%')
		    SET @DedCodInputLike = REPLACE(@DedCodInputLike, '%%', '%')
		    SET @DedCodInputLike = REPLACE(@DedCodInputLike, '%%', '%')
		    SET @DedCodInputLike = REPLACE(@DedCodInputLike, '%%', '%')
		    SET @DedCodInputLike = REPLACE(@DedCodInputLike, '%%', '%')
		    SET @DedCodInputLike = REPLACE(@DedCodInputLike, '%%', '%')

		    SET @DedCodInputLike = @DedCodInputLike + '%'


		    SELECT TOP 1 @DedCodInputLikeFound = Cd_AR  FROM AR WHERE Cd_AR LIKE @DedCodInputLike
			ORDER BY LEN(Cd_AR)

		    SET @RowCount = @@ROWCOUNT

		    IF @RowCount = 1
		    BEGIN

		      INSERT INTO xCodifica
		      (
		        codice
		      , codifica
	          )
		      VALUES
		      (
		        @DedCodInputAll
		      , @DedCodInputLikeFound
		      )

			  SET @CodificaCodice = @DedCodInputAll
			  SET @DedCodInputAll = @DedCodInputLikeFound
			  SET @Codifica = 1
			  SET @DedCodFount = 1

		    END
		    ELSE IF @RowCount = 0
		    BEGIN 
		    
			  SET @DedCodInputLike = SUBSTRING(@DedCodInputLike, 1, LEN(@DedCodInputLike) - 1)

			  SET @DedCodInputLike = REPLACE(@DedCodInputLike, '%', '-')

			  IF LEN(@DedCodInputLike) > 20
		        SET @DedCodInputLike = REPLACE(@DedCodInputLike, '-', '')

			  IF (@DedCodInputLike <> @DedCodInputAll)
			  BEGIN

			    IF LEN(@DedCodInputLike) <= 20
			    BEGIN

		          INSERT INTO xCodifica
		          (
  		            codice
		          , codifica
	              )
		          VALUES
		          (
		            @DedCodInputAll
		          , @DedCodInputLike
		          )

			      SET @CodificaCodice = @DedCodInputAll
				  SET @DedCodInputAll = @DedCodInputLike
			      SET @Codifica = 1
			      SET @DedCodFount = 1
			    END
		      END
		    END
		  END

		  IF @DedCodFount = 0 AND LEN(@DedCodInputAll) > 20
		  BEGIN

		    -- errore

			--print 'Errore'			

        	SET @Severity = 16
			SET @XErrore = 'Codice più lungo di 20 caratteri: ' + @DedCodInputAll

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2


	        --SET @Codifica = 1
	      
      
	        --SET @LastCodificaCodifica = NULL
	        --SELECT TOP 1 @LastCodificaCodifica = codifica FROM xCodifica
		    --WHERE codifica LIKE 'XXXXCOD%'
		    --ORDER BY codifica DESC

		    --IF @LastCodificaCodifica IS NULL
		    --  SET @NumeroCodifica = 1
		    --ELSE
		    --BEGIN
		      --SET @NumeroCodifica = CAST(SUBSTRING(@LastCodificaCodifica, 8, 13) AS int)

		      --SET @NumeroCodifica = @NumeroCodifica + 1

		    --END

		    --SET @CarNumeroCodifica = CAST(@NumeroCodifica AS varchar(20))

		    --SET @CodificaCodifica = 'XXXXCOD' + RIGHT('0000000000000' + @CarNumeroCodifica, 13)

		    --INSERT INTO xCodifica
		    --(
		      --codice
		    --, codifica
	        --)
		    --VALUES
		    --(
		      --@CodificaCodice
		    --, @CodificaCodifica
		    --)

		    --SET @DedCodInputAll = @CodificaCodifica

          END
		END
	  END
	END
	

	SET @DedCodInput = @DedCodInputAll

	--print @DedCodInput

    -- Insert statements for procedure here

	DECLARE	    	  
      @CHECKOUT varchar(255)
    , @COMMESSA varchar(10)
    , @DATA varchar(10)  
    , @DBPATH varchar(100)
    , @DED_COD varchar(30)
    , @DED_FILE varchar(30)
    , @DED_REV_DATA varchar(10)
    , @DED_REV_DESC varchar(60)
    , @DED_REV_NUM varchar(2)
    , @DED_REV_USER varchar(20)
    , @DEDSTATEDATE varchar(19)
    , @DEDSTATEID int
    , @DEDSTATEPATH varchar(255)
    , @DEDSTATEUSER varchar(50)    
	, @NewDescrizione varchar(200)
    , @DISEGNATOR varchar(20)
    , @EX_CODICE varchar(40)
    , @GOTE varchar(30)
    , @LG varchar(15)
	, @LGFIGLIO varchar(15)
	, @NEWLG varchar(15)
	, @NEWLGFIGLIO varchar(15)
    , @MATERIALE varchar(30)    
    , @OLDFILE varchar(255)
    , @PESO varchar(13)
	, @NEWPESO varchar(13)
    , @POS_ varchar(5)
    , @QTA varchar(5)
    , @SCALA varchar(8)
    , @SUP_GOMMATA varchar(20)
	, @NEWSUP_GOMMATA varchar(20)
    , @TIPOLOGIA varchar(20)
    , @TRATT_TERM varchar(30)
	, @ATTR1 varchar(20)
    , @F varchar(50)
	, @larg varchar(10)
	, @lung varchar(10)
	, @man varchar(1)
	, @P varchar(50)
	, @Q float
	, @IdDb int
	, @Id_DBCiclo int
	, @Id_AR int
	, @Id_DBFase int
	, @DedCodFiglio varchar(50)
	, @NewDedCodFiglio varchar(30)
	, @Sequenza int
	, @Cd_ARClasse1 char(3)
	, @Cd_ARClasse2 char(3)
	, @Cd_ARClasse3 char(3)
	, @Cd_ARGruppo1 char(3)
	, @Cd_ARGruppo2 char(3)
	, @Cd_ARGruppo3 char(3)
	, @NoteXML varchar(2000)
	, @PesoNetto numeric (18,4)
	, @SuperficieGommata numeric (18,4)
	, @LgNumero numeric (18,4)
	, @LgNumeroFiglio numeric (18,4)
	, @DBKit bit
	, @DBFantasma bit
	, @DBKitCheck bit
	, @DBFantasmaCheck bit
	, @UMAcquisto bit
	, @iCount int
	, @DEDIDP varchar(50)
	, @DEDREVP varchar(50)
	, @DEDIDC varchar(50)
	, @DEDREVC varchar(50)
	, @DedDis nvarchar(30)
	, @POTENZA nvarchar(4)
	, @N_MOTORI nvarchar(20)
	, @NOME_COMM nvarchar(150)
	, @LARG_MACC nvarchar(10)
	, @LUNG_MACC nvarchar(10)
	, @MTPH nvarchar(10)
	, @DED_xRevisione Char(2)



	--print @DedDis


	--SELECT TOP 1 @DedDis = DED_DIS FROM [QS_DED_PLUS].dbo.DED_DATA
	--                               WHERE DED_COD = @DedCodInputAll
	--							   ORDER BY DED_COD DESC
    
	--print '@DedCodInput'
	--print @DedCodInput
	--print '@DedDis'
	--print @DedDis

	

	IF @Transaction = 1
	BEGIN


	  --IF @Azione = 'U' OR @Azione = 'D'
	  IF @Azione = 'D'
	  BEGIN

	    /* Cancellazione vecchia distinta */		

	    EXEC @Severity = xDEDCancellaDistintaSp 
		                 @DedCodInput = @DedCodInput

	  END

	  --/* Crea temporary table degli articoli processati */
	  --IF OBJECT_ID(N'tempdb..##TTArticoli', N'U') IS NOT NULL 
      --  DROP TABLE ##TTArticoli

	  --CREATE table ##TTArticoli(Cd_AR varchar(20) PRIMARY key)
	  --DELETE FROM ##TTArticoli

	END 

	--IF EXISTS (SELECT 1 FROM ##TTArticoli WHERE ##TTArticoli.Cd_AR = @DedCodInput)
	--BEGIN

	--  IF @ForzaFantaKit = 0
	--  BEGIN

	--    IF ISNULL(@CodPadre, '') <> ''
	--	BEGIN

	--	  --print @CodPadre + '###' + @DedCodInput

	--	  UPDATE AR 
	--	  SET DBFantasma = 1
	--	  WHERE Cd_AR = @CodPadre

	--	END

	--  END

	--  RETURN 0

	--END
	--ELSE
	--BEGIN

	  
	--   INSERT INTO ##TTArticoli (Cd_AR) VALUES (@DedCodInput)

	--END


    DECLARE DedArticoliCrs CURSOR LOCAL STATIC FOR
	SELECT 
--	  DEDID
--	, DEDREV
      CAT_MERC
    --, CHECKOUT
    , COMMESSA
    , DEDDATE
    , DBPATH
    , DED_COD
    , DED_DIS
    , DED_FILE
    , DEDREVDATE
    , DEDREVDESC
    --, DED_REV_NUM
    , DEDREVUSER
    , DEDSTATEDATE
    , DEDSTATEID
    --, DEDSTATEPATH
    , DEDSTATEUSER
    , DEDDESC
    --, DISEGNATOR
    , EX_CODICE
    --, GOTE
    , LG
    , MATERIALE
    , NOTA_DI_TAGLIO
    --, OLDFILE
    , PESO
    , POS_
    --, QTA
    --, SCALA
    , SUP_GOMMATA
    , TIPOLOGIA
    , TRATT_TERM
	, ATTR1
	, DEDSTATEID
	, ITEM
	, POTENZA
	, N_MOTORI
	, NOME_COMM
	, LARG_MACC
	, LUNG_MACC
	, MTPH
	--, CASE WHEN LEFT(RIGHT(DED_DIS, 2), 1) = '_' THEN RIGHT(DED_DIS, 1) ELSE NULL END
	, CASE WHEN LEFT(RIGHT(DED_DIS, 2), 1) = '_' THEN RIGHT(DED_DIS, 1) ELSE CASE WHEN LEFT(RIGHT(DED_DIS, 3), 1) = '_' THEN RIGHT(DED_DIS, 2) ELSE NULL END END

    FROM GESTIONALE.[QS_DED_PLUS].dbo.DED_DATA AS A
	WHERE A.DEDID = @DEDID
	  AND A.DEDREV = @DEDREV

    OPEN DedArticoliCrs

    WHILE (@Severity = 0)
    BEGIN

      FETCH DedArticoliCrs INTO
--	    @DEDID
--	  , @DEDREV
        @CAT_MERC
      --, @CHECKOUT
      , @COMMESSA
      , @DATA
      , @DBPATH
      , @DED_COD
      , @DedDis
      , @DED_FILE
      , @DED_REV_DATA
      , @DED_REV_DESC
      --, @DED_REV_NUM
      , @DED_REV_USER
      , @DEDSTATEDATE
      , @DEDSTATEID
      --, @DEDSTATEPATH
      , @DEDSTATEUSER
      , @DESCRIZION
      --, @DISEGNATOR
      , @EX_CODICE
      --, @GOTE
      , @LG
      , @MATERIALE
      , @NOTA_DI_TAGLIO
      --, @OLDFILE
      , @PESO
      , @POS_
      --, @QTA
      --, @SCALA
      , @SUP_GOMMATA
      , @TIPOLOGIA
      , @TRATT_TERM
      , @ATTR1	  
	  , @xStatoDED
	  , @xItem
	  , @POTENZA
	  , @N_MOTORI
	  , @NOME_COMM
	  , @LARG_MACC
	  , @LUNG_MACC
	  , @MTPH
	  , @DED_xRevisione



	  IF @@FETCH_STATUS <> 0
	    BREAK

	  /*
	  IF LEN(ISNULL(@xItem, '')) >= 4
	    SET @xItem = NULL	  

	  SET @xItem = LTRIM(RTRIM(SUBSTRING(@xItem, 1, 3)))

	  IF @xItem = ''
	    SET @xItem = NULL

	  IF @xItem IS NOT NULL
	  BEGIN

	    IF NOT EXISTS (SELECT 1 FROM xItem WHERE Cd_xItem = @xItem)
		BEGIN

		  INSERT INTO xItem (Cd_xItem, Descrizione) VALUES (@xItem, @xItem)

		END

	  END
	  */

	  -- SIMONE --
	  SET @xItem = CONVERT(Char(3), CASE WHEN LEN(ISNULL(@xItem, '')) >= 4 OR LTRIM(RTRIM(ISNULL(@xItem, ''))) = '' THEN NULL ELSE LTRIM(RTRIM(@xItem)) END)

	  IF (@xItem IS NOT NULL) AND (NOT EXISTS (SELECT 1 FROM xItem WHERE xItem.Cd_xItem = @xItem))
	  BEGIN
		INSERT INTO xItem(
			Cd_xItem,
			Descrizione)
		VALUES(@xItem, @xItem)
	  END
	  -- SIMONE --

      IF ISNULL(@DESCRIZION, '') = ''
		SET @DESCRIZION = 'Senza Descrizione'

	  IF NOT EXISTS (SELECT 1 FROM ARGruppo1 WHERE Cd_ARGruppo1 = ISNULL(@CAT_MERC, ''))
		SET @CAT_MERC = NULL

	  IF NOT EXISTS (SELECT 1 FROM ARClasse1 WHERE Cd_ARClasse1 = ISNULL(@TIPOLOGIA, ''))
		SET @TIPOLOGIA = NULL

	  -- Conversione valori in formato numerico

	  -- Peso

	  --print @DEDID
	  --print 'Peso prima'
	  --print @PESO

	  SET @NEWPESO = ''

	  SET @iCount = 1

	  WHILE (@iCount <= len(@PESO))
	  BEGIN


		  IF SUBSTRING(@PESO, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			  SET @NEWPESO = @NEWPESO + SUBSTRING(@PESO, @iCount, 1)

		  SET @iCount = @iCount + 1

	  END

	  SET @PESO = @NEWPESO

	  
	  --print 'Peso dopo'
	  --print @PESO


	  -- Superficie Gommata

	  SET @NEWSUP_GOMMATA = ''

	  SET @iCount = 1

	  WHILE (@iCount <= len(@SUP_GOMMATA))
	  BEGIN


		  IF SUBSTRING(@SUP_GOMMATA, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			  SET @NEWSUP_GOMMATA = @NEWSUP_GOMMATA + SUBSTRING(@SUP_GOMMATA, @iCount, 1)

		  SET @iCount = @iCount + 1

	  END

	  SET @SUP_GOMMATA = @NEWSUP_GOMMATA

	  -- LG

	  SET @NEWLG = ''

	  SET @iCount = 1

	  WHILE (@iCount <= len(@LG))
	  BEGIN


		  IF SUBSTRING(@LG, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			  SET @NEWLG = @NEWLG + SUBSTRING(@LG, @iCount, 1)

		  SET @iCount = @iCount + 1

	  END

	  SET @LG = @NEWLG

		
      SET @NoteXML = NULL

	  IF ISNULL(@DATA, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="6">' + @DATA + '</row>'
		  
      END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="6">' + '</row>'


	  END

      IF ISNULL(@DISEGNATOR, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="7">' + @DISEGNATOR + '</row>'
		  
      END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="7">' + '</row>'


	  END

	  IF ISNULL(@LG, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="8">' + @LG + '</row>'
		  
      END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="8">' + '</row>'

	  END

	  IF ISNULL(@MATERIALE, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="9">' + @MATERIALE + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="9">' + '</row>'

	  END

	  IF ISNULL(@NOTA_DI_TAGLIO, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="10">' + @NOTA_DI_TAGLIO + '</row>'
		  
      END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="10">' + '</row>'


	  END

	  IF ISNULL(@TRATT_TERM, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="11">' + @TRATT_TERM + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="11">' + '</row>'

	  END

	  IF ISNULL(@COMMESSA, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="12">' + @COMMESSA + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="12">' + '</row>'


	  END

	  IF ISNULL(@ATTR1, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="13">' + @ATTR1 + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="13">' + '</row>'


	  END

	  IF ISNULL(@POTENZA, '') <> '' AND @Livello = 1
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="15">' + @POTENZA + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="15">' + '</row>'

	  END

	  IF ISNULL(@N_MOTORI, '') <> '' AND @Livello = 1
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="17">' + @N_MOTORI + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="17">' + '</row>'

	  END


	  IF ISNULL(@NOME_COMM, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="18">' + @NOME_COMM + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="18">' + '</row>'


	  END

	  IF ISNULL(@LARG_MACC, '') <> '' AND @Livello = 1 AND SUBSTRING(ISNULL(@xItem, ''), 1, 1) = 'C'
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="19">' + @LARG_MACC + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="19">' + '</row>'


	  END

	  IF ISNULL(@LUNG_MACC, '') <> '' AND @Livello = 1 AND SUBSTRING(ISNULL(@xItem, ''), 1, 1) = 'C'
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="20">' + @LUNG_MACC + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="20">' + '</row>'

	  END

	  IF ISNULL(@MTPH, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="21">' + @MTPH + '</row>'
		  
	  END
	  ELSE
	  BEGIN


		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="21">' + '</row>'


	  END

	  IF ISNULL(@SUP_GOMMATA, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="22">' + @SUP_GOMMATA + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="22">' + '</row>'


	  END

	  IF ISNULL(@EX_CODICE, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="23">' + @EX_CODICE + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="23">' + '</row>'


	  END




	  IF @NoteXML IS NOT NULL
		SET @NoteXML = @NoteXML + '</rows>'


	  SET @PesoNetto = NULL

	  IF @PESO IS NULL
		SET @PesoNetto = 0
	  ELSE
	    IF ISNUMERIC(@PESO) = 1
		  SET @PesoNetto =  CAST(REPLACE(@PESO, ',' , '.') AS numeric(18,4))
		ELSE
		  SET @PesoNetto = 0

	  --print '@pesonetto'
	  --print @pesonetto

      SET @SuperficieGommata = NULL

	  IF @SUP_GOMMATA IS NULL
		SET @SuperficieGommata = 0
	  ELSE
	    IF ISNUMERIC(@SUP_GOMMATA) = 1
		  SET @SuperficieGommata = CAST(REPLACE(@SUP_GOMMATA, ',' , '.') AS numeric(18,4))
		ELSE
		  SET @SuperficieGommata = 0

      SET @LgNumero = NULL


	  IF @LG IS NULL
		SET @LgNumero = 0
	  ELSE
	    IF ISNUMERIC(@LG) = 1
		  SET @LgNumero = CAST(REPLACE(@LG, ',' , '.') AS numeric(18,4))
		ELSE
		  SET @LgNumero = 0

	  --IF @iLBavetta = 1
	  --  print @LgNumero

		
	  --print @CAT_MERC
	  --print @TIPOLOGIA

	  IF @TIPOLOGIA IS NULL
	  BEGIN
		SET @Cd_ARClasse2 = NULL
	    SET @Cd_ARClasse3 = NULL
	  END
	  ELSE
	  BEGIN
	    SET @Cd_ARClasse2 = '000'
	    SET @Cd_ARClasse3 = '000'
	  END

	  IF @CAT_MERC IS NULL
	  BEGIN

		SET @Cd_ARGruppo2 = NULL
	    SET @Cd_ARGruppo3 = NULL

	  END
	  ELSE
	  BEGIN
	    SET @Cd_ARGruppo2 = '000'
	    SET @Cd_ARGruppo3 = '000'
      END

	  SET @DBKit = 0
      SET @DBFantasma = 0
	  SET @UMAcquisto = 0

	  IF ISNULL(@CAT_MERC, '') = '' OR @CAT_MERC IN ('MOT','RID','COM','BUL','FIX','RUL','RAS','RET','GOM','TAM','OLE','MON','TEC','FUS','ELE','PAR','ATM') OR (NOT @CAT_MERC IN('MOT','RID','COM','TAP','BUL','FIX','GRI','RUL','RAS','RET','GOM','TAM','SAL','SAS','PRO','LAM','HDX','TUB','LAG','OLE','MON','TEC','FUS','ELE','PAR','ATM','SAM','SHD'))
		SET @UMAcquisto = 0
	  ELSE
	    SET @UMAcquisto = 1

	  IF @ForzaFantaKit = 1
	  BEGIN
	    SET @DBKit = 1
        SET @DBFantasma = 1
	  END
	  ELSE IF @ForzaFantaKit = 2
	  BEGIN
	    SET @DBKit = 0
        SET @DBFantasma = 1
	  END

	  ELSE
	  BEGIN

  	    SET @DBKit = 0
        SET @DBFantasma = 0

		-- DA NON FARE: Imposto a Kit e Fantasma se Esiste una distinta con 'SAL','SAS','ATM','SAM','SHD' come padre

		--IF EXISTS (SELECT 1 FROM DBMateriale 
		                    --INNER JOIN DB ON DB.Id_DB = DBMateriale.Id_DB
							--INNER JOIN AR ON AR.Cd_AR = DB.Cd_AR
							--WHERE AR.Cd_ARGruppo1 IN ('SAL','SAS','ATM','SAM','SHD')
							--AND DBMateriale.Cd_AR = @DedCodInput)
	    --BEGIN
  	      --SET @DBKit = 1
          --SET @DBFantasma = 1
		--END
							
		                                                          
        /* 22/06/2015 by guic: aggiunte le terne */
		IF ISNULL(@CAT_MERC, '') IN ('SAL','SAS','SAM','SHD')
		  SET @ForzaFantaKit = 1
		/* 14/07/2015 by guic : ForzaFantaKit 2 e codice in tabella: Inizio*/
		ELSE IF ISNULL(@CAT_MERC, '') IN ('ATM', 'TAM', 'TER')
		  SET @ForzaFantaKit = 2
        ELSE IF EXISTS (SELECT 1 FROM xDBReale WHERE Cd_AR = @DedCodInput)
          SET @ForzaFantaKit = 2
		/* 14/07/2015 by guic : ForzaFantaKit 2 e codice in tabella: Fine*/
       
		IF ISNULL(@CodPadre, '') <> ''
		BEGIN

		  --print @CodPadre + '---' + @DedCodInput

		  UPDATE AR 
		  SET DBFantasma = 1
		  WHERE Cd_AR = @CodPadre

		END

	  END

 
      IF @iLBavetta = 1 OR @iLBarraFilettata = 1
	  BEGIN
	    SET @NewDescrizione = @DedCodInput
	  END
	  ELSE IF @iLTubo = 1
	  BEGIN

	    SET @NewDescrizione = 'TUBO CORRIMANO'
		

	  END
	  ELSE
	  BEGIN
        IF @Codifica = 0
	      SET @NewDescrizione = @DESCRIZION
	    ELSE
	      SET @NewDescrizione = @CodificaCodice + ' --- ' + @DESCRIZION
	  END
	  
	  --print 'qui'

	  IF NOT EXISTS (SELECT 1 FROM AR WHERE Cd_AR = @DedCodInput)
	  BEGIN

	    --print 'not exists'



	    IF @Azione <> 'D'
		BEGIN

		  --print @DedCodInput

		  /* 01/12/2014 by guic: per bavette, barra filettata, tubo corrimano 
	      viene creato un livello in più */


		  SET @LottoRiordinoTuboBavetta = 0.0

		  IF @iLBavetta = 1
		    SET @LottoRiordinoTuboBavetta = 10.0
		  ELSE IF @iLTubo = 1
		    SET @LottoRiordinoTuboBavetta = 6.0
		  ELSE IF @iLBarraFilettata = 1
		  BEGIN

		    IF @DedCodInput = 'BARRAFILETTATAM45'
			  SET @LottoRiordinoTuboBavetta = 1.0
			ELSE IF @DedCodInput = 'BARRAFILETTATAM30'
			  SET @LottoRiordinoTuboBavetta = 3.0
			ELSE
			  SET @LottoRiordinoTuboBavetta = 1.0

		  END

          --print @DedCodInput
		  --print @xItem

		  --print 'aaaaaaaaaaaaa'
		  --print @DedCodInput
		  --print @NewDescrizione
		  --print 'aaaaaaaaaaaaa'


	      INSERT INTO AR
          (  
           --Id_AR
	         Cd_AR
           , Descrizione
           , DescrizioneBreve
           --, VBDescrizione
           --, Note_AR
           , Cd_ARGruppo1
           , Cd_ARGruppo2
           , Cd_ARGruppo3
           , Cd_ARClasse1
           , Cd_ARClasse2
           , Cd_ARClasse3
           --, Cd_VbReparto
           --, Cd_Aliquota_A
           --, Cd_Aliquota_V
           --, Cd_CGConto_VI
           --, Cd_CGConto_VE
           --, Cd_CGConto_AI
           --, Cd_CGConto_AE
           --, Cd_CAVda_VI
           --, Cd_CAVda_VE
           --, Cd_CAVda_AI
           --, Cd_CAVda_AE
           --, Cd_ARStato
           --, Cd_ARMarca
           --, Cd_ARNomenclatura
           --, Cd_ARPrdClasse
           --, Id_ARCategoria
           --, Cd_IntraServizio
           --, Modello
           --, Sconto
           --, Provvigione
           --, Ricarica
           --, ScortaMinima
           --, ScortaMassima
           --, LottoMinimo
           , LottoRiordino
           --, PesoLordo
           , PesoNetto
           --, PesoFattore
           --, PesoLordoMks
           --, PesoNettoMks
           --, Altezza
           --, Lunghezza
           --, Larghezza
           --, DimensioniFattore
           --, AltezzaMks
           --, LunghezzaMks
           --, LarghezzaMks
           --, VolumeMks
           --, CostoStandard
           --, ClasseAbc
           --, TipoValorizzazione
           --, Fittizio
           --, Obsoleto
           , DBKit
           --, NoInventario
           --, NoGiornale
           , DBFantasma
           --, MG_LottoObbligatorio
           --, MG_MatricolaObbligatoria
           --, MG_GiacenzaNonNegativa
           , TipoGestComm
           --, MrpGiorniRiordino
           --, MrpProduzioneMassima
           --, MrpIncludi
           --, MrpGiorniCopertura
           --, MrpResa
           --, MrpLottoRiordino
           --, MrpLottoMinimo
           --, MrpPuntoRiordino
           --, MrpIgnoraDistinta
           --, WebB2CPubblica
           --, WebB2BPubblica
           --, WebDescrizione
           --, WebNote_AR
           --, WebInfoLink
           --, WebGiacenza
           --, AmsManaged
           --, NoteOfferta
           --, Attributi
           , NoteXML
           --, UserIns
           --, UserUpd
           --, TimeIns
           --, TimeUpd
           --, Ts
           --, IntraTipo
		   , xCd_xStatoDED
		   , xItem
		   , xRevisione
           ) VALUES (
           --Id_AR
           @DedCodInput --Cd_AR
           , SUBSTRING(@NewDescrizione, 1 , 80)		--Descrizione
           , SUBSTRING(@NewDescrizione, 1, 40)	--DescrizioneBreve
           --,								--VBDescrizione
           --,								--Note_AR
           , @CAT_MERC		     			--Cd_ARGruppo1
           , @Cd_ARGruppo2					--Cd_ARGruppo2
           , @Cd_ARGruppo3					--Cd_ARGruppo3
           , @TIPOLOGIA		     			--Cd_ARClasse1
           , @Cd_ARClasse2					--Cd_ARClasse2
           , @Cd_ARClasse3					--Cd_ARClasse3
           --,								--Cd_VbReparto
           --,	@CommCODIVA							--Cd_Aliquota_A
           --,	@CommCODIVA							--Cd_Aliquota_V
           --,								--Cd_CGConto_VI
           --,								--Cd_CGConto_VE
           --,								--Cd_CGConto_AI
           --,								--Cd_CGConto_AE
           --,								--Cd_CAVda_VI
           --,								--Cd_CAVda_VE
           --,								--Cd_CAVda_AI
           --,								--Cd_CAVda_AE
           --,								--Cd_ARStato
           --,								--Cd_ARMarca
           --,								--Cd_ARNomenclatura
           --,								--Cd_ARPrdClasse
           --,								--Id_ARCategoria
           --,								--Cd_IntraServizio
           --,								--Modello
           --,								--Sconto
           --,								--Provvigione
           --,								--Ricarica
           --,								--ScortaMinima
           --,								--ScortaMassima
           --,								--LottoMinimo
           , @LottoRiordinoTuboBavetta		--LottoRiordino
           --,								--PesoLordo
           , @PesoNetto    					--PesoNetto
           --,								--PesoFattore
           --,								--PesoLordoMks
           --,								--PesoNettoMks  
           --,								--Altezza
           --,								--Lunghezza
           --,								--Larghezza
           --,								--DimensioniFattore
           --,								--AltezzaMks
           --,								--LunghezzaMks
           --,								--LarghezzaMks
           --,								--VolumeMks
           --,								--CostoStandard
           --,								--ClasseAbc
           --,								--TipoValorizzazione
           --,								--Fittizio
           --,								--Obsoleto
           , @DBKit  							--DBKit
           --,								--NoInventario
           --,								--NoGiornale
           , @DBFantasma						--DBFantasma
           --,								--MG_LottoObbligatorio
           --,								--MG_MatricolaObbligatoria
           --,								--MG_GiacenzaNonNegativa
           , 2								--TipoGestComm
           --,								--MrpGiorniRiordino
           --,								--MrpProduzioneMassima
           --,								--MrpIncludi
           --,								--MrpGiorniCopertura
           --,								--MrpResa
           --,								--MrpLottoRiordino
           --,								--MrpLottoMinimo
           --,								--MrpPuntoRiordino
           --,								--MrpIgnoraDistinta
           --,								--WebB2CPubblica
           --,								--WebB2BPubblica
           --,								--WebDescrizione
           --,								--WebNote_AR
           --,								--WebInfoLink 
           --,								--WebGiacenza
           --,								--AmsManaged
           --,								--NoteOfferta
           --, 								--Attributi
           ,	@NoteXML						--NoteXML
           --,								--UserIns
           --,								--UserUpd
           --,								--TimeIns
           --,								--TimeUpd
           --,								--Ts
           --,								--IntraTipo
		   , CAST (@xStatoDED AS char(3))
	       , CASE WHEN @Livello = 1 THEN @xItem ELSE NULL END
		   , CASE WHEN @Livello = 0 THEN @DEDREV ELSE @DED_xRevisione END
          )

		  SET @Severity = @@ERROR
		  IF @Severity <> 0
		  BEGIN		          	

		    SET @XErrore = 'Errore inserimento articolo'

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2

		  END
		    
		  SET @Id_AR = @@IDENTITY

		  IF NOT (@iLBavetta = 1 OR @iLTubo = 1 OR @iLBarraFilettata = 1)
		  BEGIN

	        INSERT INTO ARARMisura
	        (  Cd_AR
             , Cd_ARMisura
             , TipoARMisura
             , UMFatt
             , DefaultMisura
             --, Riga
             --, UserIns
             --, UserUpd
             --, TimeIns
             --, TimeUpd
             --, Ts
	        ) VALUES (
	          @DedCodInput
	          --@ArticoliMetodoUMCODART			-- Cd_AR
	        , 'NR'             -- Cd_ARMisura
	        , ''
            , 1.0
            , 1
            --, Riga
            --, UserIns
            --, UserUpd
            --, TimeIns
            --, TimeUpd
            --, Ts
	        )

		    SET @Severity = @@ERROR
		    IF @Severity <> 0
		    BEGIN		     

	          IF @Transaction = 1
	            GOTO labelExit
	          ELSE
	            GOTO labelExit2

		    END


		    IF @UMAcquisto = 1
		    BEGIN

	          IF @CAT_MERC = 'LAG' AND ISNULL(@SuperficieGommata,0) <> 0
              BEGIN

		        INSERT INTO ARARMisura
	            (  Cd_AR
                 , Cd_ARMisura
                 , TipoARMisura
                 , UMFatt
                 , DefaultMisura
                 --, Riga
                 --, UserIns
                 --, UserUpd
                 --, TimeIns
                 --, TimeUpd
                 --, Ts
	            ) VALUES (
	               @DedCodInput
	               --@ArticoliMetodoUMCODART			-- Cd_AR
	             , 'MQ'             -- Cd_ARMisura
	             , 'A'
                 , (1.0 / @SuperficieGommata)
                 , 0
                 --, Riga
                 --, UserIns
                 --, UserUpd
                 --, TimeIns
                 --, TimeUpd
                 --, Ts
	            )

			    SET @Severity = @@ERROR
		        IF @Severity <> 0
			    BEGIN

    	          IF @Transaction = 1
	                GOTO labelExit
  	              ELSE
	                GOTO labelExit2

			    END

		      END


		      IF @CAT_MERC = 'TAP' AND ISNULL(@LgNumero ,0) <> 0
              BEGIN

  	            INSERT INTO ARARMisura
	            (  Cd_AR
                 , Cd_ARMisura
                 , TipoARMisura
                 , UMFatt
                 , DefaultMisura
                 --, Riga
                 --, UserIns
                 --, UserUpd
                 --, TimeIns
                 --, TimeUpd
                 --, Ts
	            ) VALUES (
	               @DedCodInput
	               --@ArticoliMetodoUMCODART			-- Cd_AR
	             , 'MT'             -- Cd_ARMisura
	             , 'A'
                 , (1.0 / @LgNumero)
                 , 0
                 --, Riga
                 --, UserIns
                 --, UserUpd
                 --, TimeIns
                 --, TimeUpd
                 --, Ts
	            )

 		        SET @Severity = @@ERROR
		        IF @Severity <> 0
			    BEGIN		        

	              IF @Transaction = 1
	                GOTO labelExit
	              ELSE
	                GOTO labelExit2

			    END

              END

		      IF @CAT_MERC = 'GRI' AND ISNULL(@LgNumero ,0) <> 0
              BEGIN

  	            INSERT INTO ARARMisura
	            (  Cd_AR
                 , Cd_ARMisura
                 , TipoARMisura
                 , UMFatt
                 , DefaultMisura
                 --, Riga
                 --, UserIns
                 --, UserUpd
                 --, TimeIns
                 --, TimeUpd
                 --, Ts
	            ) VALUES (
	               @DedCodInput
	               --@ArticoliMetodoUMCODART			-- Cd_AR
	             , 'MT'             -- Cd_ARMisura
	             , 'A'
                 , (1.0 / (@LgNumero / 1000.0))
                 , 0
                 --, Riga
                 --, UserIns
                 --, UserUpd
                 --, TimeIns
                 --, TimeUpd
                 --, Ts
	            )

 		        SET @Severity = @@ERROR
		        IF @Severity <> 0
			    BEGIN

   	              IF @Transaction = 1
	                GOTO labelExit
	              ELSE
	                GOTO labelExit2
			    END


		      END

	          IF @CAT_MERC NOT IN ('LAG','TAP','GRI') AND ISNULL(@PesoNetto,0) <> 0
              BEGIN

		        INSERT INTO ARARMisura
	            (  Cd_AR
                 , Cd_ARMisura
                 , TipoARMisura
                 , UMFatt
                 , DefaultMisura
                 --, Riga
                 --, UserIns
                 --, UserUpd
                 --, TimeIns
                 --, TimeUpd
                 --, Ts
	            ) VALUES (
	               @DedCodInput
	               --@ArticoliMetodoUMCODART			-- Cd_AR
	             , 'KG'             -- Cd_ARMisura
	             , 'A'
                 , (1.0 / @PesoNetto)
                 , 0
                 --, Riga
                 --, UserIns
                 --, UserUpd
                 --, TimeIns
                 --, TimeUpd
                 --, Ts
	            )

			    SET @Severity = @@ERROR
		        IF @Severity <> 0
			    BEGIN

   	              IF @Transaction = 1
	                GOTO labelExit
	              ELSE
	                GOTO labelExit2

		         END 
		      
			  END

			END

		  END
		  ELSE  /* @iLBavetta = 1 OR @iLTubo = 1 OR @iLBarraFilettata */
		  BEGIN

		    INSERT INTO ARARMisura
	          (  Cd_AR
               , Cd_ARMisura
               , TipoARMisura
               , UMFatt
               , DefaultMisura
               --, Riga
               --, UserIns
               --, UserUpd
               --, TimeIns
               --, TimeUpd
               --, Ts
	          ) VALUES (
	            @DedCodInput
	            --@ArticoliMetodoUMCODART			-- Cd_AR
	          , 'MT'             -- Cd_ARMisura
	          , ''
              , 1.0
              , 1
              --, Riga
              --, UserIns
              --, UserUpd
              --, TimeIns
              --, TimeUpd
              --, Ts
	          )

		    SET @Severity = @@ERROR
		    IF @Severity <> 0
		    BEGIN		     

	          IF @Transaction = 1
	            GOTO labelExit
	          ELSE
	            GOTO labelExit2

		    END

			SET @FattoreTuboBavetta = 1.0

			IF @iLBavetta = 1
			  SET @FattoreTuboBavetta = 10.0
			ELSE IF @iLTubo = 1
			  SET @FattoreTuboBavetta = 6.0
			ELSE IF @iLBarraFilettata = 1
			BEGIN
		      IF @DedCodInput = 'BARRAFILETTATAM45'
			    SET @FattoreTuboBavetta = 1.0
			  ELSE IF @DedCodInput = 'BARRAFILETTATAM30'
			    SET @FattoreTuboBavetta = 3.0
              ELSE
			    SET @FattoreTuboBavetta = 1.0
			END


			INSERT INTO ARARMisura
	        (  Cd_AR
             , Cd_ARMisura
             , TipoARMisura
             , UMFatt
             , DefaultMisura
             --, Riga
             --, UserIns
             --, UserUpd
             --, TimeIns
             --, TimeUpd
             --, Ts
	        ) VALUES (
	           @DedCodInput
	           --@ArticoliMetodoUMCODART			-- Cd_AR
	         , 'NR'             -- Cd_ARMisura
	         , 'A'
             , @FattoreTuboBavetta
             , 0
             --, Riga
             --, UserIns
             --, UserUpd
             --, TimeIns
             --, TimeUpd
             --, Ts
	        )

 		    SET @Severity = @@ERROR
		    IF @Severity <> 0
			BEGIN		        

	          IF @Transaction = 1
	            GOTO labelExit
	          ELSE
	            GOTO labelExit2

			END

		  END

		END
      END
	  ELSE IF @Azione <> 'D' AND (NOT @iLBAvetta = 1) AND (NOT @iLTubo = 1) AND (NOT @iLBarraFilettata = 1)
	  BEGIN

	    --print 'else'

	    SELECT @Id_AR = AR.ID_AR
		FROM AR
		WHERE Cd_AR = @DedCodInput

		IF @@ROWCOUNT <> 1
		BEGIN

		  SET @Severity = 16

	      IF @Transaction = 1
	        GOTO labelExit
	      ELSE
	        GOTO labelExit2


		END

		--SET @DBKitCheck = 0
	    --SET @DBFantasmaCheck = 0

		--SELECT @DBKitCheck = DBKit
	    --   ,   @DBFantasmaCheck = DBFantasma
		--FROM AR 
		--WHERE Cd_AR = @DedCodInput


		--IF (@DBKitCheck IS NULL) OR (@DBFantasmaCheck IS NULL)
		--BEGIN
  		--  SET @DBKitCheck = 0
	    --  SET @DBFantasmaCheck = 0
		--END

		--IF (@DBKit <> @DBKitCheck) OR (@DBFantasma <> @DBFantasmaCheck)
		--BEGIN
		    --SET @Severity = 16

			--SET @XErrore = 'Prodotto ' + @DedCodInput + ' gia presente ma Flag Kit o Fantasma non coerente.'

	        --IF @Transaction = 1
	          --GOTO labelExit
	        --ELSE
	          --GOTO labelExit2


		--END

		--print @xItem
        
	    UPDATE AR
		SET --Id_AR                       = Id_AR
	          Descrizione                 = SUBSTRING(@NewDescrizione,1 , 80)
            , DescrizioneBreve            = SUBSTRING(@NewDescrizione, 1, 40)
              --, VBDescrizione           = 
              --, Note_AR                 =
            , Cd_ARGruppo1                = @CAT_MERC
            , Cd_ARGruppo2                = @Cd_ARGruppo2
            , Cd_ARGruppo3                = @Cd_ARGruppo3
            , Cd_ARClasse1                = @TIPOLOGIA
            , Cd_ARClasse2                = @Cd_ARClasse2
            , Cd_ARClasse3                = @Cd_ARClasse3
            --, Cd_VbReparto              = 
            --, Cd_Aliquota_A             = @CommCODIVA
            --, Cd_Aliquota_V             = @CommCODIVA
            --, Cd_CGConto_VI             =
            --, Cd_CGConto_VE             =
            --, Cd_CGConto_AI             =
            --, Cd_CGConto_AE             =
            --, Cd_CAVda_VI               =            
		    --, Cd_CAVda_VE               =
            --, Cd_CAVda_AI               =
            --, Cd_CAVda_AE               =
            --, Cd_ARStato                =
            --, Cd_ARMarca                =
            --, Cd_ARNomenclatura         =
            --, Cd_ARPrdClasse            =
            --, Id_ARCategoria            =
            --, Cd_IntraServizio          =
            --, Modello                   =
            --, Sconto                    =
            --, Provvigione               =
            --, Ricarica                  =
            --, ScortaMinima              =
            --, ScortaMassima             =
            --, LottoMinimo               =
            --, LottoRiordino             =  ##### da non mettere in update #####
            --, PesoLordo                 =
            , PesoNetto                   = @PesoNetto
            --, PesoFattore               =
            --, PesoLordoMks              =
            --, PesoNettoMks              =
            --, Altezza                   =
            --, Lunghezza                 =
            --, Larghezza                 =
            --, DimensioniFattore         =
            --, AltezzaMks                =
            --, LunghezzaMks              =
            --, LarghezzaMks              =
            --, VolumeMks                 =
            --, CostoStandard             = 
            --, ClasseAbc                 =
            --, TipoValorizzazione        =
            --, Fittizio                  =
            --, Obsoleto                  =
              , DBKit                     = @DBKit
            --, NoInventario              =
            --, NoGiornale                =
              , DBFantasma                = @DBFantasma
            --, MG_LottoObbligatorio      =
            --, MG_MatricolaObbligatoria  =
            --, MG_GiacenzaNonNegativa    =
            , TipoGestComm                = 2
            --, MrpGiorniRiordino         =
            --, MrpProduzioneMassima      =
            --, MrpIncludi                =
            --, MrpGiorniCopertura        =
            --, MrpResa                   =
            --, MrpLottoRiordino          =
            --, MrpLottoMinimo            =
            --, MrpPuntoRiordino          =
            --, MrpIgnoraDistinta         =
            --, WebB2CPubblica            =
            --, WebB2BPubblica            =
            --, WebDescrizione            =
            --, WebNote_AR                =
            --, WebInfoLink               =
            --, WebGiacenza               =
            --, AmsManaged                =
            --, NoteOfferta               =
            --, Attributi                 =
            , NoteXML                     = @NoteXML
            --, UserIns                   =
            --, UserUpd                   =
            --, TimeIns                   =
            --, TimeUpd                   =
            --, Ts                        =
            --, IntraTipo                 =
		    , xCd_xStatoDED = CAST (@xStatoDED AS char(3))
	        , xItem = CASE WHEN @Livello = 1 THEN @xItem ELSE NULL END
			, xRevisione = CASE WHEN @Livello = 0 THEN @DEDREV ELSE @DED_xRevisione END


		WHERE Cd_AR = @DedCodInput

		

		SET @Severity = @@ERROR
		IF @Severity <> 0
		BEGIN

	      IF @Transaction = 1
	        GOTO labelExit
	      ELSE
	        GOTO labelExit2

		END

        IF NOT EXISTS (SELECT 1 FROM ARARMisura
		               WHERE Cd_AR = @DedCodInput
					     AND Cd_ARMisura = 'NR')
		BEGIN
					   		
		  INSERT INTO ARARMisura
	      (  Cd_AR
           , Cd_ARMisura
           , TipoARMisura
           , UMFatt
           , DefaultMisura
           --, Riga
           --, UserIns
           --, UserUpd
           --, TimeIns
           --, TimeUpd
           --, Ts
	      ) VALUES (
	        @DedCodInput
	        --@ArticoliMetodoUMCODART			-- Cd_AR
	      , 'NR'             -- Cd_ARMisura
	      , ''
          , 1.0
          , 1
          --, Riga
          --, UserIns
          --, UserUpd
          --, TimeIns
          --, TimeUpd
          --, Ts
	      )

		  SET @Severity = @@ERROR
		  IF @Severity <> 0
	      BEGIN

  	         IF @Transaction = 1
	           GOTO labelExit
	         ELSE
	           GOTO labelExit2
	      END

	    END

		IF @UMAcquisto = 1
		BEGIN

	      IF @CAT_MERC = 'LAG' AND ISNULL(@SuperficieGommata,0) <> 0
          BEGIN

		    IF EXISTS (SELECT 1 FROM ARARMisura WHERE Cd_AR = @DedCodInput
			                                      AND Cd_ARMisura <> 'MQ'
												  AND TipoARMisura = 'A')
	        BEGIN

			  UPDATE ARARMisura SET TipoARMisura = ''
		      WHERE Cd_AR = @DedCodInput
			    AND Cd_ARMisura <> 'MQ'
				AND TipoARMisura = 'A'

   		      SET @Severity = @@ERROR
		      IF @Severity <> 0
			  BEGIN

    	        IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2

              END

			END


            IF NOT EXISTS (SELECT 1 FROM ARARMisura
		                   WHERE Cd_AR = @DedCodInput
			    		     AND Cd_ARMisura = 'MQ')
	        BEGIN


		      INSERT INTO ARARMisura
  	            (  Cd_AR
                 , Cd_ARMisura
                 , TipoARMisura
                 , UMFatt
                 , DefaultMisura
                 --, Riga
                 --, UserIns
                 --, UserUpd
                 --, TimeIns
                 --, TimeUpd
                 --, Ts
	            ) VALUES (
	               @DedCodInput
	               --@ArticoliMetodoUMCODART			-- Cd_AR
	             , 'MQ'             -- Cd_ARMisura
	             , 'A'
                 , (1.0 / @SuperficieGommata)
                 , 0
                 --, Riga
                 --, UserIns
                 --, UserUpd
                 --, TimeIns
                 --, TimeUpd
                 --, Ts
	            )

 		        SET @Severity = @@ERROR
		        IF @Severity <> 0
				BEGIN

  	              IF @Transaction = 1
	                GOTO labelExit
	              ELSE
	                GOTO labelExit2
				END
		          

		    END		  
		    ELSE
		    BEGIN

		      UPDATE ARARMisura
			  SET UMFatt = (1.0 / @SuperficieGommata)
			  /* 25/06/2015 by guic: Begin */
			    , TipoARMisura = 'A'
			  /* 25/06/2015 by guic: End */
			  WHERE Cd_AR = @DedCodInput
			        AND Cd_ARMisura = 'MQ'

 		      SET @Severity = @@ERROR
		      IF @Severity <> 0
			  BEGIN

    	        IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2

               END
		    END

		  END

		  IF @CAT_MERC = 'TAP' AND ISNULL(@LgNumero ,0) <> 0
          BEGIN

		    IF EXISTS (SELECT 1 FROM ARARMisura WHERE Cd_AR = @DedCodInput
			                                      AND Cd_ARMisura <> 'MT'
												  AND TipoARMisura = 'A')
	        BEGIN

			  UPDATE ARARMisura SET TipoARMisura = ''
		      WHERE Cd_AR = @DedCodInput
			    AND Cd_ARMisura <> 'MT'
				AND TipoARMisura = 'A'

   		      SET @Severity = @@ERROR
		      IF @Severity <> 0
			  BEGIN

    	        IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2

              END

			END


		    IF NOT EXISTS (SELECT 1 FROM ARARMisura
		                   WHERE Cd_AR = @DedCodInput
			    		     AND Cd_ARMisura = 'MT')
			BEGIN


    	        INSERT INTO ARARMisura
	          (  Cd_AR
               , Cd_ARMisura
               , TipoARMisura
               , UMFatt
               , DefaultMisura
               --, Riga
               --, UserIns
               --, UserUpd
               --, TimeIns
               --, TimeUpd
               --, Ts
	          ) VALUES (
	             @DedCodInput
	             --@ArticoliMetodoUMCODART			-- Cd_AR
	           , 'MT'             -- Cd_ARMisura
	           , 'A'
               , (1.0 / @LgNumero)
               , 0
               --, Riga
               --, UserIns
               --, UserUpd
               --, TimeIns
               --, TimeUpd
               --, Ts
	          )

			  SET @Severity = @@ERROR
		      IF @Severity <> 0
			  BEGIN

	            IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2


			  END		        

			END
			ELSE
			BEGIN

		      UPDATE ARARMisura
			  SET UMFatt = (1.0 / @LgNumero)
			  /* 25/06/2015 by guic: Begin */
			    , TipoARMisura = 'A'
			  /* 25/06/2015 by guic: End */

			  WHERE Cd_AR = @DedCodInput
			        AND Cd_ARMisura = 'MT'

 		      SET @Severity = @@ERROR
		      IF @Severity <> 0
			  BEGIN

  	            IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2

			  END
		        
			END

          END

		  IF @CAT_MERC = 'GRI' AND ISNULL(@LgNumero ,0) <> 0
          BEGIN

		    IF EXISTS (SELECT 1 FROM ARARMisura WHERE Cd_AR = @DedCodInput
			                                      AND Cd_ARMisura <> 'MT'
												  AND TipoARMisura = 'A')
	        BEGIN

			  UPDATE ARARMisura SET TipoARMisura = ''
		      WHERE Cd_AR = @DedCodInput
			    AND Cd_ARMisura <> 'MT'
				AND TipoARMisura = 'A'

   		      SET @Severity = @@ERROR
		      IF @Severity <> 0
			  BEGIN

    	        IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2

              END

			END


		    IF NOT EXISTS (SELECT 1 FROM ARARMisura
		                   WHERE Cd_AR = @DedCodInput
			    		     AND Cd_ARMisura = 'MT')
			BEGIN

  	          INSERT INTO ARARMisura
	          (  Cd_AR
               , Cd_ARMisura
               , TipoARMisura
               , UMFatt
               , DefaultMisura
               --, Riga
               --, UserIns
               --, UserUpd
               --, TimeIns
               --, TimeUpd
               --, Ts
	          ) VALUES (
	             @DedCodInput
	             --@ArticoliMetodoUMCODART			-- Cd_AR
	           , 'MT'             -- Cd_ARMisura
	           , 'A'
               , (1.0 / (@LgNumero / 1000.0))
               , 0
               --, Riga
               --, UserIns
               --, UserUpd
               --, TimeIns
               --, TimeUpd
               --, Ts
	          )

 		      SET @Severity = @@ERROR
		      IF @Severity <> 0
			  BEGIN

	            IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2
			  END
		        

		    END
			ELSE
			BEGIN

		      UPDATE ARARMisura
			  SET UMFatt = (1.0 / (@LgNumero / 1000.0))
			  /* 25/06/2015 by guic: Begin */
			    , TipoARMisura = 'A'
			  /* 25/06/2015 by guic: End */

			  WHERE Cd_AR = @DedCodInput
			        AND Cd_ARMisura = 'MT'

 		      SET @Severity = @@ERROR
		      IF @Severity <> 0
			  BEGIN

	            IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2
			  END

			END
          END

		  IF @CAT_MERC NOT IN ('LAG','TAP','GRI') AND ISNULL(@PesoNetto,0) <> 0
          BEGIN

		    IF EXISTS (SELECT 1 FROM ARARMisura WHERE Cd_AR = @DedCodInput
			                                      AND Cd_ARMisura <> 'KG'
												  AND TipoARMisura = 'A')
	        BEGIN

			  UPDATE ARARMisura SET TipoARMisura = ''
		      WHERE Cd_AR = @DedCodInput
			    AND Cd_ARMisura <> 'KG'
				AND TipoARMisura = 'A'

   		      SET @Severity = @@ERROR
		      IF @Severity <> 0
			  BEGIN

    	        IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2

              END

			END


		  	IF NOT EXISTS (SELECT 1 FROM ARARMisura
		                   WHERE Cd_AR = @DedCodInput
			    		     AND Cd_ARMisura = 'KG')
			BEGIN

		      INSERT INTO ARARMisura
	          (  Cd_AR
               , Cd_ARMisura
               , TipoARMisura
               , UMFatt
               , DefaultMisura
               --, Riga
               --, UserIns
               --, UserUpd
               --, TimeIns
               --, TimeUpd
               --, Ts
	          ) VALUES (
	             @DedCodInput
	             --@ArticoliMetodoUMCODART			-- Cd_AR
	           , 'KG'             -- Cd_ARMisura
	           , 'A'
               , (1.0 / @PesoNetto)
               , 0
               --, Riga
               --, UserIns
               --, UserUpd
               --, TimeIns
               --, TimeUpd
               --, Ts
	          )

			  SET @Severity = @@ERROR
		      IF @Severity <> 0
			  BEGIN

	            IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2
			  END

		    END
			ELSE
			BEGIN

		      UPDATE ARARMisura
			  SET UMFatt = (1.0 / @PesoNetto)
			  /* 25/06/2015 by guic: Begin */
			    , TipoARMisura = 'A'
			  /* 25/06/2015 by guic: End */

			  WHERE Cd_AR = @DedCodInput
			        AND Cd_ARMisura = 'KG'

 		      SET @Severity = @@ERROR
		      IF @Severity <> 0
			  BEGIN

	            IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2
			  END

			END
		  END

		  
        END
		/* 25/06/2015 by guic: Begin */
		/*IF @UMAcquisto = 1*/
		ELSE		

		BEGIN

          UPDATE ARARMisura
		  SET TipoARMisura = ''
		  WHERE Cd_AR = @DedCodInput
	        AND Cd_ARMisura <> 'NR'

		  SET @Severity = @@ERROR
		  IF @Severity <> 0
		  BEGIN

  	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2
		  END

		END

		/* 25/06/2015 by guic: End */

	  END     	

	  IF @Azione <> 'D'
	  BEGIN

	    SET @CheckDIBA = 0


	    IF NOT EXISTS (SELECT 1 FROM DB WHERE Cd_AR = @DedCodInput)
	    BEGIN
		  
       
	      IF EXISTS(SELECT 1 FROM GESTIONALE.[QS_DED_PLUS].dbo.DED_BOM WHERE DED_BOM.DEDIDP = @DEDID
		                                                    AND DED_BOM.DEDREVP = @DEDREV
															AND ISNULL(DED_BOM.DEDIDC, '') <> ''														
														    AND ISNULL(DED_BOM.CREATIONDATE , (@DistDate + 1)) < @DistDate
															AND ISNULL(DED_BOM.VALIDDATE, (@DistDate - 1)) >= @DistDate)

                                                         

	      BEGIN

		      --print '@CheckCrea'
            			
			  INSERT INTO DB
              (
		        --Id_DB
	            Cd_AR
	          , InizioValidita
	          , FineValidita)
              VALUES (
  		        --, 
		        @DedCodInput
              , '01/01/2001'
	          , NULL
		      )

              SET @IdDb = @@IDENTITY

			
	      END
        END


	    ELSE
	    BEGIN

			-- non c'è niente da modificare su DB

			-- check distinta base			

			SELECT TOP 1 @IDDBCheck =  Id_DB FROM DB WHERE Cd_AR = @DedCodInput

			IF @@ROWCOUNT = 1
			BEGIN
			  

		      EXEC @Severity = xDEDCheckDIBASp @DEDID = @DEDID
			                                 , @DEDREV = @DEDREV
											 , @IDDBCheck = @IDDBCheck
			                                 , @CheckDIBA = @CheckDIBA OUTPUT 
											 , @DistDate = @DistDate
											 , @UltRev = @UltRev
											 , @StoreRadice = @StoreRadice	

		      IF @Severity <> 0
	          BEGIN
			     
			    --print 'Errore'			

	            IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2

    	      END

											 
			  --INSERT INTO @TTLog (lMessage) SELECT lMessage FROM #TTlog

			  

			  --print '@CheckDIBA'
			  --print @CheckDIBA

			END

		    SELECT TOP 1 @IdDb = DB.Id_DB FROM DB
      			   WHERE Cd_AR = @DedCodInput


			IF @CheckDIBA = 0
			BEGIN

              DELETE FROM DBMateriale
	             WHERE Id_DB = @IdDb

			END

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



		ORDER BY DED_BOM.DEDIDC

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

		  IF @Q <= 0
		  BEGIN

		    print 'Errore qta 0 '
			print 'Articolo padre ' + @DEDIDP
			print 'Articolo figlio ' + @DEDIDC

		  END

          
		  SET @DedCodFiglio = NULL

		  IF @UltRev = 1
   	      BEGIN

		    SELECT TOP 1 @DedCodFiglio = DED_COD
			           , @DedCodFiglioCatMerc = CAT_MERC
				  	   , @DedCodFiglioDescrizione = DEDDESC
					   , @DedCodFiglioNotadiTaglio = NOTA_DI_TAGLIO
			             FROM GESTIONALE.[QS_DED_PLUS].dbo.DED_DATA			              
		                 WHERE DEDID = @DEDIDC
						 AND ISNULL(DEDREVDATE, @DistDate - 1) < @DistDate
					       --AND DEDREV = @DEDREVC	
					     ORDER BY CAST(DEDREV AS Int) DESC
	      END
		  ELSE
		  BEGIN 

		    SELECT TOP 1 @DedCodFiglio = DED_COD
			           , @DedCodFiglioCatMerc = CAT_MERC
				  	   , @DedCodFiglioDescrizione = DEDDESC
					   , @DedCodFiglioNotadiTaglio = NOTA_DI_TAGLIO
			             FROM GESTIONALE.[QS_DED_PLUS].dbo.DED_DATA			              
		                 WHERE DEDID = @DEDIDC
					       AND DEDREV = @DEDREVC	
					       ORDER BY DEDREV DESC
		  END				 

  		  IF LTRIM(RTRIM(ISNULL(@DedCodFiglio,''))) = ''
		    CONTINUE

	      ---print @DedDis + ' ### ' + @F

		  SET @NewLivello = @Livello + 1

		  EXEC @Severity = xDEDCreaArticoloSp 
		                     @DedId = @DEDIDC
					       , @DedRev = @DEDREVC
	   		      	       , @Transaction = 0
			     	       , @Azione = @Azione
						   , @ForzaFantaKit = @ForzaFantaKit
						   , @CodPadre = @DedCodInput 
						   , @XErrore = @XErrore OUTPUT
						   , @DistDate = @DistDate
                           , @UltRev = @UltRev
						   , @UltBBT = 0
						   , @DedIdPadre = @DedIdPadre
						   , @Livello = @NewLivello




		  IF @Severity <> 0
	      BEGIN
			     
			--print 'Errore'			

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2

	      END

		  IF @Severity = 0
		  BEGIN
		    

			
			SET @DedCodFiglio = upper(@DedCodFiglio)

        	-- I bulloni dentro assiemi saldati, tamburi, ecc. sono divisi da quelli liberi e creati con codice con suffisso _K
	        IF  @DedCodFiglioCatMerc IN('BUL', 'OLE', 'COM', 'GOM') AND @ForzaFantaKit = 1
	          SET @DedCodFiglio = @DedCodFiglio + '_K'

			
			--guic: codifica
			IF EXISTS (SELECT 1 FROM xCodifica WHERE codice = @DedCodFiglio)
	        BEGIN

		      SELECT TOP 1 @DedCodFiglio = codifica FROM xCodifica WHERE codice = @DedCodFiglio

            END

		   
			SET @UMMateriale = 'NR'			


--###############			IF EXISTS (SELECT 1 FROM DBMateriale WHERE Id_DB = @IdDb
--###############	                                               AND Cd_AR = @DedCodFiglio
--###############												   AND Consumo = @Q
--###############	                                               AND DivisoreConsumo = 1.0
--###############	                                               AND Cd_ARMisura = @UMMateriale
--###############	                                               AND FattoreToUM1 = 1.0
--###############	                                               AND InizioValidita = '01/01/2001'
--###############	                                               AND FineValidita = NULL)
--###############		      CONTINUE

--###############			ELSE IF EXISTS (SELECT 1 FROM DBMateriale WHERE Id_DB = @IdDb
--###############	                                               AND Cd_AR = @DedCodFiglio)
--###############	        BEGIN

--###############			  UPDATE DBMateriale 
--###############			    SET Consumo = @Q
--###############	              , DivisoreConsumo = 1.0
--###############	              , Cd_ARMisura = @UMMateriale
--###############	              , FattoreToUM1 = 1.0
--###############	              , InizioValidita = '01/01/2001'
--###############	              , FineValidita = NULL
--###############		      WHERE Id_DB = @IdDb
--###############	            AND Cd_AR = @DedCodFiglio

--###############			  SET @Severity = @@ERROR
--###############		      IF @Severity <> 0
--###############			  BEGIN

--###############	            IF @Transaction = 1
--###############	              GOTO labelExit
--###############	            ELSE
--###############	              GOTO labelExit2

--###############			  END


--###############			END

--###############			ELSE
--###############			BEGIN	         	        	       	          

			IF @CheckDIBA = 0
			BEGIN
			
			  SET @Sequenza = 0

			  SELECT TOP 1 @Sequenza = Sequenza 
			  FROM DBMateriale
			  WHERE Id_DB = @IdDb
			  ORDER BY Sequenza DESC
			  
			  IF @@ROWCOUNT = 0
			    SET @Sequenza = 0
				
		      SET @Sequenza = @Sequenza + 1

		      --print @DedCodFiglio
		      --print @F
			 			  
		      INSERT INTO DBMateriale
		      (	
		         --Id_DBMateriale
	             Id_DB
	           , Cd_AR
	           , Consumo
	           , DivisoreConsumo
	           , Cd_ARMisura
	           , FattoreToUM1
	           --, ConsumoUM1
	           --, Sfrido
	           --, Opzionale
	           , InizioValidita
	           , FineValidita
	           --, NoteDBMateriale
	           , Sequenza
	           --, UserIns
	           --, UserUpd
	           --, TimeIns
	           --, TimeUpd
	           --, Ts
	          )
	          VALUES
	          (
		       --Id_DBMateriale
	             @IdDb --, Id_DB
	           , @DedCodFiglio --, Cd_AR
	           , @Q --@Q
	           , 1.0
	           , @UMMateriale --, Cd_ARMisura
	           , 1.0 --, FattoreToUM1
	           --, @Q --ConsumoUM1
	           --, Sfrido
	           --, Opzionale
	           , '01/01/2001' --, InizioValidita
	           , NULL --FineValidita  
	           --, NoteDBMateriale
	           , @Sequenza
	           --, UserIns
	           --, UserUpd
	           --, TimeIns
	           --, TimeUpd
	           --, Ts		  
		      )

			  SET @Severity = @@ERROR
		      IF @Severity <> 0
			  BEGIN

	            IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2
		      END

			END
	      END
		END

		CLOSE DedBomCrs
		DEALLOCATE DedBomCrs
	  

	    IF @UltBBT = 0 AND (@iLBavetta2 = 1 OR @iLBarraFilettata2 = 1 OR @iLTubo2 = 1)
	    BEGIN

		  EXEC @Severity = xDEDCreaArticoloSp 
		                   @DedId = @DEDID
		                 , @DedRev = @DEDREV
	   		             , @Transaction = 0
			     	     , @Azione = @Azione
			             , @ForzaFantaKit = @ForzaFantaKit
					     , @CodPadre = @DedCodInput 
						 , @XErrore = @XErrore OUTPUT
					     , @DistDate = @DistDate
                         , @UltRev = @UltRev
					     , @UltBBT = 1
						 , @DedIdPadre = @DedIdPadre

          IF @Severity <> 0
	      BEGIN
			     
			--print 'Errore'			

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2

	      END

	      SELECT TOP 1 @DedCodFiglio = DED_COD
			         , @DedCodFiglioCatMerc = CAT_MERC
				  	 , @DedCodFiglioDescrizione = DEDDESC
					 , @DedCodFiglioNotadiTaglio = NOTA_DI_TAGLIO
			         FROM GESTIONALE.[QS_DED_PLUS].dbo.DED_DATA			              
		             WHERE DEDID = @DEDID
					   AND DEDREV = @DEDREV
					       


		  IF (((@DedCodFiglioCatMerc = 'GOM') AND LTRIM(RTRIM(@DedCodFiglioNotadiTaglio)) LIKE 'Bavetta%' AND LTRIM(RTRIM(@DedCodFiglioDescrizione)) LIKE 'Bavetta%') OR
		  ((LTRIM(RTRIM(@DedCodFiglioDescrizione)) LIKE 'TUBO%CORRIMANO%') AND @DedCodFiglioCatMerc = 'TUB') OR
	      ((@DedCodFiglioCatMerc = 'BUL') AND LTRIM(RTRIM(@DedCodFiglioNotadiTaglio)) LIKE 'Barra Filettata%'))

	      --IF (@DedCodFiglio LIKE 'Bavetta%' OR @DedCodFiglio LIKE 'Tubo')
	      BEGIN

			  
			-- calcolo lunghezza

			SET @LGFIGLIO = NULL


			SELECT TOP 1 @LGFIGLIO = LG FROM GESTIONALE.[QS_DED_PLUS].dbo.DED_DATA WHERE DEDID = @DEDID			      
				                                                        AND DEDREV = @DEDREV

  
         	SET @NEWLGFIGLIO = ''

	        SET @iCount = 1

	        WHILE (@iCount <= len(@LGFIGLIO))
	        BEGIN


		       IF SUBSTRING(@LGFIGLIO, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			     SET @NEWLGFIGLIO = @NEWLGFIGLIO + SUBSTRING(@LGFIGLIO, @iCount, 1)

		       SET @iCount = @iCount + 1

	        END

	        SET @LGFIGLIO = @NEWLGFIGLIO

			SET @LgNumeroFiglio = NULL

	        IF @LGFIGLIO IS NULL
		      SET @LgNumeroFiglio = 0
	        ELSE
	          IF ISNUMERIC(@LGFIGLIO) = 1
		        SET @LgNumeroFiglio = CAST(REPLACE(@LGFIGLIO, ',' , '.') AS numeric(18,4))
		      ELSE
		        SET @LgNumeroFiglio = 0

         

			SET @Q =  @LgNumeroFiglio / 1000.0

  			SET @UMMateriale = 'MT'

			/* 02/02/2015 per bavette e simili l'unità di misura in distinta deve essere il numero: NON E' VERO */

  			/*SET @UMMateriale = 'NR'

			SET @QTemp = 1

			SELECT @QTemp = UMFatt FROM ARARmisura 
			WHERE Cd_AR = @DedBavBaTubSave
			  AND Cd_ARMisura = 'NR'

			IF ISNULL(@QTemp, 0) <> 0
			  SET @QTemp = 1.0 / @QTemp
			ELSE
			  SET @QTemp = 1.0

			--print @DedCodInput
			--print @QTemp
			

			SET @Q =  @LgNumeroFiglio / 1000.0 * @QTemp*/


		    IF NOT EXISTS (SELECT 1 FROM DB WHERE Cd_AR = @DedCodInput)
	        BEGIN
		                     			
			  INSERT INTO DB
              (
		        --Id_DB
	            Cd_AR
	          , InizioValidita
	          , FineValidita)
              VALUES (
  		        --, 
		        @DedCodInput
              , '01/01/2001'
	          , NULL
	          )
			     		            

              SET @IdDb = @@IDENTITY

		    END
			ELSE
		      SELECT TOP 1 @IdDb = DB.Id_DB FROM DB
      		  WHERE Cd_AR = @DedCodInput

			DELETE FROM DBMateriale
	        WHERE Id_DB = @IdDb



		    SET @Sequenza = 0

			SELECT TOP 1 @Sequenza = Sequenza 
			FROM DBMateriale
			WHERE Id_DB = @IdDb
			ORDER BY Sequenza DESC
			  
			IF @@ROWCOUNT = 0
			  SET @Sequenza = 0
				
		    SET @Sequenza = @Sequenza + 1

		    --print @DedCodFiglio
		    --print @F
			 			  
		    INSERT INTO DBMateriale
		    (	
		       --Id_DBMateriale
	           Id_DB
	         , Cd_AR
	         , Consumo
	         , DivisoreConsumo
	         , Cd_ARMisura
	         , FattoreToUM1
	         --, ConsumoUM1
	         --, Sfrido
	         --, Opzionale
	         , InizioValidita
	         , FineValidita
	         --, NoteDBMateriale
	         , Sequenza
	         --, UserIns
	         --, UserUpd
	         --, TimeIns
	         --, TimeUpd
	         --, Ts
	        )
	        VALUES
	        (
		     --Id_DBMateriale
	         @IdDb --, Id_DB
	         , @DedBavBaTubSave --, Cd_AR
	         , @Q
	         , 1.0
	         , @UMMateriale --, Cd_ARMisura
	         , 1.0 --, FattoreToUM1
	         --, @Q --ConsumoUM1
	         --, Sfrido
	         --, Opzionale
	         , '01/01/2001' --, InizioValidita
	         , NULL --FineValidita  
	         --, NoteDBMateriale
	         , @Sequenza
	         --, UserIns
	         --, UserUpd
	         --, TimeIns
	         --, TimeUpd
	         --, Ts		  
		    )

			SET @Severity = @@ERROR
		    IF @Severity <> 0
			BEGIN

	          IF @Transaction = 1
	            GOTO labelExit
	          ELSE
	            GOTO labelExit2

		    END

		  END
	    END

      END

    END

    CLOSE DedArticoliCrs
	DEALLOCATE DedArticoliCrs

	labelExit:
    IF @Transaction = 1 
	BEGIN
	  IF @Severity = 0
	    COMMIT TRANSACTION
	  ELSE	
	  BEGIN
	    print 'Rollback'
	    ROLLBACK TRANSACTION
	  END

	  --IF OBJECT_ID(N'tempdb..##TTArticoli', N'U') IS NOT NULL 
      --  DROP TABLE ##TTArticoli


	  SET @Ciclo = 0

	  -- Scrive Log su File

	  --EXEC master.dbo.sp_configure 'show advanced options', 1
      --RECONFIGURE
      --EXEC master.dbo.sp_configure 'xp_cmdshell', 1
      --RECONFIGURE

	  
	  /***** 09/10/2015 by guic: INIZIO tolto log */
	  
	  /*DECLARE LogCrs CURSOR LOCAL STATIC FOR
	  SELECT lMessage
	  FROM #TTLog

	  OPEN LogCrs

	  WHILE (@Ciclo = 0)
	  BEGIN

	    FETCH LogCrs INTO @LogMessage

	    IF @@FETCH_STATUS <> 0
	      BREAK

	    EXEC dbo.xWriteLog @Message = @LogMessage, @NomeFile = @NomeFileLog

	  END

	  CLOSE LogCrs
	  DEALLOCATE LogCrs*/

	  /***** 09/10/2015 by guic: FINE tolto log */

	  --EXEC master.dbo.sp_configure 'xp_cmdshell', 0
      --RECONFIGURE
      --EXEC master.dbo.sp_configure 'show advanced options', 0
      --RECONFIGURE

	  IF OBJECT_ID(N'tempdb..#TTLog', N'U') IS NOT NULL 
        DROP TABLE #TTLog


	  RETURN @Severity
    END
	

	labelExit2:
	RETURN @Severity

	--IF @Transaction = 1 
	--BEGIN

	  --EXEC master.dbo.sp_configure 'xp_cmdshell', 0
      --RECONFIGURE
      --EXEC master.dbo.sp_configure 'show advanced options', 0
      --RECONFIGURE

	--END
	

	

END