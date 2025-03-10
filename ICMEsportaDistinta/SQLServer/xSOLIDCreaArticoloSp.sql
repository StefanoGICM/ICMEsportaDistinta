USE [ADB_ICM]
GO
/****** Object:  StoredProcedure [dbo].[xSOLIDCreaArticoloSp]    Script Date: 1/21/2025 5:01:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[xSOLIDCreaArticoloSp]
( @DedId varchar(50),
  @DedRev varchar(50),
  @Transaction smallint,
  @Azione char(1),
  @CodPadre varchar(30),
  @XErrore varchar(1000) OUTPUT,
  @XWarning varchar(max) OUTPUT,
  @DistDate smalldatetime,
  @UltRev smallint,
  @DedIdPadre varchar(50) = NULL,
  @Livello int = 0,
  @First int = 0

)     -- 'A' Add, 'U' Update, 'D' Delete
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @First = 1
	BEGIN

      IF OBJECT_ID('tempdb..#ICM_Cache_SOLID') IS NOT NULL
        DROP TABLE #ICM_Cache_SOLID

	  CREATE TABLE #ICM_Cache_SOLID
	  (
		  DedId varchar(50),
		  DedRev varchar(50),
		  PRIMARY KEY (DedId, DedRev)
	  )

      IF OBJECT_ID('tempdb..#ICM_Data_Art') IS NOT NULL
        DROP TABLE #ICM_Data_Art

	  CREATE TABLE #ICM_Data_Art
	  (
		  Cd_AR varchar(20) PRIMARY KEY,
		  Lunghezza numeric(18,4),
		  PesoNetto numeric(18,4),
		  SupGommata numeric(18,4)
		  
	  )


	  if OBJECT_ID('tempdb..#UMLinear') IS NOT NULL
	    DROP TABLE #UMLinear

	  CREATE TABLE #UMLinear
	  (id INT,
	   um varchar(50),
	   PRIMARY KEY (id)
	  )


      if OBJECT_ID('tempdb..#UMMass') IS NOT NULL
	    DROP TABLE #UMMass

	  CREATE TABLE #UMMass
	  (id INT,
	   um varchar(50),
	   PRIMARY KEY (id)
	  )


	  if OBJECT_ID('tempdb..#UMConv') IS NOT NULL
	    DROP TABLE #UMConv

	  --Conversione UM per Linear
	  CREATE TABLE #UMConv
	  (id INT, 
	   um1 varchar(50),
	   um2 varchar(50),
	   conv decimal(23,11),
	   PRIMARY KEY (id),
	   UNIQUE NONCLUSTERED (um1, um2),
	   UNIQUE NONCLUSTERED (um2, um1)
	  )


	  if OBJECT_ID('tempdb..#FamMerc') IS NOT NULL
        DROP TABLE #FamMerc


	  -- Assegnazione unità di misura di acquisto per famiglie merceologiche
	  CREATE TABLE #FamMerc (id INT, name varchar(50), PRIMARY KEY (id), UNIQUE NONCLUSTERED (name) )


	  if OBJECT_ID('tempdb..#UMMaga') IS NOT NULL
        DROP TABLE #UMMaga
	
	  CREATE TABLE #UMMaga (id INT, name varchar(50), entity varchar(100), PRIMARY KEY (id))

	
	  if OBJECT_ID('tempdb..#UMAcq') IS NOT NULL
       DROP TABLE #UMAcq
	
	  CREATE TABLE #UMAcq (id INT, name varchar(50), entity varchar(100), PRIMARY KEY (id))

	  INSERT INTO #UMLinear
	  (  id
	   , um 
	  )
	  SELECT 
	    id
	  , um
	  FROM [PDMDATABASE].[ICM_Custom].[dbo].[ICM_UMLinear]	  


	  INSERT INTO #UMMass
	  (  id
	   , um
	  )
	  SELECT
	    id
	  , um
	  FROM [PDMDATABASE].[ICM_Custom].[dbo].[ICM_UMMass]	  

	  INSERT INTO #UMConv
	  (  id
	   , um1
	   , um2
	   , conv 
	  )
	  SELECT
	    id
	  , um1
	  , um2
	  , conv 
	  FROM [PDMDATABASE].[ICM_Custom].[dbo].[ICM_UMConv]

	  INSERT INTO #FamMerc 
	  (  id
	   , name
	  )
	  SELECT
	    id
	  , name
	  FROM [PDMDATABASE].[ICM_Custom].[dbo].[ICM_FamMerc]

	  INSERT INTO #UMMaga 
	  (  id
	   , name
	   , entity
	  )
	  SELECT
	    id
	  , name
	  , entity
	  FROM [PDMDATABASE].[ICM_Custom].[dbo].[ICM_UMMaga]


	  INSERT INTO #UMAcq 
	  (  id
	   , name
	   , entity
	  )
	  SELECT
	    id
	  , name
	  , entity
	  FROM [PDMDATABASE].[ICM_Custom].[dbo].[ICM_UMAcq]


	END

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
	, @NOTA_DI_TAGLIO varchar(200)
	, @DedCodFiglioCatMerc varchar(20)
	, @DedCodInputLike nvarchar(50)
	, @DedCodInputLikeFound nvarchar(50)
	, @DedCodFount int
	, @XWarningTemp varchar(max)
	, @RowCount int
	, @PreDescr varchar(40)	
    , @PreCodificaCodice varchar(30)
	, @PreCodificaCodifica varchar(20)
	, @IWhilePreCodifica int
	, @PreCodifica int
	, @DESCRIZION varchar(200)
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
	, @UMDist varchar(2)
	, @xItem varchar(20)
	, @xStatoDED varchar(50)
	, @DedCodFiglioDescrizione varchar(200)
	, @DedCodFiglioNotadiTaglio varchar(200)
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
	, @CATEGORIA1 varchar(200)
	, @CATEGORIA2 varchar(200)
	, @CATEGORIA3 varchar(200)
	, @CATEGORIA1_PREFIX varchar(200)
	, @CATEGORIA2_PREFIX varchar(200)
	, @CATEGORIA3_PREFIX varchar(200) 
	, @FAMIGLIA1 varchar(200)
	, @FAMIGLIA2 varchar(200)
	, @FAMIGLIA3 varchar(200)
	, @TRAS_FOUND smallint
	, @FAMIGLIA1_PREFIX varchar(200)
	, @FAMIGLIA2_PREFIX varchar(200)
	, @FAMIGLIA3_PREFIX varchar(200)
	, @FIGLIOFAMIGLIA1_PREFIX varchar(200)
	, @FIGLIOFAMIGLIA2_PREFIX varchar(200)
	, @FIGLIOFAMIGLIA3_PREFIX varchar(200)
	, @Cd_xStatoDED varchar(3)
	, @FaiAcquista varchar(10)
	, @DescTecnicaITA varchar(200)
    , @DescTecnicaENG varchar(200)
    , @DescCommITA varchar(200)
    , @DescCommENG varchar(200)
    , @AContLamM2 varchar(200)
    , @TrattFinitura varchar(200)
    , @TrattGalvanico varchar(200)
    , @TrattProtez varchar(200)
    , @TrattSuperf varchar(200)
    , @Item varchar(200)
    , @Sotttocommessa varchar(200)
    , @Produttore varchar(200)
    , @AContLamMm2 varchar(200)
    , @L1ContLam varchar(200)
    , @L2ContLam varchar(200)
    , @PiegaturaLam varchar(200)
    , @RaggioPiegLam varchar(200)
    , @Sp_Lamiera varchar(200)
    , @Designazione varchar(200)
    , @DesigGeo varchar(200)
    , @DesigGeoEN varchar(200)
    , @DesigGeENG varchar(200)
    , @DesigGeoITA varchar(200)
    , @IngombroX varchar(200)
    , @IngombroY varchar(200)
    , @IngombroZ varchar(200)
    , @CodProduttore varchar(200)
	, @NEWIngombroX varchar(200)
    , @NEWIngombroY varchar(200)
    , @NEWIngombroZ varchar(200)
	, @NotePreventivo varchar(200)
	, @NoteDescTecnicaITA varchar(200)
    , @NoteDescTecnicaENG varchar(200)
    , @NoteDescCommITA varchar(200)
    , @NoteDescCommENG varchar(200)
	, @NoteTrattFinitura varchar(200)
    , @NoteTrattGalvanico varchar(200)
    , @NoteTrattProtez varchar(200)
    , @NoteTrattSuperf varchar(200)
	, @NotexItem varchar(200)
	, @NoteSOTTOCOMMESSA varchar(200)
    , @NoteStandard_DIN varchar(200)
    , @NoteStandard_ISO varchar(200)
    , @NoteStandard_UNI varchar(200)
    , @NoteProduttore varchar(200)
    , @Noteshmetal_AreaContorno_mm2 varchar(200)
    , @Noteshmetal_L1_Contorno varchar(200)
    , @Noteshmetal_L2_Contorno varchar(200)
    , @Noteshmetal_Piegature varchar(200)
    , @Noteshmetal_RaggioDiPiegatura varchar(200)
    , @Noteshmetal_Sp_Lamiera varchar(200)
    , @NoteDesignazione varchar(200)
    , @NoteDesignazioneGeometrica varchar(200)
    , @NoteDesignazioneGeometricaEN varchar(200)
    , @NoteDesignazioneGeometricaENG varchar(200)
    , @NoteDesignazioneGeometricaITA varchar(200)
    , @NoteIngombroX varchar(200)
    , @NoteIngombroY varchar(200)
    , @NoteIngombroZ varchar(200)    
    , @NoteCATEGORIA4 varchar(200)
    , @NoteCATEGORIA4_PREFIX varchar(200)
    , @NoteCodiceProduttore varchar(200)
    , @NoteCATEGORIA0 varchar(200)
    , @NoteCATEGORIA0_PREFIX varchar(200)
	, @TypeSW char(1)
	, @iFamIndex int
	, @bFamFound smallint
	, @UMCod nvarchar(max)
	, @UMCodPrincipale nvarchar(200)
	, @UMMagazzinoFiglio nvarchar(200)
	, @EntityMagazzinoFiglio nvarchar(200)
	, @LunghezzaFiglio numeric(18,4)
	, @PesoNettoFiglio numeric(18,4)
	, @SupGommataFiglio numeric(18,4)
	, @UMEntity nvarchar(200)
	, @DEDLinear varchar(200)
	, @DEDMass varchar(200)
	, @DEDLinearInt int
	, @DEDMassInt int
	, @UMSolidWorksLinear varchar(50)
	, @UMSolidWorksMass varchar(50)
	, @UMArcaLinear varchar(50)
	, @UMArcaMass varchar(50)
    , @FattoreUMLinear numeric (18,4)
	, @Fattore#UMMass numeric (18,4)
	, @NotaSW varchar(1000)
	, @POTENZA nvarchar(4)
	, @NEWPOTENZA nvarchar(4)
	, @N_MOTORI nvarchar(20)
	, @NEWN_MOTORI nvarchar(20)
	, @NOME_COMM nvarchar(150)
	, @LARG_MACC nvarchar(10)
	, @NEWLARG_MACC nvarchar(10)
	, @LUNG_MACC nvarchar(10)
	, @NEWLUNG_MACC nvarchar(10)
	, @MTPH nvarchar(10)
	, @NEWMTPH nvarchar(10)

	SET @Severity = 0

	/* Assumo come unità di misura di riferimento ARCA 
	           Linear = 'MT'
			   Peso = 'KG'
	   Dimensioni e pesi vengono dapprima converiti in queste unità di misura
	   Poi vengono convertiti nell'unità di misura usata in anagrafica articolo 
	   per dati sull'anagrafica articolo (solo in UPDATE)  e nell'unità di misura espresssa in categoria merceologica per 
	   le unità di misura alternative (ad esempio unità di misura di acquisto)
	*/

	SET @UMArcaLinear = 'MT'
	SET @UMArcaMass = 'KG'

	SET @FattoreUMLinear = 1
	SET @Fattore#UMMass = 1


	SET @Codifica = 0
	SET @iLBavetta = 0
	SET @iLTubo = 0
	SET @iLBarraFilettata = 0

	SET @iLBavetta2 = 0
	SET @iLTubo2 = 0
	SET @iLBarraFilettata2 = 0


	IF @Transaction = 1
	  BEGIN TRANSACTION

	IF EXISTS (SELECT 1 FROM #ICM_Cache_SOLID WHERE DedId = @DedId
	                                            AND DedRev = @DedRev)
    BEGIN

	  --print 'CACHED ' + @DedId + ' ' + @DedRev

	  IF @Transaction = 1
	    GOTO labelExit
	  ELSE
	    GOTO labelExit2

	END
	ELSE
	BEGIN

	  INSERT INTO #ICM_Cache_SOLID (DedId, DedRev) VALUES (@DedId, @DedRev)


	END


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

	
	-- print 'Ingresso'
	-- print @DedId
	-- print @DedRev

	-- prende l'ultima revisione

	IF @UltRev = 1
	BEGIN

	  SET @DedNewRev = NULL

	  SELECT TOP 1 @DedNewRev = DEDREV 
	  FROM [PDMDATABASE].[ICM_Custom].[dbo].[XPORT_ANAG]
	  WHERE 
	  (DEDID = @DedId) --AND (DED_DIS NOT LIKE 'ZZ%')	
	  AND ISNULL(DEDREVDATE, @DistDate - 1) < @DistDate
	  ORDER BY CAST(DEDREV AS Int) DESC

	  IF @DedNewRev IS NOT NULL
	    SET @DedRev = @DedNewRev

     
	END

	--print 'inizio ' + @DedId + ' --- ' + @DedRev


	SELECT 
	  -- @DedCodInputAll = DED_DIS
	  @DedCodInputAll = DED_COD
	, @xRevisione = @DedRev --CASE WHEN LEFT(RIGHT(DED_DIS, 2), 1) = '_' THEN RIGHT(DED_DIS, 1) ELSE NULL END
	, @FAMIGLIA1_PREFIX = FAMIGLIA1_PREFIX  
	, @FAMIGLIA2_PREFIX = FAMIGLIA2_PREFIX
	, @NOTA_DI_TAGLIO = NOTA_DI_TAGLIO
	, @DESCRIZION  = DescTecnicaITA --DEDDESC
	FROM [PDMDATABASE].[ICM_Custom].[dbo].[XPORT_ANAG] WHERE DEDID = @DedId     
     AND DEDREV = @DedRev

	 IF @@ROWCOUNT <> 1
	 BEGIN

	   SET @Severity = 16
	   SET @XErrore = 'Codice Articolo/Revisione non trovato: ' + @DedCodInputAll

	   IF @Transaction = 1
	     GOTO labelExit
	   ELSE
	     GOTO labelExit2

	 END

     SET @DedCodInputAll = UPPER(@DedCodInputAll)    

     IF ISNULL(@DESCRIZION, '') = ''
	  SET @DESCRIZION = 'Senza Descrizione'


	 SET @PreDescr = ''

	 /* guic: togliere ?*/
	 /*IF LEN(@DedCodInputAll) = 21
	 BEGIN
	   SET @DedCodInputAll = SUBSTRING(@DedCodInputAll, 1, LEN(@DedCodInputAll) - 3) + SUBSTRING(@DedCodInputAll, LEN(@DedCodInputAll) - 1, 2)
	 END*/
	 /* guic: togliere ?*/

	 IF LEN(@DedCodInputAll) > 20
	 BEGIN

		-- errore

		--print 'Errore'			

        SET @Severity = 16
		SET @XErrore = 'Codice articolo più lungo di 20 caratteri: ' + @DedCodInputAll

	    IF @Transaction = 1
	      GOTO labelExit
	    ELSE
	      GOTO labelExit2

	      

	 END
	

	 SET @DedCodInput = @DedCodInputAll

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
    , @DEDSTATEID nvarchar(50)
    , @DEDSTATEPATH varchar(255)
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
	, @FattoreConversione numeric (18,4)
	, @FattoreUMLinearUmAcq numeric(18,4)
	, @FattoreUMMassUmAcq numeric (18,4)
	, @LgNumero numeric (18,4)
	, @LgNumeroFiglio numeric (18,4)
	, @DBKit bit
	, @DBFaiAcquista bit
	, @DBKitCheck bit
	, @DBFaiAcquistaCheck bit
	, @UMAcquisto bit
	, @iCount int
	, @DEDIDP varchar(50)
	, @DEDREVP varchar(50)
	, @DEDIDC varchar(50)
	, @DEDREVC varchar(50)
	, @DedDis nvarchar(30)	
	, @DED_xRevisione Char(2)
	, @SOTTOCOMMESSA nvarchar(200)
    , @Standard_DIN nvarchar(200)
    , @Standard_ISO nvarchar(200)
    , @Standard_UNI nvarchar(200)
    , @MPTH nvarchar(200)    
    , @shmetal_AreaContorno_mm2 nvarchar(200)
	, @NEWshmetal_AreaContorno_mm2 nvarchar(200)
    , @shmetal_L1_Contorno nvarchar(200)
	, @NEWshmetal_L1_Contorno nvarchar(200)
    , @shmetal_L2_Contorno nvarchar(200)
	, @NEWshmetal_L2_Contorno nvarchar(200)
    , @shmetal_Piegature nvarchar(200)
	, @NEWshmetal_Piegature nvarchar(200)
    , @shmetal_RaggioDiPiegatura nvarchar(200)
	, @NEWshmetal_RaggioDiPiegatura nvarchar(200)
    , @shmetal_Sp_Lamiera nvarchar(200)    
	, @NEWshmetal_Sp_Lamiera nvarchar(200)    
    , @DesignazioneGeometrica nvarchar(200)
    , @DesignazioneGeometricaEN nvarchar(200)
    , @DesignazioneGeometricaENG nvarchar(200)
    , @DesignazioneGeometricaITA nvarchar(200)
    , @LargMacchina nvarchar(200)
    , @LungMacchina nvarchar(200)
    , @CATEGORIA4 nvarchar(200)
    , @CATEGORIA4_PREFIX nvarchar(200)
    , @CodiceProduttore nvarchar(200)
    , @CATEGORIA0 nvarchar(200)
    , @CATEGORIA0_PREFIX nvarchar(200)
	, @NoteDATA varchar(10) 
	, @NoteDISEGNATOR varchar(20)
	, @NoteLG varchar(15)
	, @NoteMATERIALE varchar(30)
	, @NoteNOTA_DI_TAGLIO varchar(200)
	, @NoteTRATT_TERM varchar(30)
	, @NoteCOMMESSA varchar(10)
	, @NoteATTR1 varchar(20)
	, @NotePOTENZA nvarchar(4)
	, @NoteN_MOTORI nvarchar(20)
	, @NoteNOME_COMM nvarchar(200)
	, @NoteLargMacchina nvarchar(10)
	, @NoteLungMacchina nvarchar(10)
	, @NoteMTPH nvarchar(10)
	, @NoteSUP_GOMMATA varchar(20)
	, @NoteEX_CODICE varchar(40)
	, @PesoNettoinArticolo numeric (18,4)
	

	IF @Transaction = 1
	BEGIN


	  --IF @Azione = 'U' OR @Azione = 'D'
	  IF @Azione = 'D'
	  BEGIN

	    /* Cancellazione vecchia distinta */		

	    EXEC @Severity = xSOLIDCancellaDistintaSp 
		                 @DedCodInput = @DedCodInput

	  END


	END 


	-- guic: impostati a blank perchè nella tabella di confine di SolidWorks non ci sono
	SET @EX_CODICE = ''
	SET @ATTR1 = ''
	SET @NOME_COMM = ''
	SET @LARG_MACC = ''
	SET @LUNG_MACC = ''
	SET @MTPH = ''



    DECLARE DedArticoliCrs CURSOR LOCAL STATIC FOR
	SELECT 
--	  DEDID
--	, DEDREV
      CATEGORIA1
	, CATEGORIA2
	, CATEGORIA3
    , CATEGORIA1_PREFIX
	, CATEGORIA2_PREFIX
	, CATEGORIA3_PREFIX
    , FAMIGLIA1
	, FAMIGLIA2
	, FAMIGLIA3
    , FAMIGLIA1_PREFIX
	, FAMIGLIA2_PREFIX
	, FAMIGLIA3_PREFIX    
    , COMMESSA
    , DEDDATE
    , DBPATH
    , DED_COD
    , DED_DIS
    , DED_FILE
    , DEDREVDATE
    , DEDREVDESC
    , DEDREVUSER
    , DEDSTATEID
	, DescTecnicaITA
    , DescTecnicaENG
    , DescCommercialeITA
    , DescCommercialeENG
    , LG
    , MATERIALE
    , NOTA_DI_TAGLIO
    , PESO
    , SUP_GOMMATA
    , TRATT_TERMICO
	, TrattFinitura
    , TrattGalvanico
    , TrattProtezione
    , TrattSuperficiale
	, ITEM
	, POTENZA
	, N_MOTORI
	, SOTTOCOMMESSA
    , Standard_DIN
    , Standard_ISO
    , Standard_UNI
    , MPTH
    , Produttore
    , shmetal_AreaContorno_mm2
    , shmetal_L1_Contorno
    , shmetal_L2_Contorno
    , shmetal_Piegature
    , shmetal_RaggioDiPiegatura
    , shmetal_Sp_Lamiera
    , Designazione
    , DesignazioneGeometrica
    , DesignazioneGeometricaEN
    , DesignazioneGeometricaENG
    , DesignazioneGeometricaITA
    , IngombroX
    , IngombroY
    , IngombroZ
    , LargMacchina
    , LungMacchina
    , CATEGORIA4
    , CATEGORIA4_PREFIX
    , CodiceProduttore
    , CATEGORIA0
    , CATEGORIA0_PREFIX	
	, @DedRev --CASE WHEN LEFT(RIGHT(DED_DIS, 2), 1) = '_' THEN RIGHT(DED_DIS, 1) ELSE NULL END
	, FaiAcquista
	, TipoSW
	, DEDLinear
	, DEDMass

    FROM [PDMDATABASE].[ICM_Custom].[dbo].[XPORT_ANAG] AS A
	WHERE A.DEDID = @DEDID
	  AND A.DEDREV = @DEDREV

    OPEN DedArticoliCrs

    WHILE (@Severity = 0)
    BEGIN

      FETCH DedArticoliCrs INTO
--	    @DEDID
--	  , @DEDREV
        @CATEGORIA1
	  , @CATEGORIA2
	  , @CATEGORIA3
      , @CATEGORIA1_PREFIX
	  , @CATEGORIA2_PREFIX
	  , @CATEGORIA3_PREFIX
      , @FAMIGLIA1
	  , @FAMIGLIA2
	  , @FAMIGLIA3
      , @FAMIGLIA1_PREFIX
	  , @FAMIGLIA2_PREFIX
	  , @FAMIGLIA3_PREFIX
      , @COMMESSA
      , @DATA
      , @DBPATH
      , @DED_COD
      , @DedDis
      , @DED_FILE
      , @DED_REV_DATA
      , @DED_REV_DESC
      , @DED_REV_USER
      , @DEDSTATEID
	  , @DescTecnicaITA
      , @DescTecnicaENG
      , @DescCommITA
      , @DescCommENG
      , @LG
      , @MATERIALE
      , @NOTA_DI_TAGLIO
      , @PESO
      , @SUP_GOMMATA      
      , @TRATT_TERM
	  , @TrattFinitura
      , @TrattGalvanico
      , @TrattProtez
      , @TrattSuperf	  
	  , @xItem
	  , @POTENZA
	  , @N_MOTORI
	  , @SOTTOCOMMESSA
      , @Standard_DIN
      , @Standard_ISO
      , @Standard_UNI
      , @MPTH
      , @Produttore
      , @shmetal_AreaContorno_mm2
      , @shmetal_L1_Contorno
      , @shmetal_L2_Contorno
      , @shmetal_Piegature
      , @shmetal_RaggioDiPiegatura
      , @shmetal_Sp_Lamiera
      , @Designazione
      , @DesignazioneGeometrica
      , @DesignazioneGeometricaEN
      , @DesignazioneGeometricaENG
      , @DesignazioneGeometricaITA
      , @IngombroX
      , @IngombroY
      , @IngombroZ
      , @LargMacchina
      , @LungMacchina
      , @CATEGORIA4
      , @CATEGORIA4_PREFIX
      , @CodiceProduttore
      , @CATEGORIA0
      , @CATEGORIA0_PREFIX
	  , @DED_xRevisione
	  , @FaiAcquista
	  , @TypeSW
	  , @DEDLinear
	  , @DEDMass

	  IF @@FETCH_STATUS <> 0
	    BREAK
	 
	  -- 21/02/2024 by guic
	  IF @FAMIGLIA1_PREFIX = '-'
	    SET @FAMIGLIA1 = '-'

	  IF @FAMIGLIA1 = '-'
	    SET @FAMIGLIA1_PREFIX = '-'

	  IF @PESO IS NULL OR LTRIM(RTRIM(@PESO)) = '' SET @PESO = '0'
	  IF @SUP_GOMMATA IS NULL OR LTRIM(RTRIM(@SUP_GOMMATA)) = '' SET @SUP_GOMMATA = '0'
	  IF @LG IS NULL OR LTRIM(RTRIM(@LG)) = '' SET @LG = '0'
	  IF @N_MOTORI IS NULL OR LTRIM(RTRIM(@N_MOTORI)) = '' SET @N_MOTORI = '0'
      IF @POTENZA IS NULL OR LTRIM(RTRIM(@POTENZA)) = '' SET @POTENZA = '0'
	  IF @MTPH IS NULL OR LTRIM(RTRIM(@MTPH)) = '' SET @MTPH = '0'
      IF @LUNG_MACC IS NULL OR LTRIM(RTRIM(@LUNG_MACC)) = '' SET @LUNG_MACC = '0'
	  IF @LARG_MACC IS NULL OR LTRIM(RTRIM(@LARG_MACC)) = '' SET @LARG_MACC = '0'
	  IF @shmetal_AreaContorno_mm2 IS NULL OR LTRIM(RTRIM(@shmetal_AreaContorno_mm2)) = '' SET @shmetal_AreaContorno_mm2 = '0'
	  IF @shmetal_L1_Contorno IS NULL OR LTRIM(RTRIM(@shmetal_L1_Contorno)) = '' SET @shmetal_L1_Contorno = '0'
	  IF @shmetal_L2_Contorno IS NULL OR LTRIM(RTRIM(@shmetal_L2_Contorno)) = '' SET @shmetal_L2_Contorno = '0'
	  IF @shmetal_Piegature IS NULL OR LTRIM(RTRIM(@shmetal_Piegature)) = '' SET @shmetal_Piegature = '0'
	  IF @shmetal_RaggioDiPiegatura IS NULL OR LTRIM(RTRIM(@shmetal_RaggioDiPiegatura)) = '' SET @shmetal_RaggioDiPiegatura = '0'
	  IF @shmetal_Sp_Lamiera IS NULL OR LTRIM(RTRIM(@shmetal_Sp_Lamiera)) = '' SET @shmetal_Sp_Lamiera = '0'
	  IF @IngombroX IS NULL OR LTRIM(RTRIM(@IngombroX)) = '' SET @IngombroX = '0'
	  IF @IngombroY IS NULL OR LTRIM(RTRIM(@IngombroY)) = '' SET @IngombroY = '0'
      IF @IngombroZ IS NULL OR LTRIM(RTRIM(@IngombroZ)) = '' SET @IngombroZ = '0'
	       

	  SET @PESO = REPLACE(@PESO, ',', '.')
	  SET @SUP_GOMMATA = REPLACE(@SUP_GOMMATA, ',', '.')
	  SET @LG = REPLACE(@LG, ',', '.')
	  SET @N_MOTORI = REPLACE(@N_MOTORI, ',', '.')
	  SET @POTENZA = REPLACE(@POTENZA, ',', '.')
	  SET @MTPH = REPLACE(@MTPH, ',', '.')
	  SET @LUNG_MACC = REPLACE(@LUNG_MACC, ',', '.')
	  SET @LARG_MACC = REPLACE(@LARG_MACC, ',', '.')
	  SET @shmetal_AreaContorno_mm2 = REPLACE(@shmetal_AreaContorno_mm2, ',', '.')
	  SET @shmetal_L1_Contorno = REPLACE(@shmetal_L1_Contorno, ',', '.')
	  SET @shmetal_L2_Contorno = REPLACE(@shmetal_L2_Contorno, ',', '.')
	  SET @shmetal_Piegature = REPLACE(@shmetal_Piegature, ',', '.')
	  SET @shmetal_RaggioDiPiegatura = REPLACE(@shmetal_RaggioDiPiegatura, ',', '.')
	  SET @shmetal_Sp_Lamiera = REPLACE(@shmetal_Sp_Lamiera, ',', '.')
	  SET @IngombroX = REPLACE(@IngombroX, ',', '.')
	  SET @IngombroY = REPLACE(@IngombroY, ',', '.')
	  SET @IngombroZ = REPLACE(@IngombroZ, ',', '.')
	  

	  --print 'dopo fetch'

      /* ricavo unità di misura di Solidworks */
	  
	  IF @DEDLinear IS NOT NULL AND ISNUMERIC(@DEDLinear) = 1 AND ROUND(@DEDLinear,0,1) = @DEDLinear
	  BEGIN

	    SET @DEDLinearInt = CAST(@DEDLinear AS INT)

	  END
	  ELSE
	  BEGIN


	    SET @Severity = 16
	    SET @XErrore = 'Unità di misura per lunghezza espressa in SolidWorks non riconosciuta'

	    IF @Transaction = 1
	      GOTO labelExit
	    ELSE
	      GOTO labelExit2


	  END

	  SELECT TOP 1 
	    @UMSolidWorksLinear = um
	  FROM #UMLinear
	  WHERE id = @DEDLinearInt

	  IF @@ROWCOUNT = 0 OR ISNULL(@UMSolidWorksLinear, '') = ''
	  BEGIN

	    SET @Severity = 16

	    SET @XErrore = 'Unità di misura per lunghezza espressa in SolidWorks non riconosciuta'

	    IF @Transaction = 1
	      GOTO labelExit
	    ELSE
	      GOTO labelExit2


	  END


	  IF @DEDMass IS NOT NULL AND ISNUMERIC(@DEDMass) = 1 AND ROUND(@DEDMass,0,1) = @DEDMass
	  BEGIN

	    SET @DEDMassInt = CAST(@DEDMass AS INT)

	  END
	  ELSE
	  BEGIN

	   
	   SET @Severity = 16
	   SET @XErrore = 'Unità di misura per peso espressa in SolidWorks non riconosciuta'

	    IF @Transaction = 1
	      GOTO labelExit
	    ELSE
	      GOTO labelExit2


	  END

	  SELECT TOP 1 
	    @UMSolidWorksMass = um
	  FROM #UMMass
	  WHERE id = @DEDMassInt

	  IF @@ROWCOUNT = 0 OR ISNULL(@UMSolidWorksMass, '') = ''
	  BEGIN

	    SET @Severity = 16
	    SET @XErrore = 'Unità di misura per peso espressa in SolidWorks non riconosciuta'

	    IF @Transaction = 1
	      GOTO labelExit
	    ELSE
	      GOTO labelExit2


	  END

	  /* Calcolo fattore di conversione tra le unità di misura di SolidWorks e di Arca*/	

	  IF @UMArcaLinear <> @UMSolidWorksLinear
	  BEGIN

	    SELECT TOP 1 
	      @FattoreUMLinear = conv
	    FROM #UMConv
	    WHERE um1 = @UMSolidWorksLinear
	      AND um2 = @UMArcaLinear

	    IF @@ROWCOUNT = 0
	    BEGIN

	      SELECT TOP 1 
  	        @FattoreUMLinear = (1 / conv)
	      FROM #UMConv
	      WHERE um1 = @UMArcaLinear
	        AND um2 = @UMSolidWorksLinear

		  IF @@ROWCOUNT = 0
		  BEGIN


	        SET @Severity = 16
	        SET @XErrore = 'Fattore di conversione tra unità di misura metriche di SolidWorks e ARCA non trovato'

	       IF @Transaction = 1
	         GOTO labelExit
	       ELSE
	         GOTO labelExit2


		  END
	   
	    END

	  END

	  ELSE
	    SET @FattoreUMLinear = 1
	
	  IF @UMArcaMass <> @UMSolidWorksMass
	  BEGIN

	    SELECT TOP 1 
	      @Fattore#UMMass = conv
	    FROM #UMConv
	    WHERE um1 = @UMSolidWorksMass
  	      AND um2 = @UMArcaMass

	    IF @@ROWCOUNT = 0
	    BEGIN

	      SELECT TOP 1 
  	        @Fattore#UMMass = (1 / conv)
	      FROM #UMConv
	      WHERE um1 = @UMArcaMass
	        AND um2 = @UMSolidWorksMass

		  IF @@ROWCOUNT = 0
		  BEGIN


	        SET @Severity = 16
	        SET @XErrore = 'Fattore di conversione tra unità di misura di peso di SolidWorks e ARCA non trovato'

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2


		  END
	    

	    END

	  END

	  ELSE
	    SET @Fattore#UMMass = 1

     --print 'prima simone'
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

	  IF NOT (@Livello = 1 AND SUBSTRING(ISNULL(@xItem, ''), 1, 1) = 'C')
	  BEGIN
	    SET @LARG_MACC = '0'
		SET @LUNG_MACC = '0'
	  END

	  IF NOT (@Livello = 1)
	  BEGIN
	    SET @POTENZA = '0'
		SET @N_MOTORI = '0'
	  END

      IF ISNULL(@DESCRIZION, '') = ''
		SET @DESCRIZION = 'Senza Descrizione'

      
	  SELECT TOP 1 @Cd_xStatoDED = Cd_xStatoDED 
	  FROM xStatoDED
	  WHERE Descrizione = @DEDSTATEID

	  IF @@ROWCOUNT = 0
	  BEGIN

	    SET @Severity = 16
		SET @XErrore = 'Stato ' + @DEDSTATEID + ' non tabellato per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2


	  END

      --guic: controllo e creazione dati in tabelle Classi e Gruppi
	  

	  IF LTRIM(RTRIM(@FAMIGLIA1_PREFIX)) = ''
	    SET @FAMIGLIA1_PREFIX = NULL

	  IF LTRIM(RTRIM(@FAMIGLIA2_PREFIX)) = ''
	    SET @FAMIGLIA2_PREFIX = NULL

	  IF LTRIM(RTRIM(@FAMIGLIA3_PREFIX)) = ''
	    SET @FAMIGLIA3_PREFIX = NULL

      IF LTRIM(RTRIM(@CATEGORIA1_PREFIX)) = ''
	    SET @CATEGORIA1_PREFIX = NULL

	  IF LTRIM(RTRIM(@CATEGORIA2_PREFIX)) = ''
	    SET @CATEGORIA2_PREFIX = NULL

	  IF LTRIM(RTRIM(@CATEGORIA3_PREFIX)) = ''
	    SET @CATEGORIA3_PREFIX = NULL

	  
	  IF @FAMIGLIA2_PREFIX IS NULL
	  BEGIN

	    SET @FAMIGLIA2_PREFIX = '000'
		SET @FAMIGLIA2 = @FAMIGLIA1

	  END

	  IF @FAMIGLIA3_PREFIX IS NULL
	  BEGIN

	    SET @FAMIGLIA3_PREFIX = '000'
		SET @FAMIGLIA3 = @FAMIGLIA2

	  END

	  IF @CATEGORIA2_PREFIX IS NULL
	  BEGIN

	    SET @CATEGORIA2_PREFIX = '000'
		SET @CATEGORIA2 = @CATEGORIA1

	  END

	  IF @CATEGORIA3_PREFIX IS NULL
	  BEGIN

	    SET @CATEGORIA3_PREFIX = '000'
		SET @CATEGORIA3 = @CATEGORIA2

	  END

	  --print 'dopo famiglia'
	  
	  /*
	  IF LTRIM(RTRIM(@FAMIGLIA1_PREFIX)) = '' 
	  BEGIN
	    SET @FAMIGLIA1_PREFIX = NULL
		SET @FAMIGLIA1 = NULL
	  END

      IF LTRIM(RTRIM(@FAMIGLIA2_PREFIX)) = '' 
	  BEGIN
	    SET @FAMIGLIA2_PREFIX = NULL
		SET @FAMIGLIA2 = NULL
	  END

      IF LTRIM(RTRIM(@FAMIGLIA3_PREFIX)) = '' 
	  BEGIN
	    SET @FAMIGLIA3_PREFIX = NULL
		SET @FAMIGLIA3 = NULL
	  END

	  IF LTRIM(RTRIM(@CATEGORIA1_PREFIX)) = '' 
	  BEGIN
	    SET @CATEGORIA1_PREFIX = NULL
		SET @CATEGORIA1 = NULL
	  END

      IF LTRIM(RTRIM(@CATEGORIA2_PREFIX)) = '' 
	  BEGIN
	    SET @CATEGORIA2_PREFIX = NULL
		SET @CATEGORIA2 = NULL
	  END

      IF LTRIM(RTRIM(@CATEGORIA3_PREFIX)) = '' 
	  BEGIN
	    SET @CATEGORIA3_PREFIX = NULL
		SET @CATEGORIA3 = NULL
	  END
	  */

	  
	 	 			 
	  IF @FAMIGLIA1_PREFIX IS NOT NULL AND LEN(@FAMIGLIA1_PREFIX) > 3
	  BEGIN
	        SET @Severity = 16

		    SET @XErrore = 'Lunghezza Prefisso FAMIGLIA1 maggiore di 3 per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2

		  
	  END

	  IF @FAMIGLIA2_PREFIX IS NOT NULL AND LEN(@FAMIGLIA2_PREFIX) > 3
	  BEGIN

	        SET @Severity = 16
		    SET @XErrore = 'Lunghezza Prefisso FAMIGLIA2 maggiore di 3 per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2

		  
	  END

	  IF @FAMIGLIA3_PREFIX IS NOT NULL AND LEN(@FAMIGLIA3_PREFIX) > 3
	  BEGIN
	        SET @Severity = 16
		    SET @XErrore = 'Lunghezza Prefisso FAMIGLIA3 maggiore di 3 per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2

		  
	  END


	  IF @CATEGORIA1_PREFIX IS NOT NULL AND LEN(@CATEGORIA1_PREFIX) > 3
	  BEGIN
	        SET @Severity = 16
		    SET @XErrore = 'Lunghezza Prefisso CATEGORIA1 maggiore di 3 per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2

		  
	  END

	  IF @CATEGORIA2_PREFIX IS NOT NULL AND LEN(@CATEGORIA2_PREFIX) > 3
	  BEGIN
	        SET @Severity = 16
		    SET @XErrore = 'Lunghezza Prefisso CATEGORIA2 maggiore di 3 per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2

		  
	  END

	  IF @CATEGORIA3_PREFIX IS NOT NULL AND LEN(@CATEGORIA3_PREFIX) > 3
	  BEGIN
	        SET @Severity = 16
		    SET @XErrore = 'Lunghezza Prefisso CATEGORIA3 maggiore di 3 per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2
		  
	  END


	  IF @FAMIGLIA1 IS NOT NULL AND LEN(@FAMIGLIA1) > 50
	  BEGIN

		    /*
			SET @XErrore = 'Lunghezza  FAMIGLIA1 maggiore di 50 per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2

			*/ 
			SET @FAMIGLIA1 = SUBSTRING(@FAMIGLIA1, 1, 50)
		  
	  END

	  
	  IF @FAMIGLIA2 IS NOT NULL AND LEN(@FAMIGLIA2) > 50
	  BEGIN

		    /*
			SET @XErrore = 'Lunghezza  FAMIGLIA2 maggiore di 50 per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2
			*/

			SET @FAMIGLIA2 = SUBSTRING(@FAMIGLIA2, 1, 50)
		  
	  END

	  IF @FAMIGLIA3 IS NOT NULL AND LEN(@FAMIGLIA3) > 50
	  BEGIN

		    
			/*
			SET @XErrore = 'Lunghezza  FAMIGLIA3 maggiore di 50 per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2
			*/

			SET @FAMIGLIA3 = SUBSTRING(@FAMIGLIA3, 1, 50)

		  
	  END
	  

	  IF @CATEGORIA1 IS NOT NULL AND LEN(@CATEGORIA1) > 50
	  BEGIN

	        /*

		    SET @XErrore = 'Lunghezza  CATEGORIA1 maggiore di 50 per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2

			*/

			SET @CATEGORIA1 = SUBSTRING(@CATEGORIA1, 1, 50)
		  
	  END

	  IF @CATEGORIA2 IS NOT NULL AND LEN(@CATEGORIA2) > 50
	  BEGIN


	        /*
		    SET @XErrore = 'Lunghezza  CATEGORIA2 maggiore di 50 per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2
			*/

			SET @CATEGORIA2 = SUBSTRING(@CATEGORIA2, 1, 50)

		  
	  END

	  IF @CATEGORIA3 IS NOT NULL AND LEN(@CATEGORIA3) > 50
	  BEGIN

	        /*

		    SET @XErrore = 'Lunghezza  CATEGORIA3 maggiore di 50 per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2

			*/

			SET @CATEGORIA3 = SUBSTRING(@CATEGORIA3, 1, 50)
		  
	  END

	  
	  IF (@FAMIGLIA1 IS NOT NULL AND @FAMIGLIA1_PREFIX IS NULL) OR
	     (@FAMIGLIA1 IS NULL AND @FAMIGLIA1_PREFIX IS NOT NULL)
      BEGIN
	        SET @Severity = 16
		    SET @XErrore = 'Compilare entrambe FAMIGLIA1 e FAMIGLIA1_PREFIX per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2


	  END

	  IF (@FAMIGLIA2 IS NOT NULL AND @FAMIGLIA2_PREFIX IS NULL) OR
	     (@FAMIGLIA2 IS NULL AND @FAMIGLIA2_PREFIX IS NOT NULL)
      BEGIN
	        SET @Severity = 16
		    SET @XErrore = 'Compilare entrambe FAMIGLIA2 e FAMIGLIA2_PREFIX per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2


	  END

	  IF (@FAMIGLIA3 IS NOT NULL AND @FAMIGLIA3_PREFIX IS NULL) OR
	     (@FAMIGLIA3 IS NULL AND @FAMIGLIA3_PREFIX IS NOT NULL)
      BEGIN
	        SET @Severity = 16
		    SET @XErrore = 'Compilare entrambe FAMIGLIA3 e FAMIGLIA3_PREFIX per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2


	  END
	  

	  IF (@CATEGORIA1 IS NOT NULL AND @CATEGORIA1_PREFIX IS NULL) OR
	     (@CATEGORIA1 IS NULL AND @CATEGORIA1_PREFIX IS NOT NULL)
      BEGIN
	        SET @Severity = 16
		    SET @XErrore = 'Compilare entrambi CATEGORIA1 e CATEGORIA1_PREFIX per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2


	  END

	  IF (@CATEGORIA2 IS NOT NULL AND @CATEGORIA2_PREFIX IS NULL) OR
	     (@CATEGORIA2 IS NULL AND @CATEGORIA2_PREFIX IS NOT NULL)
      BEGIN
	        SET @Severity = 16
		    SET @XErrore = 'Compilare entrambi CATEGORIA2 e CATEGORIA2_PREFIX per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2


	  END

	  IF (@CATEGORIA3 IS NOT NULL AND @CATEGORIA3_PREFIX IS NULL) OR
	     (@CATEGORIA3 IS NULL AND @CATEGORIA3_PREFIX IS NOT NULL)
      BEGIN
	        SET @Severity = 16
		    SET @XErrore = 'Compilare entrambi CATEGORIA3 e CATEGORIA3_PREFIX per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2


	  END

	  /* Verifica che i valori famiglia e categoria siano nella tabella, altrimenti li inserisce */

	  IF @CATEGORIA1_PREFIX IS NOT NULL
	  BEGIN

	    IF NOT EXISTS(SELECT 1 FROM ARClasse1 WHERE Cd_ARClasse1 = @CATEGORIA1_PREFIX)
	    BEGIN

	      INSERT INTO ARClasse1 (Cd_ARClasse1, Descrizione) VALUES (@CATEGORIA1_PREFIX, @CATEGORIA1)

		  SET @Severity = @@ERROR
		    IF @Severity <> 0
		    BEGIN		          	
			  
		      SET @XErrore = 'Errore inserimento CATEGORIA1 per Articolo: ' + @DED_COD

	          IF @Transaction = 1
	            GOTO labelExit
	          ELSE
	            GOTO labelExit2

		    END

	    END

      END

	  IF @CATEGORIA1_PREFIX IS NOT NULL AND @CATEGORIA2_PREFIX IS NOT NULL
	  BEGIN

	    IF NOT EXISTS(SELECT 1 FROM ARClasse2 WHERE Cd_ARClasse1 = @CATEGORIA1_PREFIX
	                                            AND Cd_ARClasse2 = @CATEGORIA2_PREFIX)
	    BEGIN

	      INSERT INTO ARClasse2 (Cd_ARClasse1, Cd_ArClasse2, Descrizione) VALUES (@CATEGORIA1_PREFIX, @CATEGORIA2_PREFIX, @CATEGORIA2)

		  SET @Severity = @@ERROR
		    IF @Severity <> 0
		    BEGIN		          	

		      SET @XErrore = 'Errore inserimento CATEGORIA2 per Articolo: ' + @DED_COD

	          IF @Transaction = 1
	            GOTO labelExit
	          ELSE
	            GOTO labelExit2

			END

		  END

	  END

	  IF @CATEGORIA1_PREFIX IS NOT NULL AND @CATEGORIA2_PREFIX IS NOT NULL AND @CATEGORIA3_PREFIX IS NOT NULL
	  BEGIN

	    IF NOT EXISTS(SELECT 1 FROM ARClasse3 WHERE Cd_ARClasse1 = @CATEGORIA1_PREFIX
	                                            AND Cd_ARClasse2 = @CATEGORIA2_PREFIX
			  		  						    AND Cd_ARClasse3 = @CATEGORIA3_PREFIX)
	    BEGIN

	      INSERT INTO ARClasse3 (Cd_ARClasse1, Cd_ARClasse2, Cd_ARClasse3, Descrizione) VALUES (@CATEGORIA1_PREFIX, @CATEGORIA2_PREFIX, @CATEGORIA3_PREFIX, @CATEGORIA3)

		  SET @Severity = @@ERROR
		    IF @Severity <> 0
		    BEGIN		          	

		      SET @XErrore = 'Errore inserimento CATEGORIA3 per Articolo: ' + @DED_COD

	          IF @Transaction = 1
	            GOTO labelExit
	          ELSE
	            GOTO labelExit2

		    END

	    END

	  END

	  IF @FAMIGLIA1_PREFIX IS NOT NULL
	  BEGIN

	    IF NOT EXISTS(SELECT 1 FROM ARGruppo1 WHERE Cd_ARGruppo1 = @FAMIGLIA1_PREFIX)
	    BEGIN

	      INSERT INTO ARGruppo1 (Cd_ARGruppo1, Descrizione) VALUES (@FAMIGLIA1_PREFIX, @FAMIGLIA1)

		  SET @Severity = @@ERROR
		  IF @Severity <> 0
		  BEGIN		          	

		    SET @XErrore = 'Errore inserimento FAMIGLIA1 per Articolo: ' + @DED_COD

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2

		  END

	    END

	  END

	  IF @FAMIGLIA1_PREFIX IS NOT NULL AND @FAMIGLIA2_PREFIX IS NOT NULL
	  BEGIN

	    IF NOT EXISTS(SELECT 1 FROM ARGruppo2 WHERE Cd_ARGruppo1 = @FAMIGLIA1_PREFIX
	                                            AND Cd_ARGruppo2 = @FAMIGLIA2_PREFIX)
	    BEGIN

	      INSERT INTO ARGruppo2 (Cd_ARGruppo1, Cd_ArGruppo2, Descrizione) VALUES (@FAMIGLIA1_PREFIX, @FAMIGLIA2_PREFIX, @FAMIGLIA2)

		  SET @Severity = @@ERROR
		    IF @Severity <> 0
		    BEGIN		          	

		      SET @XErrore = 'Errore inserimento FAMIGLIA2 per Articolo: ' + @DED_COD

	          IF @Transaction = 1
	            GOTO labelExit
	          ELSE
	            GOTO labelExit2

		    END

	    END

	  END

	  IF @FAMIGLIA1_PREFIX IS NOT NULL AND @FAMIGLIA2_PREFIX IS NOT NULL AND @FAMIGLIA3_PREFIX IS NOT NULL
	  BEGIN


	    IF NOT EXISTS(SELECT 1 FROM ARGruppo3 WHERE Cd_ARGruppo1 = @FAMIGLIA1_PREFIX
	                                            AND Cd_ARGruppo2 = @FAMIGLIA2_PREFIX
			  			  					    AND Cd_ARGruppo3 = @FAMIGLIA3_PREFIX)
	    BEGIN

	      INSERT INTO ARGruppo3 (Cd_ARGruppo1, Cd_ARGruppo2, Cd_ARGruppo3, Descrizione) VALUES (@FAMIGLIA1_PREFIX, @FAMIGLIA2_PREFIX, @FAMIGLIA3_PREFIX, @FAMIGLIA3)

		  SET @Severity = @@ERROR
		    IF @Severity <> 0
		    BEGIN		          	

		      SET @XErrore = 'Errore inserimento FAMIGLIA3 per Articolo: ' + @DED_COD

	          IF @Transaction = 1
	            GOTO labelExit
	          ELSE
	            GOTO labelExit2

		    END

	    END

	  END

	  --print 'pippo1'

	  -- Conversione valori in formato numerico
	 
	  -- Peso
	  SET @NEWPESO = ''

	  SET @iCount = 1

	  WHILE (@iCount <= len(@PESO))
	  BEGIN
	      IF @NEWPESO <> '' AND SUBSTRING(@PESO, @iCount, 1) = ' '
		    BREAK

		  IF SUBSTRING(@PESO, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			  SET @NEWPESO = @NEWPESO + SUBSTRING(@PESO, @iCount, 1)

		  SET @iCount = @iCount + 1

	  END

	  SET @PESO = @NEWPESO

	  --print 'peso'

	  -- Superficie Gommata

	  SET @NEWSUP_GOMMATA = ''

	  SET @iCount = 1

	  WHILE (@iCount <= len(@SUP_GOMMATA))
	  BEGIN
	      IF @NEWSUP_GOMMATA <> '' AND SUBSTRING(@SUP_GOMMATA, @iCount, 1) = ' '
		    BREAK


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

	      IF @NEWLG <> '' AND SUBSTRING(@LG, @iCount, 1) = ' '
		    BREAK

		  IF SUBSTRING(@LG, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			  SET @NEWLG = @NEWLG + SUBSTRING(@LG, @iCount, 1)

		  SET @iCount = @iCount + 1

	  END

	  SET @LG = @NEWLG

	  -- N_Motori
	  SET @NEWN_MOTORI = ''

	  SET @iCount = 1

	  WHILE (@iCount <= len(@N_MOTORI))
	  BEGIN

	  
	      IF @NEWN_MOTORI <> '' AND SUBSTRING(@N_MOTORI, @iCount, 1) = ' '
		    BREAK

		  IF SUBSTRING(@N_MOTORI, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			  SET @NEWN_MOTORI = @NEWN_MOTORI + SUBSTRING(@N_MOTORI, @iCount, 1)

		  SET @iCount = @iCount + 1

	  END

	  SET @N_MOTORI = @NEWN_MOTORI

	  -- Potenza
	  SET @NEWPOTENZA = ''

	  SET @iCount = 1

	  WHILE (@iCount <= len(@POTENZA))
	  BEGIN

	      IF @NEWPOTENZA <> '' AND SUBSTRING(@POTENZA, @iCount, 1) = ' '
		    BREAK

		  IF SUBSTRING(@POTENZA, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			  SET @NEWPOTENZA = @NEWPOTENZA + SUBSTRING(@POTENZA, @iCount, 1)

		  SET @iCount = @iCount + 1

	  END

	  SET @POTENZA = @NEWPOTENZA

	  -- MTPH
	  SET @NEWMTPH = ''

	  SET @iCount = 1

	  WHILE (@iCount <= len(@MTPH))
	  BEGIN

	      IF @NEWMTPH <> '' AND SUBSTRING(@MTPH, @iCount, 1) = ' '
		    BREAK

		  IF SUBSTRING(@MTPH, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			  SET @NEWMTPH = @NEWMTPH + SUBSTRING(@MTPH, @iCount, 1)

		  SET @iCount = @iCount + 1

	  END

	  SET @MTPH = @NEWMTPH

	  -- Lunghezza Macchina
	  SET @NEWLUNG_MACC = ''

	  SET @iCount = 1

	  WHILE (@iCount <= len(@LUNG_MACC))
	  BEGIN


	  	  IF @NEWLUNG_MACC <> '' AND SUBSTRING(@LUNG_MACC, @iCount, 1) = ' '
		    BREAK

		  IF SUBSTRING(@LUNG_MACC, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			  SET @NEWLUNG_MACC = @NEWLUNG_MACC + SUBSTRING(@LUNG_MACC, @iCount, 1)

		  SET @iCount = @iCount + 1

	  END

	  SET @LUNG_MACC = @NEWLUNG_MACC

	  -- Larghezza Macchina

	  SET @NEWLARG_MACC = ''

	  SET @iCount = 1

	  WHILE (@iCount <= len(@LARG_MACC))
	  BEGIN

	      IF @NEWLARG_MACC <> '' AND SUBSTRING(@LARG_MACC, @iCount, 1) = ' '
		    BREAK

		  IF SUBSTRING(@LARG_MACC, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			  SET @NEWLARG_MACC = @NEWLARG_MACC + SUBSTRING(@LARG_MACC, @iCount, 1)

		  SET @iCount = @iCount + 1

	  END

	  SET @LARG_MACC = @NEWLARG_MACC

	  -- Area contorno

  	  SET @NEWshmetal_AreaContorno_mm2 = ''

	  SET @iCount = 1

	  WHILE (@iCount <= len(@shmetal_AreaContorno_mm2))
	  BEGIN

		  IF @NEWshmetal_AreaContorno_mm2 <> '' AND SUBSTRING(@shmetal_AreaContorno_mm2, @iCount, 1) = ' '
		  BREAK

		  IF SUBSTRING(@shmetal_AreaContorno_mm2, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
		  SET @NEWshmetal_AreaContorno_mm2 = @NEWshmetal_AreaContorno_mm2 + SUBSTRING(@shmetal_AreaContorno_mm2, @iCount, 1)

		  SET @iCount = @iCount + 1

	  END

	  SET @shmetal_AreaContorno_mm2 = @NEWshmetal_AreaContorno_mm2


	  -- L1 contorno

	  SET @NEWshmetal_L1_Contorno = ''

      SET @iCount = 1

      WHILE (@iCount <= len(@shmetal_L1_Contorno))
      BEGIN

        IF @NEWshmetal_L1_Contorno <> '' AND SUBSTRING(@shmetal_L1_Contorno, @iCount, 1) = ' '
          BREAK

        IF SUBSTRING(@shmetal_L1_Contorno, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
	      SET @NEWshmetal_L1_Contorno = @NEWshmetal_L1_Contorno + SUBSTRING(@shmetal_L1_Contorno, @iCount, 1)

        SET @iCount = @iCount + 1

      END

      SET @shmetal_L1_Contorno = @NEWshmetal_L1_Contorno

	  -- L2 contorno

      SET @NEWshmetal_L2_Contorno = ''

      SET @iCount = 1

      WHILE (@iCount <= len(@shmetal_L2_Contorno))
      BEGIN

        IF @NEWshmetal_L2_Contorno <> '' AND SUBSTRING(@shmetal_L2_Contorno, @iCount, 1) = ' '
           BREAK

        IF SUBSTRING(@shmetal_L2_Contorno, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
	      SET @NEWshmetal_L2_Contorno = @NEWshmetal_L2_Contorno + SUBSTRING(@shmetal_L2_Contorno, @iCount, 1)

        SET @iCount = @iCount + 1

      END

      SET @shmetal_L2_Contorno = @NEWshmetal_L2_Contorno

	  -- Piegature
      SET @NEWshmetal_Piegature = ''

      SET @iCount = 1

      WHILE (@iCount <= len(@shmetal_Piegature))
      BEGIN

        IF @NEWshmetal_Piegature <> '' AND SUBSTRING(@shmetal_Piegature, @iCount, 1) = ' '
          BREAK

        IF SUBSTRING(@shmetal_Piegature, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
	      SET @NEWshmetal_Piegature = @NEWshmetal_Piegature + SUBSTRING(@shmetal_Piegature, @iCount, 1)

        SET @iCount = @iCount + 1

      END

      SET @shmetal_Piegature = @NEWshmetal_Piegature

	  -- RaggioDiPiegatura
      SET @NEWshmetal_RaggioDiPiegatura = ''

	  SET @iCount = 1

	  WHILE (@iCount <= len(@shmetal_RaggioDiPiegatura))
	  BEGIN

		IF @NEWshmetal_RaggioDiPiegatura <> '' AND SUBSTRING(@shmetal_RaggioDiPiegatura, @iCount, 1) = ' '
	      BREAK

		IF SUBSTRING(@shmetal_RaggioDiPiegatura, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			SET @NEWshmetal_RaggioDiPiegatura = @NEWshmetal_RaggioDiPiegatura + SUBSTRING(@shmetal_RaggioDiPiegatura, @iCount, 1)

		SET @iCount = @iCount + 1

	  END

	  SET @shmetal_RaggioDiPiegatura = @NEWshmetal_RaggioDiPiegatura

	  -- Sp Lamiera
	  SET @NEWshmetal_Sp_Lamiera = ''

      SET @iCount = 1

      WHILE (@iCount <= len(@shmetal_Sp_Lamiera))
      BEGIN

        IF @NEWshmetal_Sp_Lamiera <> '' AND SUBSTRING(@shmetal_Sp_Lamiera, @iCount, 1) = ' '
          BREAK

        IF SUBSTRING(@shmetal_Sp_Lamiera, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
	      SET @NEWshmetal_Sp_Lamiera = @NEWshmetal_Sp_Lamiera + SUBSTRING(@shmetal_Sp_Lamiera, @iCount, 1)

        SET @iCount = @iCount + 1

      END

      SET @shmetal_Sp_Lamiera = @NEWshmetal_Sp_Lamiera


	  -- IngombroX

      SET @NEWIngombroX = ''

      SET @iCount = 1

      WHILE (@iCount <= len(@IngombroX))
      BEGIN

        IF @NEWIngombroX <> '' AND SUBSTRING(@IngombroX, @iCount, 1) = ' '  
           BREAK

        IF SUBSTRING(@IngombroX, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
	       SET @NEWIngombroX = @NEWIngombroX + SUBSTRING(@IngombroX, @iCount, 1)

        SET @iCount = @iCount + 1

      END

      SET @IngombroX = @NEWIngombroX

	  -- IngombroY

      SET @NEWIngombroY = ''

      SET @iCount = 1

      WHILE (@iCount <= len(@IngombroY))
      BEGIN

        IF @NEWIngombroY <> '' AND SUBSTRING(@IngombroY, @iCount, 1) = ' '
           BREAK

        IF SUBSTRING(@IngombroY, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
	      SET @NEWIngombroY = @NEWIngombroY + SUBSTRING(@IngombroY, @iCount, 1)

        SET @iCount = @iCount + 1

      END

      SET @IngombroY = @NEWIngombroY

	  -- IngombroZ

      SET @NEWIngombroZ = ''

      SET @iCount = 1

      WHILE (@iCount <= len(@IngombroZ))
      BEGIN   

        IF @NEWIngombroZ <> '' AND SUBSTRING(@IngombroZ, @iCount, 1) = ' '
          BREAK

        IF SUBSTRING(@IngombroZ, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
	      SET @NEWIngombroZ = @NEWIngombroZ + SUBSTRING(@IngombroZ, @iCount, 1)

        SET @iCount = @iCount + 1

      END

      SET @IngombroZ = @NEWIngombroZ




	  IF TRY_CAST(@N_MOTORI AS int) IS NULL	  
	  BEGIN
	  	--print @DEDID
		--print '@N_MOTORI'
		--print @N_MOTORI

	    SET @N_MOTORI = '0'
	  END


	  IF TRY_CAST(@POTENZA AS numeric(18,8)) IS NULL	  
	  BEGIN
	    --print @DEDID
		--print 'POTENZA'
		--print @POTENZA

	    SET @POTENZA = '0'
	  END

	  IF TRY_CAST(@MTPH AS numeric(18,8)) IS NULL	  
	  BEGIN
	    --print @DEDID
		--print 'MTPH'
		--print @MTPH

	    SET @MTPH = '0'
	  END

	  
	  IF TRY_CAST(@LUNG_MACC AS numeric(18,8)) IS NULL	  
	  BEGIN
	  	--print @DEDID
		--print '@LUNG_MACC'
		--print @LUNG_MACC

	    SET @LUNG_MACC = '0'
	  END

	  IF TRY_CAST(@LARG_MACC AS numeric(18,8)) IS NULL	  
	  BEGIN
	    --print @DEDID
		--print '@LARG_MACC'
		--print @LARG_MACC

	    SET @LARG_MACC = '0'
	  END

	  
	  IF TRY_CAST(@SUP_GOMMATA AS numeric(18,8)) IS NULL
	  
	  BEGIN
	  	--print @DEDID
		--print '@SUP_GOMMATA'
		--print @SUP_GOMMATA

	    SET @SUP_GOMMATA = '0'
	  END

	  IF TRY_CAST(@PESO AS numeric(18,4)) IS NULL	  
	  BEGIN
	    --print @DEDID
		--print '@PESO'
		--print @PESO

	    SET @PESO = 0
	  END
		 
	  IF TRY_CAST(@LG AS numeric(18,4)) IS NULL
	  
	  BEGIN
	    --print @DEDID
		--print '@LG'
		--print @LG

	    SET @LG = '0'
	  END

	  IF TRY_CAST(@DATA AS smalldatetime) IS NULL
	  BEGIN

	    SET @DATA = NULL

      END

	  IF TRY_CAST(@shmetal_AreaContorno_mm2 AS numeric(18,8)) IS NULL
	  
	  BEGIN
	    --print @DEDID
		--print '@LG'
		--print @LG

	    SET @shmetal_AreaContorno_mm2 = '0'
	  END

	  IF TRY_CAST(@shmetal_L1_Contorno AS numeric(18,8)) IS NULL
	  
	  BEGIN
	    --print @DEDID
		--print '@LG'
		--print @LG

	    SET @shmetal_L1_Contorno = '0'
	  END
	  
	  IF TRY_CAST(@shmetal_L2_Contorno AS numeric(18,8)) IS NULL
	  
	  BEGIN
	    --print @DEDID
		--print '@LG'
		--print @LG

	    SET @shmetal_L2_Contorno = '0'
	  END
	  	  
	  IF TRY_CAST(@shmetal_Piegature AS numeric(18,8)) IS NULL
	  
	  BEGIN
	    --print @DEDID
		--print '@LG'
		--print @LG

	    SET @shmetal_Piegature = '0'
	  END

	  IF TRY_CAST(@shmetal_RaggioDiPiegatura AS numeric(18,8)) IS NULL
	  
	  BEGIN
	    --print @DEDID
		--print '@LG'
		--print @LG

  	    SET @shmetal_RaggioDiPiegatura = '0'
	  END
	  
	  IF TRY_CAST(@shmetal_Sp_Lamiera AS numeric(18,8)) IS NULL
	  
	  BEGIN
	    --print @DEDID
		--print '@LG'
		--print @LG

	    SET @shmetal_Sp_Lamiera = '0'
	  END
	 	  
	  IF TRY_CAST(@IngombroX AS numeric(18,8)) IS NULL
	  
	  BEGIN
	    --print @DEDID
		--print '@LG'
		--print @LG

	    SET @IngombroX = '0'
	  END

	  IF TRY_CAST(@IngombroY AS numeric(18,8)) IS NULL
	  
	  BEGIN
	    --print @DEDID
		--print '@LG'
		--print @LG

	    SET @IngombroY = '0'
	  END
	  
	  IF TRY_CAST(@IngombroZ AS numeric(18,8)) IS NULL
	  
	  BEGIN
	    --print @DEDID
		--print '@LG'
		--print @LG

	    SET @IngombroZ = '0'
	  END
	  
	  	 	  	  
	  --print 'pippo4'

		
      -- Sostituisco nelle note i caratteri < e > che danno problemi nell'XML con [ e ]

	  SET @NoteDATA = REPLACE(REPLACE(@DATA, '<', '['), '>', ']')
	  SET @NoteDISEGNATOR = REPLACE(REPLACE(@DISEGNATOR, '<', '['), '>', ']')
	  SET @NoteLG = REPLACE(REPLACE(@LG, '<', '['), '>', ']')
	  SET @NoteMATERIALE = REPLACE(REPLACE(@MATERIALE, '<', '['), '>', ']')
	  SET @NoteNOTA_DI_TAGLIO = REPLACE(REPLACE(@NOTA_DI_TAGLIO, '<', '['), '>', ']')
	  SET @NoteTRATT_TERM = REPLACE(REPLACE(@TRATT_TERM, '<', '['), '>', ']')
	  SET @NoteCOMMESSA = REPLACE(REPLACE(@COMMESSA, '<', '['), '>', ']')
	  SET @NoteATTR1 = REPLACE(REPLACE(@ATTR1, '<', '['), '>', ']')
	  SET @NotePOTENZA = REPLACE(REPLACE(@POTENZA, '<', '['), '>', ']')
	  SET @NoteN_MOTORI = REPLACE(REPLACE(@N_MOTORI, '<', '['), '>', ']')
	  SET @NoteNOME_COMM = REPLACE(REPLACE(@NOME_COMM, '<', '['), '>', ']')
	  SET @NoteLargMacchina = REPLACE(REPLACE(@LargMacchina, '<', '['), '>', ']')
	  SET @NoteLungMacchina = REPLACE(REPLACE(@LungMacchina, '<', '['), '>', ']')
	  SET @NoteMTPH = REPLACE(REPLACE(@MTPH, '<', '['), '>', ']')
	  SET @NoteSUP_GOMMATA = REPLACE(REPLACE(@SUP_GOMMATA, '<', '['), '>', ']')
	  SET @NoteEX_CODICE = REPLACE(REPLACE(@EX_CODICE, '<', '['), '>', ']')

	  SET @NoteDescTecnicaITA = REPLACE(REPLACE(@DescTecnicaITA, '<', '['), '>', ']')
      SET @NoteDescTecnicaENG = REPLACE(REPLACE(@DescTecnicaENG, '<', '['), '>', ']')
      SET @NoteDescCommITA = REPLACE(REPLACE(@DescCommITA, '<', '['), '>', ']')
      SET @NoteDescCommENG = REPLACE(REPLACE(@DescCommENG, '<', '['), '>', ']')
	  SET @NoteTrattFinitura = REPLACE(REPLACE(@TrattFinitura, '<', '['), '>', ']')
      SET @NoteTrattGalvanico = REPLACE(REPLACE(@TrattGalvanico, '<', '['), '>', ']')
      SET @NoteTrattProtez = REPLACE(REPLACE(@TrattProtez, '<', '['), '>', ']')
      SET @NoteTrattSuperf = REPLACE(REPLACE(@TrattSuperf, '<', '['), '>', ']')
	  SET @NotexItem = REPLACE(REPLACE(@xItem, '<', '['), '>', ']')
	  SET @NoteSOTTOCOMMESSA = REPLACE(REPLACE(@SOTTOCOMMESSA, '<', '['), '>', ']')
      SET @NoteStandard_DIN = REPLACE(REPLACE(@Standard_DIN, '<', '['), '>', ']')
      SET @NoteStandard_ISO = REPLACE(REPLACE(@Standard_ISO, '<', '['), '>', ']')
      SET @NoteStandard_UNI = REPLACE(REPLACE(@Standard_UNI, '<', '['), '>', ']')
      SET @NoteProduttore = REPLACE(REPLACE(@Produttore, '<', '['), '>', ']')
      SET @Noteshmetal_AreaContorno_mm2 = REPLACE(REPLACE(@shmetal_AreaContorno_mm2, '<', '['), '>', ']')
      SET @Noteshmetal_L1_Contorno = REPLACE(REPLACE(@shmetal_L1_Contorno, '<', '['), '>', ']')
      SET @Noteshmetal_L2_Contorno = REPLACE(REPLACE(@shmetal_L2_Contorno, '<', '['), '>', ']')
      SET @Noteshmetal_Piegature = REPLACE(REPLACE(@shmetal_Piegature, '<', '['), '>', ']')
      SET @Noteshmetal_RaggioDiPiegatura = REPLACE(REPLACE(@shmetal_RaggioDiPiegatura, '<', '['), '>', ']')
      SET @Noteshmetal_Sp_Lamiera = REPLACE(REPLACE(@shmetal_Sp_Lamiera, '<', '['), '>', ']')
      SET @NoteDesignazione = REPLACE(REPLACE(@Designazione, '<', '['), '>', ']')
      SET @NoteDesignazioneGeometrica = REPLACE(REPLACE(@DesignazioneGeometrica, '<', '['), '>', ']')
      SET @NoteDesignazioneGeometricaEN = REPLACE(REPLACE(@DesignazioneGeometricaEN, '<', '['), '>', ']')
      SET @NoteDesignazioneGeometricaENG = REPLACE(REPLACE(@DesignazioneGeometricaENG, '<', '['), '>', ']')
      SET @NoteDesignazioneGeometricaITA = REPLACE(REPLACE(@DesignazioneGeometricaITA, '<', '['), '>', ']')
      SET @NoteIngombroX = REPLACE(REPLACE(@IngombroX, '<', '['), '>', ']')
      SET @NoteIngombroY = REPLACE(REPLACE(@IngombroY, '<', '['), '>', ']')
      SET @NoteIngombroZ = REPLACE(REPLACE(@IngombroZ, '<', '['), '>', ']')
      SET @NoteLargMacchina = REPLACE(REPLACE(@LargMacchina, '<', '['), '>', ']')
      SET @NoteLungMacchina = REPLACE(REPLACE(@LungMacchina, '<', '['), '>', ']')
      SET @NoteCATEGORIA4 = REPLACE(REPLACE(@CATEGORIA4, '<', '['), '>', ']')
      SET @NoteCATEGORIA4_PREFIX = REPLACE(REPLACE(@CATEGORIA4_PREFIX, '<', '['), '>', ']')
      SET @NoteCodiceProduttore = REPLACE(REPLACE(@CodiceProduttore, '<', '['), '>', ']')
      SET @NoteCATEGORIA0 = REPLACE(REPLACE(@CATEGORIA0, '<', '['), '>', ']')
      SET @NoteCATEGORIA0_PREFIX = REPLACE(REPLACE(@CATEGORIA0_PREFIX, '<', '['), '>', ']')


	  SET @NotePreventivo = ''



      SET @NoteXML = NULL

	  IF ISNULL(@NoteDATA, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="6">' + @NoteDATA + '</row>'
		  
      END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="6">' + '</row>'


	  END

      IF ISNULL(@NoteDISEGNATOR, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="7">' + @NoteDISEGNATOR + '</row>'
		  
      END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="7">' + '</row>'


	  END

	  IF ISNULL(@NoteLG, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="8">' + @NoteLG + '</row>'
		  
      END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="8">' + '</row>'

	  END

	  IF ISNULL(@NoteMATERIALE, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="9">' + @NoteMATERIALE + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="9">' + '</row>'

	  END

	  IF ISNULL(@NoteNOTA_DI_TAGLIO, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="10">' + @NoteNOTA_DI_TAGLIO + '</row>'
		  
      END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="10">' + '</row>'


	  END

	  IF ISNULL(@NoteTRATT_TERM, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="11">' + @NoteTRATT_TERM + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="11">' + '</row>'

	  END

	  IF ISNULL(@NoteCOMMESSA, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="12">' + @NoteCOMMESSA + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="12">' + '</row>'


	  END

	  IF ISNULL(@NoteATTR1, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="13">' + @NoteATTR1 + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="13">' + '</row>'


	  END

	  IF ISNULL(@NotePOTENZA, '') <> '' AND @Livello = 1
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="15">' + @NotePOTENZA + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="15">' + '</row>'

	  END

	  IF ISNULL(@NoteN_MOTORI, '') <> '' AND @Livello = 1
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="17">' + @NoteN_MOTORI + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="17">' + '</row>'

	  END


	  IF ISNULL(@NoteNOME_COMM, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="18">' + @NoteNOME_COMM + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="18">' + '</row>'


	  END

	  IF ISNULL(@NoteLargMacchina, '') <> '' AND @Livello = 1 AND SUBSTRING(ISNULL(@xItem, ''), 1, 1) = 'C'
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="19">' + @NoteLargMacchina + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="19">' + '</row>'


	  END

	  IF ISNULL(@NoteLungMacchina, '') <> '' AND @Livello = 1 AND SUBSTRING(ISNULL(@xItem, ''), 1, 1) = 'C'
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="20">' + @NoteLungMacchina + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="20">' + '</row>'

	  END

	  IF ISNULL(@NoteMTPH, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="21">' + @NoteMTPH + '</row>'
		  
	  END
	  ELSE
	  BEGIN


		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="21">' + '</row>'


	  END

	  IF ISNULL(@NoteSUP_GOMMATA, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="22">' + @NoteSUP_GOMMATA + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="22">' + '</row>'


	  END

	  IF ISNULL(@NoteEX_CODICE, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="23">' + @NoteEX_CODICE + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="23">' + '</row>'


	  END

	  IF ISNULL(@NotePreventivo, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="24">' + @NotePreventivo + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="24">' + '</row>'


	  END

	  IF ISNULL(@NoteDescTecnicaITA, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="28">' + @NoteDescTecnicaITA + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="28">' + '</row>'


	  END


	  IF ISNULL(@NoteDescTecnicaENG, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="29">' + @NoteDescTecnicaENG + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="29">' + '</row>'


	  END

	  	  IF ISNULL(@NoteDescCommITA, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="30">' + @NoteDescCommITA + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="30">' + '</row>'


	  END

	  IF ISNULL(@NoteDescCommENG, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="31">' + @NoteDescCommENG + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="31">' + '</row>'


	  END


	  IF ISNULL(@NoteTrattFinitura, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="33">' + @NoteTrattFinitura + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="33">' + '</row>'


	  END

	  IF ISNULL(@NoteTrattGalvanico, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="34">' + @NoteTrattGalvanico + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="34">' + '</row>'


	  END

	  IF ISNULL(@NoteTrattProtez, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="35">' + @NoteTrattProtez + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="35">' + '</row>'


	  END

	  IF ISNULL(@NoteTrattSuperf, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="36">' + @NoteTrattSuperf + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="36">' + '</row>'


	  END

	  IF ISNULL(@NotexItem, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="37">' + @NotexItem + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="37">' + '</row>'


	  END

	  IF ISNULL(@NoteSOTTOCOMMESSA, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="38">' + @NoteSOTTOCOMMESSA + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="38">' + '</row>'


	  END

	  IF ISNULL(@NoteStandard_DIN, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="39">' + @NoteStandard_DIN + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="39">' + '</row>'


	  END

	  IF ISNULL(@NoteStandard_ISO, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="40">' + @NoteStandard_ISO + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="40">' + '</row>'


	  END

	  IF ISNULL(@NoteStandard_UNI, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="41">' + @NoteStandard_UNI + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="41">' + '</row>'


	  END

	  IF ISNULL(@NoteProduttore, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="42">' + @NoteProduttore + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="42">' + '</row>'


	  END

	  	  IF ISNULL(@Noteshmetal_AreaContorno_mm2, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="43">' + @Noteshmetal_AreaContorno_mm2 + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="43">' + '</row>'


	  END

	  IF ISNULL(@Noteshmetal_L1_Contorno, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="44">' + @Noteshmetal_L1_Contorno + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="44">' + '</row>'


	  END

	  	  IF ISNULL(@Noteshmetal_L2_Contorno, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="45">' + @Noteshmetal_L2_Contorno + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="45">' + '</row>'


	  END


	  IF ISNULL(@Noteshmetal_Piegature, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="46">' + @Noteshmetal_Piegature + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="46">' + '</row>'


	  END

	  IF ISNULL(@Noteshmetal_RaggioDiPiegatura, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="47">' + @Noteshmetal_RaggioDiPiegatura + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="47">' + '</row>'


	  END

	  	  IF ISNULL(@Noteshmetal_Sp_Lamiera, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="48">' + @Noteshmetal_Sp_Lamiera + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="48">' + '</row>'


	  END


	  IF ISNULL(@NoteDesignazione, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="49">' + @NoteDesignazione + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="49">' + '</row>'


	  END

	  IF ISNULL(@NoteDesignazioneGeometrica, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="50">' + @NoteDesignazioneGeometrica + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="50">' + '</row>'


	  END

	  IF ISNULL(@NoteDesignazioneGeometricaEN, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="51">' + @NoteDesignazioneGeometricaEN + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="51">' + '</row>'


	  END

	  IF ISNULL(@NoteDesignazioneGeometricaENG, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="52">' + @NoteDesignazioneGeometricaENG + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="52">' + '</row>'


	  END

	  IF ISNULL(@NoteDesignazioneGeometricaITA, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="53">' + @NoteDesignazioneGeometricaITA + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="53">' + '</row>'


	  END

	  IF ISNULL(@NoteIngombroX, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="54">' + @NoteIngombroX + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="54">' + '</row>'


	  END


	  IF ISNULL(@NoteIngombroY, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="55">' + @NoteIngombroY + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="55">' + '</row>'


	  END

	  IF ISNULL(@NoteIngombroZ, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="56">' + @NoteIngombroZ + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="56">' + '</row>'


	  END


	  IF ISNULL(@NoteCATEGORIA4_PREFIX, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="57">' + @NoteCATEGORIA4_PREFIX + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="57">' + '</row>'


	  END

	  IF ISNULL(@NoteCATEGORIA4, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="58">' + @NoteCATEGORIA4 + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="58">' + '</row>'


	  END

	  IF ISNULL(@NoteCodiceProduttore, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="59">' + @NoteCodiceProduttore + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="59">' + '</row>'


	  END

	  IF ISNULL(@NoteCATEGORIA0_PREFIX, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="60">' + @NoteCATEGORIA0_PREFIX + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="60">' + '</row>'


	  END

	  IF ISNULL(@NoteCATEGORIA0, '') <> ''
	  BEGIN
		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="61">' + @NoteCATEGORIA0 + '</row>'
		  
	  END
	  ELSE
	  BEGIN

		IF @NoteXML IS NULL
		  SET @NoteXML = '<rows>'

		SET @NoteXML = @NoteXML + '<row nota="61">' + '</row>'


	  END
	
	  IF @NoteXML IS NOT NULL
		SET @NoteXML = @NoteXML + '</rows>'
     	  
	  --SET @NoteXML = REPLACE(@NoteXML, '°', '')
	  SET @NoteXML = REPLACE(@NoteXML, '&', ' ')

	  --print @NoteXML

	  --print 'pippo51'
	  --print @PESO

	  SET @PesoNetto = NULL

	  IF @PESO IS NULL
		SET @PesoNetto = 0
	  ELSE
	    IF ISNUMERIC(@PESO) = 1
		  SET @PesoNetto =  (CAST(REPLACE(@PESO, ',' , '.') AS numeric(18,4))) * @Fattore#UMMass
		ELSE
		  SET @PesoNetto = 0

      --print 'pippo52'
      SET @SuperficieGommata = NULL

	  IF @SUP_GOMMATA IS NULL
		SET @SuperficieGommata = 0
	  ELSE
	    IF ISNUMERIC(@SUP_GOMMATA) = 1
		  SET @SuperficieGommata = (CAST(REPLACE(@SUP_GOMMATA, ',' , '.') AS numeric(18,4))) * @FattoreUMLinear * @FattoreUMLinear
		ELSE
		  SET @SuperficieGommata = 0

      SET @LgNumero = NULL

	  --print 'pippo53'

	  IF @LG IS NULL
		SET @LgNumero = 0
	  ELSE
	    IF ISNUMERIC(@LG) = 1
		  SET @LgNumero = (CAST(REPLACE(@LG, ',' , '.') AS numeric(18,4))) * @FattoreUMLinear
		ELSE
		  SET @LgNumero = 0


	  -- Salvo valori su temporary table per essere utilizzati dal padre
	  IF NOT EXISTS (SELECT 1 FROM #ICM_Data_Art WHERE Cd_AR = @DedCodInput)
	  BEGIN

	    --print 'insert #ICM_Data_Art'

	    --print '@DedCodInput'
	    --print @DedCodInput
        --print '@LgNUmero'
	    --print @LgNUmero
	    --print '@PesoNetto'
	    --print @PesoNetto
	    --print '@SuperficieGommata'
	  	--print @SuperficieGommata

	    INSERT INTO #ICM_Data_Art
	    (
		    Cd_AR
		  , Lunghezza
		  , PesoNetto
		  , SupGommata
		  
	    )
		VALUES
		(
		
		    @DedCodInput
		  , @LgNUmero
		  , @PesoNetto
		  , @SuperficieGommata
		
		)


	  END

	  
	  SET @DBKit = 0
      

	  IF @FaiAcquista = 'FAI' OR ISNULL(@FaiAcquista, '') = ''
	    SET @DBFaiAcquista = 1
	  ELSE
	    SET @DBFaiAcquista = 0

	  --SET #UMAcquisto = 0

	  --IF ISNULL(@FAMIGLIA1_PREFIX, '') = '' OR @FAMIGLIA1_PREFIX IN ('MOT','RID','COM','BUL','FIX','RUL','RAS','RET','GOM','TAM','OLE','MON','TEC','FUS','ELE','PAR','ATM') OR (NOT @FAMIGLIA1_PREFIX IN('MOT','RID','COM','TAP','BUL','FIX','GRI','RUL','RAS','RET','GOM','TAM','SAL','SAS','PRO','LAM','HDX','TUB','LAG','OLE','MON','TEC','FUS','ELE','PAR','ATM','SAM','SHD'))
	  --IF ISNULL(@FAMIGLIA1_PREFIX, '') = '' OR (@FAMIGLIA1_PREFIX NOT IN (  '600' /* Carpenterie */
	  --                                                                    , '520' /* Grigliati */))
      --SET #UMAcquisto = 0
	  --ELSE
	  --SET #UMAcquisto = 1


	  SET @NewDescrizione = @DESCRIZION
	  
	  --print 'qui'

	  IF NOT EXISTS (SELECT 1 FROM AR WHERE Cd_AR = @DedCodInput)
	  BEGIN

	    --print 'not exists'



	    IF @Azione <> 'D'
		BEGIN

		  --print 'insert'
		  --print @DedCodInput

		  --print 'prima insert'
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
           --, LottoRiordino
           --, PesoLordo
           , PesoNetto
           --, PesoFattore
           --, PesoLordoMks
           --, PesoNettoMks
           --, Altezza
           , Lunghezza
           --, Larghezza
           , DimensioniFattore
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
		   , xNMotori
		   , xPotenza
		   , xLunghezzaMacchina
		   , xLarghezzaMacchina
		   , xSupGommata
		   , xData
		   , xDisegnatore
		   , xMateriale
		   , xNotaTaglio
		   , xTrattTermico
		   , xCommessa
		   , xSottocommessa
		   , xAttr1
		   , xDescCommessa
		   , xMTPH
		   , xExCodice
		   , xPreventivo
	       , xDescTecITA
	       , xDescTecENG
	       , xDescCommITA
	       , xDescCommENG
	       , xTrattamentoFinitura
	       , xTrattGalvanico
	       , xTrattProtezione
	       , xTrattSuperficie	       
	       , xStandardDIN
	       , xStandardISO
	       , xStandardUNI
	       , xProduttore
	       , xContLam
	       , xContLamL1
	       , xContLamL2
	       , xPiegatureLam
	       , xRaggioPiegaturaLam
	       , xSpessoreLam
	       , xDesig
	       , xDesigGeoENG
	       , xDesigGeoITA
	       , xIngombroX
	       , xIngombroY
	       , xIngombroZ
	       , xCategoriaPrefisso4
	       , xCategoria4
	       , xCodProduttore
	       , xCategoriaPrefisso0
	       , xCategoria0


           ) VALUES (
           --Id_AR
           @DedCodInput --Cd_AR
           , SUBSTRING(@NewDescrizione, 1 , 80)		--Descrizione
           , SUBSTRING(@NewDescrizione, 1, 40)	--DescrizioneBreve
           --,								--VBDescrizione
           --,								--Note_AR
           , @FAMIGLIA1_PREFIX		        --Cd_ARGruppo1
           , @FAMIGLIA2_PREFIX				--Cd_ARGruppo2
           , @FAMIGLIA3_PREFIX			    --Cd_ARGruppo3
           , @CATEGORIA1_PREFIX             --Cd_ARClasse1
           , @CATEGORIA2_PREFIX			    --Cd_ARClasse2
           , @CATEGORIA3_PREFIX				--Cd_ARClasse3
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
           --, @LottoRiordinoTuboBavetta		--LottoRiordino
           --,								--PesoLordo
           , @PesoNetto    					--PesoNetto
           --,								--PesoFattore
           --,								--PesoLordoMks
           --,								--PesoNettoMks  
           --,								--Altezza
           , CAST(@LG AS numeric(18,4))   	--Lunghezza
           --,								--Larghezza
           , 0.001						    --DimensioniFattore
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
           , @DBFaiAcquista						--DBFaiAcquista
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
		   , CAST (@Cd_xStatoDED AS char(3))
	       , CASE WHEN @Livello = 1 THEN @xItem ELSE NULL END
		   , @DEDREV --CASE WHEN @Livello = 0 THEN @DEDREV ELSE @DED_xRevisione END
		   , CAST(@N_MOTORI AS int)
		   , CAST(@POTENZA AS numeric(18,8))
		   , CAST(@LUNG_MACC AS numeric(18,8))
		   , CAST(@LARG_MACC AS numeric(18,8))
		   , CAST(@SUP_GOMMATA AS numeric(18,8))
		   , CAST(@DATA AS smalldatetime)
		   , @DISEGNATOR
		   , @MATERIALE
		   , @NOTA_DI_TAGLIO
		   , @TRATT_TERM
		   , SUBSTRING(@COMMESSA, 1, 10)
		   , SUBSTRING(@COMMESSA, 1, 20)
		   , @ATTR1
		   , SUBSTRING(@NOME_COMM, 1, 80)
		   , CAST(@MTPH AS numeric(18,8))
		   , SUBSTRING(@EX_CODICE, 1, 20)
		   , ''
	       , SUBSTRING(@DescTecnicaITA, 1, 100)
	       , SUBSTRING(@DescTecnicaENG, 1, 100)
	       , SUBSTRING(@DescCommITA, 1, 100)
	       , SUBSTRING(@DescCommENG, 1, 100)
	       , SUBSTRING(@TrattFinitura, 1, 100)
	       , SUBSTRING(@TrattGalvanico, 1, 100)
	       , SUBSTRING(@TrattProtez, 1, 100)
	       , SUBSTRING(@TrattSuperf, 1, 100)	       
	       , SUBSTRING(@Standard_DIN, 1, 100)
	       , SUBSTRING(@Standard_ISO, 1, 100)
	       , SUBSTRING(@Standard_UNI, 1, 100)
	       , SUBSTRING(@Produttore, 1, 100)
	       , CAST(@shmetal_AreaContorno_mm2 AS numeric(18,8))
	       , CAST(@shmetal_L1_Contorno AS numeric(18,8))
	       , CAST(@shmetal_L2_Contorno AS numeric(18,8))
	       , CAST(@shmetal_Piegature AS int)
	       , CAST(@shmetal_RaggioDiPiegatura AS numeric (18,8))
	       , CAST(@shmetal_Sp_Lamiera AS numeric(18,8))
	       , SUBSTRING(@Designazione, 1, 100)
	       --, SUBSTRING(@DesignazioneGeometrica, 1, 100)
	       --, @DesignazioneGeometricaEN
	       , SUBSTRING(@DesignazioneGeometricaENG, 1, 100)
	       , SUBSTRING(@DesignazioneGeometricaITA, 1, 100)
	       , CAST(@IngombroX AS numeric (18,8))
	       , CAST(@IngombroY AS numeric (18,8))
	       , CAST(@IngombroZ AS numeric (18,8))
	       , SUBSTRING(@CATEGORIA4_PREFIX, 1, 100)
	       , SUBSTRING(@CATEGORIA4, 1, 100)
	       , SUBSTRING(@CodiceProduttore, 1, 100)
	       , SUBSTRING(@CATEGORIA0_PREFIX, 1, 100)
	       , SUBSTRING(@CATEGORIA0, 1, 100)
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

		  --print 'dopo insert'

		  SET @iFamIndex = 0
		  SET @bFamFound = 1

		  SELECT TOP 1 
		    @iFamIndex = id
		  FROM #FamMerc
		  WHERE name = @FAMIGLIA1_PREFIX + '-' + @FAMIGLIA2_PREFIX + '-' + @FAMIGLIA3_PREFIX

		  IF @@ROWCOUNT = 0
		  BEGIN

  		    SELECT TOP 1 
		      @iFamIndex = id
		    FROM #FamMerc
		    WHERE name = @FAMIGLIA1_PREFIX + '-' + @FAMIGLIA2_PREFIX

			IF @@ROWCOUNT = 0
			BEGIN

    		  SELECT TOP 1 
		        @iFamIndex = id
		      FROM #FamMerc
		      WHERE name = @FAMIGLIA1_PREFIX

			  IF @@ROWCOUNT = 0 
			    SET @bFamFound = 0


			END
		    

		  END


		  IF @bFamFound = 1
		  BEGIN		    
		    
			SET @UMCodPrincipale = ''

		    SELECT TOP 1 
			  @UMCod = name 
			FROM #UMMaga
			WHERE id = @iFamIndex

			IF @@ROWCOUNT = 1 AND ISNULL(@UMCod, '') <> ''
			BEGIN
			  

			  SET @UMCodPrincipale = @UMCod

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
	             , @UMCod           -- Cd_ARMisura
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
			ELSE
			BEGIN

				SET @Severity = 16

				SET @XErrore = 'Unità di misura di magazzino non trovata per item con codice: ' + @DedCodInput

				IF @Transaction = 1
					GOTO labelExit
				ELSE
					GOTO labelExit2




			END

			SELECT TOP 1 
			  @UMCod = name 
            , @UMEntity = entity
			FROM #UMAcq
			WHERE id = @iFamIndex

			IF @@ROWCOUNT = 1 AND ISNULL(@UMCod, '') <> '' AND ISNULL(@UMEntity, '') <> ''
			BEGIN

			  IF ISNULL(@UMCod, '') <> @UMCodPrincipale
			  BEGIN

			    SET @FattoreConversione = 0

				
				IF @UMEntity = 'QTA'
				  SET @FattoreConversione = 1
				ELSE
				BEGIN

				    IF UPPER(@UMEntity) = 'LG'
					BEGIN

					  IF @LgNumero IS NOT NULL
					  BEGIN

					    SET @FattoreConversione = @LgNumero

						/* Il fattore di conversione in questo punto è in MT per Linear
				           Converto con l'unità di misura espressa in famiglia merceologica */

				        SELECT TOP 1 
  	                      @FattoreUMLinearUmAcq = conv
					    FROM #UMConv
					    WHERE um1 = @UMArcaLinear
					      AND um2 = @UMCod

				        IF @@ROWCOUNT = 0
				        BEGIN

					       SELECT TOP 1 
  						     @FattoreUMLinearUmAcq = (1 / conv)
				           FROM #UMConv
			               WHERE um1 = @UmCod
					       AND um2 = @UMArcaLinear

						   IF @@ROWCOUNT = 0
					       BEGIN


						      SET @Severity = 16
						      SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UmCod + ' e ' + @UMArcaLinear + ' non trovato'

						      IF @Transaction = 1
						        GOTO labelExit
						      ELSE
						        GOTO labelExit2

					        END

					

				          END
	   

				          SET  @FattoreConversione = @FattoreConversione * @FattoreUMLinearUmAcq




					  END
					  ELSE
					  BEGIN


				        SET @Severity = 16

		                SET @XErrore = 'Lunghezza nulla per item con codice: ' + @DedCodFiglio
 
	                    IF @Transaction = 1
	                      GOTO labelExit
	                    ELSE
	                      GOTO labelExit2


					  END
					END
				  

					IF UPPER(@UMEntity) = 'PESO'
					BEGIN

					  IF @PesoNetto IS NOT NULL
					  BEGIN
					    SET @FattoreConversione = @PesoNetto


						SELECT TOP 1 
  	                      @FattoreUMMassUmAcq = conv
					    FROM #UMConv
					    WHERE um1 = @UMArcaMass
					      AND um2 = @UMCod

				        IF @@ROWCOUNT = 0
				        BEGIN

					       SELECT TOP 1 
  						     @FattoreUMMassUmAcq = (1 / conv)
				           FROM #UMConv
			               WHERE um1 = @UmCod
					       AND um2 = @UMArcaMass

						   IF @@ROWCOUNT = 0
					       BEGIN


						      SET @Severity = 16
						      SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UmCod + ' e ' + @UMArcaMass + ' non trovato'

						      IF @Transaction = 1
						        GOTO labelExit
						      ELSE
						        GOTO labelExit2

					        END

					

				          END
	   

				          SET  @FattoreConversione = @FattoreConversione * @FattoreUMMassUmAcq
					  END
					  ELSE
					  BEGIN


				        SET @Severity = 16

		                SET @XErrore = 'Peso netto nullo per item con codice: ' + @DedCodFiglio
 
	                    IF @Transaction = 1
	                      GOTO labelExit
	                    ELSE
	                      GOTO labelExit2


					  END
					

					END

					IF UPPER(@UMEntity) = 'SUP_GOMMATA'
					BEGIN

					  IF @SuperficieGommata IS NOT NULL
					  BEGIN

					    SET @FattoreConversione = @SuperficieGommata

					    SELECT TOP 1 
  	                      @FattoreUMLinearUmAcq = conv
					    FROM #UMConv
					    WHERE um1 = @UMArcaLinear
					      AND um2 = @UMCod

				        IF @@ROWCOUNT = 0
				        BEGIN

					       SELECT TOP 1 
  						     @FattoreUMLinearUmAcq = (1 / conv)
				           FROM #UMConv
			               WHERE um1 = @UmCod
					       AND um2 = @UMArcaLinear

						   IF @@ROWCOUNT = 0
					       BEGIN


						      SET @Severity = 16
						      SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UmCod + ' e ' + @UMArcaLinear + ' non trovato'

						      IF @Transaction = 1
						        GOTO labelExit
						      ELSE
						        GOTO labelExit2

					       END

					

				        END
	   

				        SET  @FattoreConversione = @FattoreConversione * @FattoreUMLinearUmAcq * @FattoreUMLinearUmAcq



					  END
					  ELSE
					  BEGIN


				        SET @Severity = 16

		                SET @XErrore = 'Superficie Gommata nulla per item con codice: ' + @DedCodFiglio
 
	                    IF @Transaction = 1
	                      GOTO labelExit
	                    ELSE
	                      GOTO labelExit2


					  END

					END
			
				END
			   
			    IF ISNULL(@FattoreConversione, 0) <> 0
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
	                 , @UMCod             -- Cd_ARMisura
	                 , 'A'
                     , (1.0 / @FattoreConversione)
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
			ELSE
			BEGIN

		        SET @Severity = 16

				SET @XErrore = 'Unità di misura di acquisto non trovata per item con codice: ' + @DedCodInput

				IF @Transaction = 1
					GOTO labelExit
				ELSE
					GOTO labelExit2


			END
		  END
		  ELSE
		  BEGIN

		    SET @Severity = 16

		    SET @XErrore = 'Famiglia merceologica non trovata per item con codice: ' + @DedCodInput

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2


		  END
		

	    END
		      
      END
	  ELSE IF @Azione <> 'D' --AND (NOT @iLBAvetta = 1) AND (NOT @iLTubo = 1) AND (NOT @iLBarraFilettata = 1)
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

		
		/*		
		SET @DBKitCheck = 0
	    SET @DBFaiAcquistaCheck = 0

		SELECT @DBKitCheck = DBKit
	       ,   @DBFaiAcquistaCheck = DBFantasma
		FROM AR 
		WHERE Cd_AR = @DedCodInput


		IF (@DBKitCheck IS NULL) OR (@DBFaiAcquistaCheck IS NULL)
		BEGIN
  		  SET @DBKitCheck = 0
	      SET @DBFaiAcquistaCheck = 0
		END

		IF (@DBKit <> @DBKitCheck) OR (@DBFaiAcquista <> @DBFaiAcquistaCheck)
		BEGIN
		    SET @Severity = 16

			SET @XErrore = 'Prodotto ' + @DedCodInput + ' gia presente ma Flag Kit o Fantasma non coerente con la nuova importazione.'

	        IF @Transaction = 1
	          GOTO labelExit
	        ELSE
	          GOTO labelExit2


		END
		*/
		
		--print 'UPDATE'
		--print @xItem

		SET @PesoNettoinArticolo = NULL

		SELECT @PesoNettoinArticolo = @PesoNetto / PesoFattore 
		FROM AR 
		WHERE Cd_AR = @DedCodInput

		
		SET @Severity = @@ERROR



		IF @Severity <> 0
		BEGIN

	      IF @Transaction = 1
	        GOTO labelExit
	      ELSE
	        GOTO labelExit2

		END

		IF @PesoNettoinArticolo IS NULL
		  SET @PesoNettoinArticolo = @PesoNetto
        
	    UPDATE AR
		SET --Id_AR                       = Id_AR
	          Descrizione                 = SUBSTRING(@NewDescrizione,1 , 80)
            , DescrizioneBreve            = SUBSTRING(@NewDescrizione, 1, 40)
              --, VBDescrizione           = 
              --, Note_AR                 =
            , Cd_ARGruppo1                = @FAMIGLIA1_PREFIX
            , Cd_ARGruppo2                = @FAMIGLIA2_PREFIX
            , Cd_ARGruppo3                = @FAMIGLIA3_PREFIX
            , Cd_ARClasse1                = @CATEGORIA1_PREFIX
            , Cd_ARClasse2                = @CATEGORIA2_PREFIX
            , Cd_ARClasse3                = @CATEGORIA3_PREFIX
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
            , PesoNetto                   = @PesoNettoinArticolo
            --, PesoFattore               =
            --, PesoLordoMks              =
            --, PesoNettoMks              =
            --, Altezza                   =
            , Lunghezza                   = CAST(@LG AS numeric(18,4))
            --, Larghezza                 =
            , DimensioniFattore           = 0.001
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
              , DBFantasma                = @DBFaiAcquista
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
		    , xCd_xStatoDED = CAST (@Cd_xStatoDED AS char(3))
	        , xItem = CASE WHEN @Livello = 1 THEN @xItem ELSE NULL END
			, xRevisione = @DEDREV --CASE WHEN @Livello = 0 THEN @DEDREV ELSE @DED_xRevisione END
			, xNMotori = CAST(@N_MOTORI AS int)
		    , xPotenza = CAST(@POTENZA AS numeric(18,8))
		    , xLunghezzaMacchina = CAST(@LUNG_MACC AS numeric(18,8))
		    , xLarghezzaMacchina = CAST(@LARG_MACC AS numeric(18,8))
		    , xSupGommata = CAST(@SUP_GOMMATA AS numeric(18,8))
			, xData = CAST(@DATA AS smalldatetime)
			, xDisegnatore = @DISEGNATOR
			, xMateriale = @MATERIALE
			, xNotaTaglio = @NOTA_DI_TAGLIO
			, xTrattTermico = @TRATT_TERM
			, xCommessa = SUBSTRING(@COMMESSA, 1, 10)
			, xSottocommessa = SUBSTRING(@COMMESSA, 1, 20)
			, xAttr1 = @ATTR1
			, xDescCommessa = SUBSTRING(@NOME_COMM, 1, 80)
			, xMTPH = CAST(@MTPH AS numeric(18,8))
			, xExCodice = SUBSTRING(@EX_CODICE, 1, 20)
		    , xPreventivo = ''
	        , xDescTecITA = SUBSTRING(@DescTecnicaITA, 1, 100)
	        , xDescTecENG = SUBSTRING(@DescTecnicaENG, 1, 100)
	        , xDescCommITA = SUBSTRING(@DescCommITA, 1, 100)
	        , xDescCommENG = SUBSTRING(@DescCommENG, 1, 100)
	        , xTrattamentoFinitura = SUBSTRING(@TrattFinitura, 1, 100)
	        , xTrattGalvanico = SUBSTRING(@TrattGalvanico, 1, 100)
	        , xTrattProtezione = SUBSTRING(@TrattProtez, 1, 100)
	        , xTrattSuperficie =  SUBSTRING(@TrattSuperf, 1, 100)     
	        , xStandardDIN = SUBSTRING(@Standard_DIN, 1, 100)
	        , xStandardISO = SUBSTRING(@Standard_ISO, 1, 100)
	        , xStandardUNI = SUBSTRING(@Standard_UNI, 1, 100)
	        , xProduttore = SUBSTRING(@Produttore, 1, 100)
	        , xContLam = CAST(@shmetal_AreaContorno_mm2 AS numeric(18,8))
	        , xContLamL1 = CAST(@shmetal_L1_Contorno AS numeric(18,8))
	        , xContLamL2 = CAST(@shmetal_L2_Contorno AS numeric(18,8))
	        , xPiegatureLam = CAST(@shmetal_Piegature AS int)
	        , xRaggioPiegaturaLam = CAST(@shmetal_RaggioDiPiegatura AS numeric (18,8))
	        , xSpessoreLam = CAST(@shmetal_Sp_Lamiera AS numeric(18,8))
	        , xDesig = SUBSTRING(@Designazione, 1, 100)
	        , xDesigGeoENG = SUBSTRING(@DesignazioneGeometricaENG, 1, 100)
	        , xDesigGeoITA = SUBSTRING(@DesignazioneGeometricaITA, 1, 100)
	        , xIngombroX = CAST(@IngombroX AS numeric (18,8))
	        , xIngombroY = CAST(@IngombroY AS numeric (18,8))
	        , xIngombroZ = CAST(@IngombroZ AS numeric (18,8))
	        , xCategoriaPrefisso4 = SUBSTRING(@CATEGORIA4_PREFIX, 1, 100)
	        , xCategoria4 = SUBSTRING(@CATEGORIA4, 1, 100)
	        , xCodProduttore = SUBSTRING(@CodiceProduttore, 1, 100)
	        , xCategoriaPrefisso0 = SUBSTRING(@CATEGORIA0_PREFIX, 1, 100)
	        , xCategoria0 = SUBSTRING(@CATEGORIA0, 1, 100)

		WHERE Cd_AR = @DedCodInput

		
		SET @Severity = @@ERROR



		IF @Severity <> 0
		BEGIN

	      IF @Transaction = 1
	        GOTO labelExit
	      ELSE
	        GOTO labelExit2

		END

	    SET @iFamIndex = 0
		SET @bFamFound = 1

		SELECT TOP 1 
		  @iFamIndex = id
		FROM #FamMerc
		WHERE name = @FAMIGLIA1_PREFIX + '-' + @FAMIGLIA2_PREFIX + '-' + @FAMIGLIA3_PREFIX

		IF @@ROWCOUNT = 0
		BEGIN

  		  SELECT TOP 1 
		    @iFamIndex = id
		  FROM #FamMerc
		  WHERE name = @FAMIGLIA1_PREFIX + '-' + @FAMIGLIA2_PREFIX

	      IF @@ROWCOUNT = 0
		  BEGIN

    		SELECT TOP 1 
		      @iFamIndex = id
		    FROM #FamMerc
		    WHERE name = @FAMIGLIA1_PREFIX

			IF @@ROWCOUNT = 0 
			  SET @bFamFound = 0


	      END
		    

		END

		IF @bFamFound = 1
		BEGIN
		  
		  SET @UMCodPrincipale = ''


		  SELECT TOP 1 @UMCod = name 
	      FROM #UMMaga
		  WHERE id = @iFamIndex

		  IF @@ROWCOUNT = 1 AND ISNULL(@UMCod, '') <> ''
		  BEGIN

		    SET @UMCodPrincipale = @UMCod

			IF NOT EXISTS (SELECT 1 FROM ARARMisura
		                   WHERE Cd_AR = @DedCodInput
					         AND Cd_ARMisura = @UMCod)

		    BEGIN

			    UPDATE ARARMisura
				  SET DefaultMisura = 0
				WHERE Cd_AR = @DedCodInput
				  AND DefaultMisura = 1

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
	            , @UMCod           -- Cd_ARMisura
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
			ELSE
			BEGIN

			  UPDATE ARARMisura
				SET DefaultMisura = 0
		      WHERE Cd_AR = @DedCodInput
			    AND Cd_ARMisura <> @UMCod
				AND DefaultMisura = 1

			  UPDATE ARARMisura
			  SET TipoARMisura = ''
			    , UMFatt = 1.0
				, DefaultMisura = 1			  
			  WHERE Cd_AR = @DedCodInput
			        AND Cd_ARMisura = @UMCod

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
		  ELSE
	      BEGIN

			SET @Severity = 16

			SET @XErrore = 'Unità di misura di magazzino non trovata per item con codice: ' + @DedCodInput

			IF @Transaction = 1
				GOTO labelExit
			ELSE
				GOTO labelExit2

		  END
							  
		  SELECT TOP 1 
			@UMCod = name 
          , @UMEntity = entity
	      FROM #UMAcq
		  WHERE id = @iFamIndex

	      IF @@ROWCOUNT = 1 AND ISNULL(@UMCod, '') <> '' AND ISNULL(@UMEntity, '') <> ''
		  BEGIN

			IF ISNULL(@UMCod, '') <> @UMCodPrincipale
			BEGIN

			  SET @FattoreConversione = 0

			  IF @UMEntity = 'QTA'
				SET @FattoreConversione = 1
			  ELSE
			  BEGIN

				  IF UPPER(@UMEntity) = 'LG'
			      BEGIN

					IF @LgNumero IS NOT NULL
					BEGIN
					  SET @FattoreConversione = @LgNumero

					  /* Il fattore di conversione in questo punto è in MT per Linear
				           Converto con l'unità di misura espressa in famiglia merceologica */

				      SELECT TOP 1 
  	                    @FattoreUMLinearUmAcq = conv
					  FROM #UMConv
					  WHERE um1 = @UMArcaLinear
					    AND um2 = @UMCod

				      IF @@ROWCOUNT = 0
				      BEGIN

					     SELECT TOP 1 
  						   @FattoreUMLinearUmAcq = (1 / conv)
				         FROM #UMConv
			             WHERE um1 = @UmCod
					     AND um2 = @UMArcaLinear

						 IF @@ROWCOUNT = 0
					     BEGIN


						    SET @Severity = 16
						    SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UmCod + ' e ' + @UMArcaLinear + ' non trovato'

						    IF @Transaction = 1
						      GOTO labelExit
						    ELSE
						      GOTO labelExit2

					     END

					  END

				          	   

				      SET  @FattoreConversione = @FattoreConversione * @FattoreUMLinearUmAcq

					END
					ELSE
					BEGIN


				      SET @Severity = 16

		              SET @XErrore = 'Lunghezza nulla per item con codice: ' + @DedCodFiglio
 
	                  IF @Transaction = 1
	                    GOTO labelExit
	                  ELSE
	                    GOTO labelExit2


					END
			      END
				  

				  IF UPPER(@UMEntity) = 'PESO'
				  BEGIN

					IF @PesoNetto IS NOT NULL
					BEGIN

					  SET @FattoreConversione = @PesoNetto


				      SELECT TOP 1 
  	                    @FattoreUMMassUmAcq = conv
					  FROM #UMConv
					  WHERE um1 = @UMArcaMass
					    AND um2 = @UMCod

				      IF @@ROWCOUNT = 0
				      BEGIN

					     SELECT TOP 1 
  						   @FattoreUMMassUmAcq = (1 / conv)
				         FROM #UMConv
			             WHERE um1 = @UmCod
					     AND um2 = @UMArcaMass

						 IF @@ROWCOUNT = 0
					     BEGIN


						    SET @Severity = 16
						    SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UmCod + ' e ' + @UMArcaMass + ' non trovato'

						    IF @Transaction = 1
						      GOTO labelExit
						    ELSE
						      GOTO labelExit2

					     END

					  END

				          	   

				      SET  @FattoreConversione = @FattoreConversione * @FattoreUMMassUmAcq



					END
					ELSE
					BEGIN


				      SET @Severity = 16

		              SET @XErrore = 'Peso netto nullo per item con codice: ' + @DedCodFiglio
 
	                  IF @Transaction = 1
	                    GOTO labelExit
	                  ELSE
	                    GOTO labelExit2


					END
					

				  END

				  IF UPPER(@UMEntity) = 'SUP_GOMMATA'
				  BEGIN

					IF @SuperficieGommata IS NOT NULL
					BEGIN
					  SET @FattoreConversione = @SuperficieGommata

				      SELECT TOP 1 
  	                    @FattoreUMLinearUmAcq = conv
					  FROM #UMConv
					  WHERE um1 = @UMArcaLinear
					    AND um2 = @UMCod

				      IF @@ROWCOUNT = 0
				      BEGIN

					     SELECT TOP 1 
  						   @FattoreUMLinearUmAcq = (1 / conv)
				         FROM #UMConv
			             WHERE um1 = @UmCod
					     AND um2 = @UMArcaLinear

						 IF @@ROWCOUNT = 0
					     BEGIN


						    SET @Severity = 16
						    SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UmCod + ' e ' + @UMArcaLinear + ' non trovato'

						    IF @Transaction = 1
						      GOTO labelExit
						    ELSE
						      GOTO labelExit2

					     END

					  END

				          	   

				      SET  @FattoreConversione = @FattoreConversione * @FattoreUMLinearUmAcq * @FattoreUMLinearUmAcq



					END
					ELSE
					BEGIN


				      SET @Severity = 16

		              SET @XErrore = 'Superficie Gommata nulla per item con codice: ' + @DedCodFiglio
 
	                  IF @Transaction = 1
	                    GOTO labelExit
	                  ELSE
	                    GOTO labelExit2

					END

			      END							
			    
		      END
			  IF ISNULL(@FattoreConversione, 0) <> 0
			  BEGIN

				IF NOT EXISTS (SELECT 1 FROM ARARMisura
		                       WHERE Cd_AR = @DedCodInput
					             AND Cd_ARMisura = @UMCod)
				BEGIN 

			        UPDATE ARARMisura
				      SET TipoARMisura = ''
  				    WHERE Cd_AR = @DedCodInput
				      AND TipoARMisura = 'A'
					 
				  
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
	                 , @UMCod             -- Cd_ARMisura
	                 , 'A'
                     , (1.0 / @FattoreConversione)
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
				      SET TipoARMisura = ''
  				    WHERE Cd_AR = @DedCodInput
				      AND TipoARMisura = 'A'
					  AND Cd_ARMisura <> @UMCod

                    --print 'FattoreConversione'
					--print @DedCodInput
					--print @FattoreConversione

				    UPDATE ARARMisura
			        SET UMFatt = (1.0 / @FattoreConversione)
			        /* 25/06/2015 by guic: Begin */
			          , TipoARMisura = 'A'
			        /* 25/06/2015 by guic: End */
			        WHERE Cd_AR = @DedCodInput
			          AND Cd_ARMisura = @UMCod

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
			ELSE
			BEGIN

			  UPDATE ARARMisura
		        SET TipoARMisura = ''
  		      WHERE Cd_AR = @DedCodInput
			    AND TipoARMisura = 'A'

			END


		  END
		  ELSE
		  BEGIN

		     SET @Severity = 16

			 SET @XErrore = 'Unità di misura di acquisto non trovata per item con codice: ' + @DedCodInput

		     IF @Transaction = 1
			   GOTO labelExit
			 ELSE
			   GOTO labelExit2

 
		  END

		  
        END
		ELSE
		BEGIN

		  SET @Severity = 16

		  SET @XErrore = 'Famiglia merceologica non trovata per item con codice: ' + @DedCodInput

	      IF @Transaction = 1
	        GOTO labelExit
	      ELSE
	        GOTO labelExit2


		END
		
	  END     	

	  IF @Azione <> 'D'
	  BEGIN
	  

	      SET @CheckDIBA = 0


	      IF NOT EXISTS (SELECT 1 FROM DB WHERE Cd_AR = @DedCodInput)
	      BEGIN
		  
       
	        IF EXISTS(SELECT 1 FROM [PDMDATABASE].[ICM_Custom].[dbo].[XPORT_DIST] WHERE DEDIDP = @DEDID
		                                                      AND DEDREVP = @DEDREV
				  											  AND ISNULL(DEDIDC, '') <> '')													
														      

                                                         

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
			  

		        EXEC @Severity = xSOLIDCheckDIBASp @DEDID = @DEDID
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
	      SELECT DISTINCT
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
			, @UMDist

		    IF @@FETCH_STATUS <> 0
		      BREAK

		    --IF @Q <= 0
		    --BEGIN

		      --print 'Errore qta 0 '
			  --print 'Articolo padre ' + @DEDIDP
			  --print 'Articolo figlio ' + @DEDIDC

		    --END

          
		    SET @DedCodFiglio = NULL

		    IF @UltRev = 1
   	        BEGIN

		      SELECT TOP 1 @DedCodFiglio = DED_COD -- + '_' + DEDREV
			             , @DedCodFiglioCatMerc = FAMIGLIA1_PREFIX
				  	     , @DedCodFiglioDescrizione = DescCommercialeITA --DEDDESC
					     , @DedCodFiglioNotadiTaglio = NOTA_DI_TAGLIO
			             FROM [PDMDATABASE].[ICM_Custom].[dbo].[XPORT_ANAG]			              
		                 WHERE DEDID = @DEDIDC
						 AND ISNULL(DEDREVDATE, @DistDate - 1) < @DistDate
					       --AND DEDREV = @DEDREVC	
					     ORDER BY CAST(DEDREV AS Int) DESC
	        END
		    ELSE
		    BEGIN 

		      SELECT TOP 1 @DedCodFiglio = DED_COD -- + '_' + DEDREV
			             , @DedCodFiglioCatMerc = FAMIGLIA1_PREFIX
				  	     , @DedCodFiglioDescrizione = DescCommercialeITA --DEDDESC
					     , @DedCodFiglioNotadiTaglio = NOTA_DI_TAGLIO
			             FROM [PDMDATABASE].[ICM_Custom].[dbo].[XPORT_ANAG]			              
		                 WHERE DEDID = @DEDIDC
					       AND DEDREV = @DEDREVC	
					       ORDER BY DEDREV DESC
		    END				 

  		    IF LTRIM(RTRIM(ISNULL(@DedCodFiglio,''))) = ''
		      CONTINUE

			/* guic: togliere ?*/
		    /*IF LEN(@DedCodFiglio) = 21
			BEGIN
			  SET @DedCodFiglio = SUBSTRING(@DedCodFiglio, 1, LEN(@DedCodFiglio) - 3) + SUBSTRING(@DedCodFiglio, LEN(@DedCodFiglio) - 1, 2)

			END*/
			/* guic: togliere ?*/

	        --print @DedDis + ' ### ' + @F

		    SET @NewLivello = @Livello + 1
		  
		    SET @XWarningTemp = NULL

		    EXEC @Severity = xSOLIDCreaArticoloSp 
		                       @DedId = @DEDIDC
				   	         , @DedRev = @DEDREVC
	   		      	         , @Transaction = 0
			     	         , @Azione = @Azione						   
						     , @CodPadre = @DedCodInput 
						     , @XErrore = @XErrore OUTPUT
							 , @XWarning = @XWarningTemp OUTPUT
						     , @DistDate = @DistDate
                             , @UltRev = @UltRev						   
						     , @DedIdPadre = @DedIdPadre
						     , @Livello = @NewLivello
							 , @First = 0

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
		    
			  IF @XWarningTemp IS NOT NULL
			  BEGIN

			    --IF LEN(ISNULL(@XWarning, '')) + LEN(ISNULL(@XWarningTemp, '')) < 2950
				--BEGIN

				  IF @XWarning IS NULL
					SET @XWarning = @XWarningTemp
				  ELSE
				    SET @XWarning = @XWarning + CHAR(1) + @XWarningTemp

				--END


			  END
			
			  SET @DedCodFiglio = upper(@DedCodFiglio)


			  /* Cerca la famiglia merceologica per il figlio */
			  
			  SELECT TOP 1 
			    @FIGLIOFAMIGLIA1_PREFIX = AR.Cd_ARGruppo1
	          , @FIGLIOFAMIGLIA2_PREFIX = AR.Cd_ARGruppo2
	          , @FIGLIOFAMIGLIA3_PREFIX = AR.Cd_ARGruppo3
			  FROM AR WHERE AR.Cd_AR = @DedCodFiglio

			  IF @@ROWCOUNT <> 1
			  BEGIN

			  	SET @Severity = 16

		        SET @XErrore = 'Articolo (figlio) non trovato con codice: ' + @DedCodFiglio

	            IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2


			  END
			  


			  /* Cerca l'unità di misura di magazzino per il figlio */
			  SELECT TOP 1 
			    @UMMateriale = ARARMisura.Cd_ARMisura

			  FROM ARARMisura 
			  WHERE ARARMisura.Cd_AR = @DedCodFiglio
			    AND ARARMisura.DefaultMisura = 1

			  IF @@ROWCOUNT <> 1
			  BEGIN

			  	SET @Severity = 16

		        SET @XErrore = 'Unità di misura di default non trovata per item con codice: ' + @DedCodFiglio

	            IF @Transaction = 1
	              GOTO labelExit
	            ELSE
	              GOTO labelExit2


			  END

			  IF ISNULL(@UMMateriale, '') = '' OR
			     ISNULL(@UMDist, '') = ''
				 OR @UMMateriale <> @UMDist
			     				
			 BEGIN

		          SET @Severity = 16

		          SET @XErrore = 'Unità di misura di magazzino non trovata o incoerente per item con codice: ' + @DedCodFiglio
 
	              IF @Transaction = 1
	                GOTO labelExit
	              ELSE
	                GOTO labelExit2


		      END


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

		        --print '@DedCodFiglio start'
			    --print @DedCodFiglio
		        --print @F
			    --print '@DedCodFiglio end'


			 			  
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
	               , @Q   --@Q
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
	    --print 'Rollback'
		--print @DEDID
	    ROLLBACK TRANSACTION
	  END

	  

	  SET @Ciclo = 0

	  IF @First = 1
      BEGIN

        IF OBJECT_ID('tempdb..#ICM_Cache_SOLID') IS NOT NULL
          DROP TABLE #ICM_Cache_SOLID

		IF OBJECT_ID('tempdb..#ICM_Data_Art') IS NOT NULL
          DROP TABLE #ICM_Data_Art

		if OBJECT_ID('tempdb..#UMLinear') IS NOT NULL
	      DROP TABLE #UMLinear


        if OBJECT_ID('tempdb..#UMMass') IS NOT NULL
	      DROP TABLE #UMMass

        if OBJECT_ID('tempdb..#UMConv') IS NOT NULL
	      DROP TABLE #UMConv

        if OBJECT_ID('tempdb..#FamMerc') IS NOT NULL
          DROP TABLE #FamMerc


        if OBJECT_ID('tempdb..#UMMaga') IS NOT NULL
          DROP TABLE #UMMaga
	
	
        if OBJECT_ID('tempdb..#UMAcq') IS NOT NULL
          DROP TABLE #UMAcq
	




      END

	  RETURN @Severity
    END
	

	labelExit2:
	IF @First = 1
    BEGIN

      IF OBJECT_ID('tempdb..#ICM_Cache_SOLID') IS NOT NULL
        DROP TABLE #ICM_Cache_SOLID

	  IF OBJECT_ID('tempdb..#ICM_Data_Art') IS NOT NULL
        DROP TABLE #ICM_Data_Art

      if OBJECT_ID('tempdb..#UMLinear') IS NOT NULL
	      DROP TABLE #UMLinear


      if OBJECT_ID('tempdb..#UMMass') IS NOT NULL
	      DROP TABLE #UMMass

      if OBJECT_ID('tempdb..#UMConv') IS NOT NULL
	      DROP TABLE #UMConv

      if OBJECT_ID('tempdb..#FamMerc') IS NOT NULL
          DROP TABLE #FamMerc


      if OBJECT_ID('tempdb..#UMMaga') IS NOT NULL
          DROP TABLE #UMMaga
	
	
      if OBJECT_ID('tempdb..#UMAcq') IS NOT NULL
          DROP TABLE #UMAcq



    END

	RETURN @Severity

	

END	

