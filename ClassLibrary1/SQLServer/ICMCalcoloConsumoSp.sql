/****** Object:  StoredProcedure [dbo].[ICMCalcoloConsumoSp]    Script Date: 2/16/2023 3:38:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[ICMCalcoloConsumoSp]
  @SessionID uniqueIdentifier
, @XErrore nvarchar(200) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @Severity int

	SET @Severity = 0


	DECLARE 
	  @DEDIDP nvarchar(50)
	, @DEDREVP nvarchar(50)
	, @DEDIDC nvarchar(50)
	, @DEDREVC nvarchar(50)
	, @SWANAGP_DEDID nvarchar(50)	
	, @SWANAGP_DEDREV nvarchar(50)	
	, @QTA decimal(23,11) 
	, @CONSUMO decimal(23,11)
	, @UM nvarchar(50)
	, @FAMIGLIA1_PREFIX nvarchar(200)
	, @FAMIGLIA2_PREFIX nvarchar(200)
	, @FAMIGLIA3_PREFIX nvarchar(200)
	, @SWANAGP_FAMIGLIA1_PREFIX nvarchar(200)
	, @SWANAGP_FAMIGLIA2_PREFIX nvarchar(200)
	, @SWANAGP_FAMIGLIA3_PREFIX nvarchar(200)
	, @SWANAGP_DEDLinear varchar(200)
	, @SWANAGP_DEDMass varchar(200)
	, @LG nvarchar(200)
	, @SUP_GOMMATA nvarchar(200)
	, @PESO nvarchar(200)
	, @SWANAGP_LG nvarchar(200)
	, @SWANAGP_SUP_GOMMATA nvarchar(200)
	, @SWANAGP_PESO nvarchar(200)
	, @iCount int
	, @NEWLG nvarchar(200)
	, @NEWSUP_GOMMATA nvarchar(200)
	, @NEWPESO nvarchar(200)
	, @PesoNetto decimal(23,11)
	, @SWANAGP_PESONetto decimal(23,11)
	, @SuperficieGommata decimal(23,11)
	, @FattoreConversione decimal(23,11)
	, @FattoreConversioneAcq decimal(23,11)
	, @FatConv2 decimal(23,11)
	, @LgNumero decimal(23,11)
	, @SWANAGP_LGNumero decimal(23,11)
	, @DEDLinear varchar(200)
	, @DEDMass varchar(200)
	, @DEDLinearInt int
	, @DEDMassInt int
	, @UMSolidWorksLinear varchar(50)
	, @UMSolidWorksMass varchar(50)
	, @iFamIndex int
	, @bFamFound smallint
	, @id int
	, @SWANAG_UMMaga nvarchar(10)
	, @SWANAG_MagaFatConv decimal(23,11)
	, @SWANAG_UMAcq nvarchar(10)
	, @SWANAG_AcqFatConv decimal(23,11)
	, @SWANAG_DEDID nvarchar(50)
	, @SWANAG_DEDREV nvarchar(50)
	, @SWANAGP_DEDLinearInt int
	, @SWANAGP_DEDMassInt int
	, @UMMaga nvarchar(200)
	, @EntityMaga nvarchar(200)
	, @UMAcq nvarchar(200)
	, @EntityAcq nvarchar(200)
    , @UMArcaLinear varchar(50)
	, @UMArcaMass varchar(50)
	, @FattoreUMLinear decimal(23,11)
	, @FattoreUMMass decimal(23,11)

	/* Assumo come unità di misura di riferimento ARCA 
	           Linear = 'MT'
			   Peso = 'KG'
	   Dimensioni e pesi vengono dapprima converiti in queste unità di misura
	   Poi vengono convertiti nell'unità di misura usata in anagrafica articolo 
	   per dati sull'anagrafica articolo (solo in UPDATE)
	*/

	SET @UMArcaLinear = 'MT'
	SET @UMArcaMass = 'KG'

	
	--print 'prima	


    DECLARE SWANAG CURSOR LOCAL STATIC FOR
	  SELECT 
	  SWANAG.DEDID
	, SWANAG.DEDREV
	, SWANAG.FAMIGLIA1_PREFIX
	, SWANAG.FAMIGLIA2_PREFIX 
	, SWANAG.FAMIGLIA3_PREFIX
	, SWANAG.DEDLINEAR
	, SWANAG.DEDMASS
	, SWANAG.LG
	, SWANAG.SUP_GOMMATA
	, SWANAG.PESO

	FROM SWANAG
	WHERE SessionID = @SessionID
	
	OPEN SWANAG

	WHILE (@Severity = 0)
	BEGIN


	  FETCH SWANAG INTO
   	    @SWANAGP_DEDID
	  , @SWANAGP_DEDREV
	  , @SWANAGP_FAMIGLIA1_PREFIX
	  , @SWANAGP_FAMIGLIA2_PREFIX 
	  , @SWANAGP_FAMIGLIA3_PREFIX
   	  , @SWANAGP_DEDLinear
   	  , @SWANAGP_DEDMass
  	  , @SWANAGP_LG
	  , @SWANAGP_SUP_GOMMATA
	  , @SWANAGP_PESO


	  IF @@FETCH_STATUS <> 0
	    BREAK




      /* Calcolo dati per magazzino/acquisto */

      SET @FattoreConversione = 1
	  SET @FattoreConversioneAcq = 1


	  /* ricavo unità di misura di Solidworks */
	  
	  IF @SWANAGP_DEDLinear IS NOT NULL AND ISNUMERIC(@SWANAGP_DEDLinear) = 1 AND ROUND(@SWANAGP_DEDLinear,0,1) = @SWANAGP_DEDLinear
	  BEGIN

	    SET @SWANAGP_DEDLinearInt = CAST(@SWANAGP_DEDLinear AS INT)

	  END
	  ELSE
	  BEGIN

	    SET @Severity = 16
		SET @XErrore = 'Unità di misura per lunghezza espressa in SolidWorks non riconosciuta'


	    GOTO labelExit


	  END

	  SELECT TOP 1 
	    @UMSolidWorksLinear = um
	  FROM ICM_UMLinear
	  WHERE id = @SWANAGP_DEDLinearInt

	  IF @@ROWCOUNT = 0 OR ISNULL(@UMSolidWorksLinear, '') = ''
	  BEGIN


	    SET @Severity = 16
	    SET @XErrore = 'Unità di misura per lunghezza espressa in SolidWorks non riconosciuta'

	    GOTO labelExit


	  END


	  IF @SWANAGP_DEDMass IS NOT NULL AND ISNUMERIC(@SWANAGP_DEDMass) = 1 AND ROUND(@SWANAGP_DEDMass,0,1) = @SWANAGP_DEDMass
	  BEGIN

	    SET @SWANAGP_DEDMassInt = CAST(@SWANAGP_DEDMass AS INT)

	  END
	  ELSE
	  BEGIN

	    SET @Severity = 16
		SET @XErrore = 'Unità di misura per peso espressa in SolidWorks non riconosciuta'

	    GOTO labelExit


	  END

	  SELECT TOP 1 
	    @UMSolidWorksMass = um
	  FROM ICM_UMMass
	  WHERE id = @SWANAGP_DEDMassInt

	  IF @@ROWCOUNT = 0 OR ISNULL(@UMSolidWorksMass, '') = ''
	  BEGIN

	    SET @Severity = 16
	    SET @XErrore = 'Unità di misura per peso espressa in SolidWorks non riconosciuta'


	    GOTO labelExit


	  END

	  /* Calcolo fattori di conversione tra UM SolidWorks e UM Arca */

	  /* Calcolo fattore di conversione tra le unità di misura di SolidWorks e di Arca*/	

	  IF @UMArcaLinear <> @UMSolidWorksLinear
	  BEGIN

	    SELECT TOP 1 
	      @FattoreUMLinear = conv
	    FROM ICM_UMConv
	    WHERE um1 = @UMSolidWorksLinear
	      AND um2 = @UMArcaLinear

	    IF @@ROWCOUNT = 0
	    BEGIN

	      SELECT TOP 1 
  	        @FattoreUMLinear = (1 / conv)
	      FROM ICM_UMConv
	      WHERE um1 = @UMArcaLinear
	        AND um2 = @UMSolidWorksLinear

		  IF @@ROWCOUNT = 0
		  BEGIN


	        SET @Severity = 16
	        SET @XErrore = 'Fattore di conversione tra unità di misura metriche di SolidWorks e ARCA non trovato'
	       
	        GOTO labelExit
	      

		  END
	   
	    END

	  END

	  ELSE
	    SET @FattoreUMLinear = 1
	
	  IF @UMArcaMass <> @UMSolidWorksMass
	  BEGIN

	    SELECT TOP 1 
	      @FattoreUMMass = conv
	    FROM ICM_UMConv
	    WHERE um1 = @UMSolidWorksMass
  	      AND um2 = @UMArcaMass

	    IF @@ROWCOUNT = 0
	    BEGIN

	      SELECT TOP 1 
  	        @FattoreUMMass = (1 / conv)
	      FROM ICM_UMConv
	      WHERE um1 = @UMArcaMass
	        AND um2 = @UMSolidWorksMass

		  IF @@ROWCOUNT = 0
		  BEGIN


	        SET @Severity = 16
	        SET @XErrore = 'Fattore di conversione tra unità di misura di peso di SolidWorks e ARCA non trovato'
	        
	        GOTO labelExit

		  END
	    

	    END

	  END

	  ELSE
	    SET @FattoreUMMass = 1





	  
	  SET @NEWPESO = ''
	  SET @iCount = 1

	  WHILE (@iCount <= len(@SWANAGP_PESO))
	  BEGIN
		 
		  IF SUBSTRING(@SWANAGP_PESO, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			  SET @NEWPESO = @NEWPESO + SUBSTRING(@SWANAGP_PESO, @iCount, 1)

		  SET @iCount = @iCount + 1

	  END

	  SET @SWANAGP_PESO = @NEWPESO

	  --print 'pippo2'

	  -- Superficie Gommata

	  SET @NEWSUP_GOMMATA = ''

	  SET @iCount = 1

	  WHILE (@iCount <= len(@SWANAGP_SUP_GOMMATA))
	  BEGIN


		  IF SUBSTRING(@SWANAGP_SUP_GOMMATA, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
	        SET @NEWSUP_GOMMATA = @NEWSUP_GOMMATA + SUBSTRING(@SWANAGP_SUP_GOMMATA, @iCount, 1)

		  SET @iCount = @iCount + 1

	  END

	  SET @SWANAGP_SUP_GOMMATA = @NEWSUP_GOMMATA

	  --print 'pippo3'

	  -- LG

	  SET @NEWLG = ''

	  SET @iCount = 1

	  WHILE (@iCount <= len(@SWANAGP_LG))
	  BEGIN


		  IF SUBSTRING(@SWANAGP_LG, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			  SET @NEWLG = @NEWLG + SUBSTRING(@SWANAGP_LG, @iCount, 1)

		  SET @iCount = @iCount + 1

	  END

	  SET @SWANAGP_LG = @NEWLG


	  SET @SWANAGP_PESONetto = NULL

	  IF @SWANAGP_PESO IS NULL
		SET @SWANAGP_PESONetto = 0
	  ELSE
	    IF ISNUMERIC(@SWANAGP_PESO) = 1
  		  SET @SWANAGP_PESONetto =  (CAST(REPLACE(@SWANAGP_PESO, ',' , '.') AS decimal(23,11)))
		ELSE
		  SET @SWANAGP_PESONetto = 0

      --print 'pippo52'
      SET @SuperficieGommata = NULL

	  IF @SWANAGP_SUP_GOMMATA IS NULL
		SET @SuperficieGommata = 0
	  ELSE
	    IF ISNUMERIC(@SWANAGP_SUP_GOMMATA) = 1
		  SET @SuperficieGommata = (CAST(REPLACE(@SWANAGP_SUP_GOMMATA, ',' , '.') AS decimal(23,11)))
		ELSE
		  SET @SuperficieGommata = 0

      SET @SWANAGP_LGNumero = NULL

	  --print 'pippo53'

	  IF @SWANAGP_LG IS NULL
		 SET @SWANAGP_LGNumero = 0
	  ELSE
	    IF ISNUMERIC(@SWANAGP_LG) = 1
		  SET @SWANAGP_LGNumero = (CAST(REPLACE(@SWANAGP_LG, ',' , '.') AS decimal(23,11)))
		ELSE
		 SET @SWANAGP_LGNumero = 0
	  
	  /* Recupero unità di misura e entità */
	  SET @iFamIndex = 0
      SET @bFamFound = 1

      SELECT TOP 1 
		@iFamIndex = id
	  , @UMMaga = ummaga
	  , @EntityMaga = entitymaga
	  , @UMAcq = umacq
	  , @EntityAcq = entityacq
      FROM ICM_FamMerc
	  WHERE name = @SWANAGP_FAMIGLIA1_PREFIX + '-' + @SWANAGP_FAMIGLIA2_PREFIX + '-' + @SWANAGP_FAMIGLIA3_PREFIX

      IF @@ROWCOUNT = 0
	  BEGIN

  		SELECT TOP 1 
		  @iFamIndex = id
		, @UMMaga = ummaga
	    , @EntityMaga = entitymaga
	    , @UMAcq = umacq
	    , @EntityAcq = entityacq

		FROM ICM_FamMerc
		WHERE name = @SWANAGP_FAMIGLIA1_PREFIX + '-' + @SWANAGP_FAMIGLIA2_PREFIX

	    IF @@ROWCOUNT = 0
	    BEGIN

    	  SELECT TOP 1 
		    @iFamIndex = id
	      , @UMMaga = ummaga
	      , @EntityMaga = entitymaga
	      , @UMAcq = umacq
	      , @EntityAcq = entityacq
		  FROM ICM_FamMerc
		  WHERE name = @SWANAGP_FAMIGLIA1_PREFIX

	      IF @@ROWCOUNT = 0 
		    SET @bFamFound = 0


	    END
		    

	  END


	  IF @bFamFound = 1
	  BEGIN		    


		IF ISNULL(@UMMaga, '') <> '' AND ISNULL(@EntityMaga, '') <> ''
		BEGIN

		  SET @UM = @UMMaga

		  IF UPPER(@EntityMaga) = 'QTA'
		  BEGIN

		    SET @FattoreConversione = 1
			

          END
		  ELSE
		  BEGIN

		    IF UPPER(@EntityMaga) = 'LG'
		    BEGIN

		      IF @SWANAGP_LGNumero IS NOT NULL
			  BEGIN


			    SELECT TOP 1 
	              @FatConv2 = conv
	            FROM ICM_UMConv
	            WHERE um1 = @UMSolidWorksLinear
	              AND um2 = @UM

        	    IF @@ROWCOUNT = 0
	            BEGIN

	              SELECT TOP 1 
  	                @FatConv2 = (1 / conv)
			      FROM ICM_UMConv
				  WHERE um1 = @UM
	                AND um2 = @UMSolidWorksLinear

		          IF @@ROWCOUNT = 0
		          BEGIN

				  
				    SET @Severity = 16

		            SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UMSolidWorksLinear + ' e ' + @UM + ' non trovato'
 
	            
	                GOTO labelExit				
				
				  END


				END

			    SET @FattoreConversione = @SWANAGP_LGNumero * @FatConv2


			  END
			  ELSE
		      BEGIN


			    SET @Severity = 16

		        SET @XErrore = 'Lunghezza nulla per componente con codice: ' + @SWANAGP_DEDID + '/' + @SWANAGP_DEDREV
 	            GOTO labelExit


			  END
			END
				  

			IF UPPER(@EntityMaga) = 'PESO'
		    BEGIN

		      IF @SWANAGP_PESONetto IS NOT NULL
			  BEGIN

			  	SELECT TOP 1 
  	              @FatConv2 = conv
	            FROM ICM_UMConv
	            WHERE um1 = @UMSolidWorksMass
	              AND um2 = @UM

        	    IF @@ROWCOUNT = 0
	            BEGIN

	              SELECT TOP 1 
  	                @FatConv2 = (1 / conv)
			      FROM ICM_UMConv
				  WHERE um1 = @UM
	                AND um2 = @UMSolidWorksMass

		          IF @@ROWCOUNT = 0
		          BEGIN

				  
				    SET @Severity = 16

		            SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UMSolidWorksMass + ' e ' + @UM + ' non trovato'
 
	            
	                GOTO labelExit				
				
				  END


				END

			    SET @FattoreConversione = @SWANAGP_PESONetto * @FatConv2
				
			  END
		      ELSE
			  BEGIN


				SET @Severity = 16

		        SET @XErrore = 'Peso netto nullo per componente con codice: ' + @SWANAGP_DEDID + '/' + @SWANAGP_DEDREV
 
	            
	            GOTO labelExit
	            

			  END
					

			END

			IF UPPER(@EntityMaga) = 'SUP_GOMMATA'
			BEGIN

		      IF @SuperficieGommata IS NOT NULL
			  BEGIN

			    SELECT TOP 1 
	              @FatConv2 = conv
	            FROM ICM_UMConv
	            WHERE um1 = @UMSolidWorksLinear
	              AND um2 = @UM

        	    IF @@ROWCOUNT = 0
	            BEGIN

	              SELECT TOP 1 
  	                @FatConv2 = (1 / conv)
			      FROM ICM_UMConv
				  WHERE um1 = @UM
	                AND um2 = @UMSolidWorksLinear

		          IF @@ROWCOUNT = 0
		          BEGIN

				  
				    SET @Severity = 16

		            SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UMSolidWorksLinear + ' e ' + @UM + ' non trovato'
 
	            
	                GOTO labelExit				
				
				  END


			    END

			    SET @FattoreConversione = @SuperficieGommata * @FatConv2 * @FatConv2

				
			  END
			  ELSE
			  BEGIN

				SET @Severity = 16

		        SET @XErrore = 'Superficie Gommata nulla per componente con codice: ' + @SWANAGP_DEDID + '/' + @SWANAGP_DEDREV
 
	                    
	            GOTO labelExit


		      END
			END
		  END
		END
		ELSE
		BEGIN
		  

		  SET @Severity = 16

		  SET @XErrore = 'Unità di misura di magazzino non trovata per componente con codice: ' + @SWANAGP_DEDID + '/' + @SWANAGP_DEDREV

		  GOTO labelExit

		END

	    IF @@ROWCOUNT = 1 AND ISNULL(@UMAcq, '') <> '' AND ISNULL(@EntityAcq, '') <> ''
		BEGIN

		  SET @UM = @UMAcq

		  IF UPPER(@EntityAcq) = 'QTA'
		  BEGIN

		    SET @FattoreConversioneAcq = 1
			

          END
		  ELSE
		  BEGIN

		    IF UPPER(@EntityAcq) = 'LG'
		    BEGIN

		      IF @SWANAGP_LGNumero IS NOT NULL
			  BEGIN


			    SELECT TOP 1 
	              @FatConv2 = conv
	            FROM ICM_UMConv
	            WHERE um1 = @UMSolidWorksLinear
	              AND um2 = @UM

        	    IF @@ROWCOUNT = 0
	            BEGIN

	              SELECT TOP 1 
  	                @FatConv2 = (1 / conv)
			      FROM ICM_UMConv
				  WHERE um1 = @UM
	                AND um2 = @UMSolidWorksLinear

		          IF @@ROWCOUNT = 0
		          BEGIN

				  
				    SET @Severity = 16

		            SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UMSolidWorksLinear + ' e ' + @UM + ' non trovato'
 
	            
	                GOTO labelExit				
				
				  END


				END

			    SET @FattoreConversioneAcq = @SWANAGP_LGNumero * @FatConv2


			  END
			  ELSE
		      BEGIN


			    SET @Severity = 16

		        SET @XErrore = 'Lunghezza nulla per componente con codice: ' + @SWANAGP_DEDID + '/' + @SWANAGP_DEDREV
 	            GOTO labelExit


			  END
			END
				  

			IF UPPER(@EntityAcq) = 'PESO'
		    BEGIN

		      IF @SWANAGP_PESONetto IS NOT NULL
			  BEGIN

			  	SELECT TOP 1 
  	              @FatConv2 = conv
	            FROM ICM_UMConv
	            WHERE um1 = @UMSolidWorksMass
	              AND um2 = @UM

        	    IF @@ROWCOUNT = 0
	            BEGIN

	              SELECT TOP 1 
  	                @FatConv2 = (1 / conv)
			      FROM ICM_UMConv
				  WHERE um1 = @UM
	                AND um2 = @UMSolidWorksMass

		          IF @@ROWCOUNT = 0
		          BEGIN

				  
				    SET @Severity = 16

		            SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UMSolidWorksMass + ' e ' + @UM + ' non trovato'
 
	            
	                GOTO labelExit				
				
				  END


				END

			    SET @FattoreConversioneAcq = @SWANAGP_PESONetto * @FatConv2
				
			  END
		      ELSE
			  BEGIN


				SET @Severity = 16

		        SET @XErrore = 'Peso netto nullo per componente con codice: ' + @SWANAGP_DEDID + '/' + @SWANAGP_DEDREV
 
	            
	            GOTO labelExit
	            

			  END
					

			END

			IF UPPER(@EntityAcq) = 'SUP_GOMMATA'
			BEGIN

		      IF @SuperficieGommata IS NOT NULL
			  BEGIN

			    SELECT TOP 1 
	              @FatConv2 = conv
	            FROM ICM_UMConv
	            WHERE um1 = @UMSolidWorksLinear
	              AND um2 = @UM

        	    IF @@ROWCOUNT = 0
	            BEGIN

	              SELECT TOP 1 
  	                @FatConv2 = (1 / conv)
			      FROM ICM_UMConv
				  WHERE um1 = @UM
	                AND um2 = @UMSolidWorksLinear

		          IF @@ROWCOUNT = 0
		          BEGIN

				  
				    SET @Severity = 16

		            SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UMSolidWorksLinear + ' e ' + @UM + ' non trovato'
 
	            
	                GOTO labelExit				
				
				  END


			    END

			    SET @FattoreConversioneAcq = @SuperficieGommata * @FatConv2 * @FatConv2

				
			  END
			  ELSE
			  BEGIN

				SET @Severity = 16

		        SET @XErrore = 'Superficie Gommata nulla per articolo con codice: ' + @SWANAGP_DEDID + '/' + @SWANAGP_DEDREV
 
	                    
	            GOTO labelExit


		      END
			END
		  END
		END
		ELSE
		BEGIN

		  SET @Severity = 16

		  SET @XErrore = 'Unità di misura di acquisto non trovata per articolo con codice: ' + @SWANAGP_DEDID + '/' + @SWANAGP_DEDREV

		  GOTO labelExit

		END


	  END
	  ELSE
	  BEGIN

	     SET @Severity = 16

		 SET @XErrore = 'Famiglia merceologica non trovata per articolo con codice: ' + @SWANAGP_DEDID + '/' + @SWANAGP_DEDREV

	     
	     GOTO labelExit

	  END

	  UPDATE SWANAG
	  SET UMMaga = @UMMaga
	    , MagaFatConv = @FattoreConversione
	    , UMAcq = @UMAcq
	    , AcqFatConv = @FattoreConversioneAcq
		, FattoreUMLinear = @FattoreUMLinear
		, FattoreUMMass = @FattoreUMMass
	  WHERE SessionID = @SessionID
	    AND DEDID = @SWANAGP_DEDID
	    AND DEDREV = @SWANAGP_DEDREV

	  IF @@ERROR <> 0
      BEGIN

		  SET @Severity = 16

		  SET @XErrore = 'Errore aggiornamento Distinta per articolo con codice: ' + @SWANAGP_DEDID + '/' + @SWANAGP_DEDREV

	     
	      GOTO labelExit

	  END


	  DECLARE SWBOM CURSOR LOCAL STATIC FOR
	    SELECT 
	      SWBOM.DEDIDP
	    , SWBOM.DEDREVP
	    , SWBOM.DEDIDC
	    , SWBOM.DEDREVC
	    , SWBOM.QTA
	    , SWANAG.FAMIGLIA1_PREFIX
	    , SWANAG.FAMIGLIA2_PREFIX
	    , SWANAG.FAMIGLIA3_PREFIX
	    , SWANAG.LG
	    , SWANAG.SUP_GOMMATA
	    , SWANAG.PESO
	    , SWANAG.DEDLinear
	    , SWANAG.DEDMass

	  FROM SWBOM
	  INNER JOIN SWANAG ON (SWANAG.SessionID = SWBOM.SessionID AND 
	                        SWANAG.DEDID = SWBOM.DEDIDC AND
							SWANAG.DEDREV = SWBOM.DEDREVC)
	  WHERE SWBOM.SessionID = @SessionID
	    AND SWBOM.DEDIDP = @SWANAGP_DEDID
		AND SWBOM.DEDREVP = @SWANAGP_DEDREV


	  OPEN SWBOM

	  WHILE (@Severity = 0)
	  BEGIN

	    FETCH SWBOM INTO 
	      @DEDIDP
	    , @DEDREVP
	    , @DEDIDC
	    , @DEDREVC
	    , @QTA
  	    , @FAMIGLIA1_PREFIX
	    , @FAMIGLIA2_PREFIX
	    , @FAMIGLIA3_PREFIX
	    , @LG
	    , @SUP_GOMMATA
	    , @PESO
	    , @DEDLinear
	    , @DEDMass


	    IF @@FETCH_STATUS <> 0
	      BREAK


	    --print @DEDIDP
	    --print @DEDREVP

	    --print @DEDIDC
	    --print @DEDREVC

		SET @FattoreConversione = 1

	    /* ricavo unità di misura di Solidworks */
		
	  
	    IF @DEDLinear IS NOT NULL AND ISNUMERIC(@DEDLinear) = 1 AND ROUND(@DEDLinear,0,1) = @DEDLinear
	    BEGIN

	      SET @DEDLinearInt = CAST(@DEDLinear AS INT)

	    END
	    ELSE
	    BEGIN

	      SET @Severity = 16
		  SET @XErrore = 'Unità di misura per lunghezza espressa in SolidWorks non riconosciuta'


	      GOTO labelExit


	    END

	    SELECT TOP 1 
	      @UMSolidWorksLinear = um
	    FROM ICM_UMLinear
	    WHERE id = @DEDLinearInt

	    IF @@ROWCOUNT = 0 OR ISNULL(@UMSolidWorksLinear, '') = ''
	    BEGIN


	      SET @Severity = 16
	      SET @XErrore = 'Unità di misura per lunghezza espressa in SolidWorks non riconosciuta'

	      GOTO labelExit


	    END


	    IF @DEDMass IS NOT NULL AND ISNUMERIC(@DEDMass) = 1 AND ROUND(@DEDMass,0,1) = @DEDMass
	    BEGIN

	      SET @DEDMassInt = CAST(@DEDMass AS INT)

	    END
	    ELSE
	    BEGIN

	      SET @Severity = 16
		  SET @XErrore = 'Unità di misura per peso espressa in SolidWorks non riconosciuta'

	      GOTO labelExit


	    END

	    SELECT TOP 1 
	      @UMSolidWorksMass = um
	    FROM ICM_UMMass
	    WHERE id = @DEDMassInt

	    IF @@ROWCOUNT = 0 OR ISNULL(@UMSolidWorksMass, '') = ''
	    BEGIN

	      SET @Severity = 16
	      SET @XErrore = 'Unità di misura per peso espressa in SolidWorks non riconosciuta'


	      GOTO labelExit


	    END





	    SET @NEWPESO = ''

	    SET @iCount = 1

	    WHILE (@iCount <= len(@PESO))
	    BEGIN

		 
		    IF SUBSTRING(@PESO, @iCount, 1) IN ('0','1','2','3','4','5','6','7','8','9','.',',','^','-')
			    SET @NEWPESO = @NEWPESO + SUBSTRING(@PESO, @iCount, 1)

		    SET @iCount = @iCount + 1

	    END

	    SET @PESO = @NEWPESO

	    --print 'pippo2'

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

	    --print 'pippo3'

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


	    SET @PesoNetto = NULL

	    IF @PESO IS NULL
		  SET @PesoNetto = 0
	    ELSE
	      IF ISNUMERIC(@PESO) = 1
  		    SET @PesoNetto =  (CAST(REPLACE(@PESO, ',' , '.') AS decimal(23,11)))
		  ELSE
		    SET @PesoNetto = 0

        --print 'pippo52'
        SET @SuperficieGommata = NULL

	    IF @SUP_GOMMATA IS NULL
		  SET @SuperficieGommata = 0
	    ELSE
	      IF ISNUMERIC(@SUP_GOMMATA) = 1
		    SET @SuperficieGommata = (CAST(REPLACE(@SUP_GOMMATA, ',' , '.') AS decimal(23,11)))
		  ELSE
		    SET @SuperficieGommata = 0

        SET @LgNumero = NULL

	    --print 'pippo53'

	    IF @LG IS NULL
		  SET @LgNumero = 0
	    ELSE
	      IF ISNUMERIC(@LG) = 1
		    SET @LgNumero = (CAST(REPLACE(@LG, ',' , '.') AS decimal(23,11)))
		  ELSE
		    SET @LgNumero = 0
	  
	    /* Recupero unità di misura e entità */
	    SET @iFamIndex = 0
        SET @bFamFound = 1

        SELECT TOP 1 
		  @iFamIndex = id
		, @UMMaga = ummaga
	    , @EntityMaga = entitymaga
	    , @UMAcq = umacq
	    , @EntityAcq = entityacq

        FROM ICM_FamMerc
	    WHERE name = @FAMIGLIA1_PREFIX + '-' + @FAMIGLIA2_PREFIX + '-' + @FAMIGLIA3_PREFIX

        IF @@ROWCOUNT = 0
	    BEGIN

  		  SELECT TOP 1 
		    @iFamIndex = id
	      , @UMMaga = ummaga
	      , @EntityMaga = entitymaga
	      , @UMAcq = umacq
	      , @EntityAcq = entityacq

		  FROM ICM_FamMerc
		  WHERE name = @FAMIGLIA1_PREFIX + '-' + @FAMIGLIA2_PREFIX

	      IF @@ROWCOUNT = 0
	      BEGIN

    	    SELECT TOP 1 
		      @iFamIndex = id
		    , @UMMaga = ummaga
	        , @EntityMaga = entitymaga
	        , @UMAcq = umacq
	        , @EntityAcq = entityacq
		    FROM ICM_FamMerc
		    WHERE name = @FAMIGLIA1_PREFIX

	        IF @@ROWCOUNT = 0 
		      SET @bFamFound = 0


	      END
		    

	    END


	    IF @bFamFound = 1
	    BEGIN		    


		  IF ISNULL(@UMMaga, '') <> '' AND ISNULL(@EntityMaga, '') <> ''
		  BEGIN

		    SET @UM = @UMMaga

		    IF @EntityMaga = 'QTA'
		    BEGIN

		      SET @FattoreConversione = 1
			  --SET @UM = 'NR'

            END
		    ELSE
		    BEGIN

		      IF UPPER(@EntityMaga) = 'LG'
		      BEGIN

		        IF @LgNumero IS NOT NULL
			    BEGIN


			      SELECT TOP 1 
	                @FatConv2 = conv
	              FROM ICM_UMConv
	              WHERE um1 = @UMSolidWorksLinear
	                AND um2 = @UM

        	      IF @@ROWCOUNT = 0
	              BEGIN

	                SELECT TOP 1 
  	                  @FatConv2 = (1 / conv)
			        FROM ICM_UMConv
				    WHERE um1 = @UM
	                  AND um2 = @UMSolidWorksLinear

		            IF @@ROWCOUNT = 0
		            BEGIN

				  
				      SET @Severity = 16

		              SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UMSolidWorksLinear + ' e ' + @UM + ' non trovato'
 
	            
	                  GOTO labelExit				
				
				    END


				  END

			      SET @FattoreConversione = @LgNumero * @FatConv2


			    END
			    ELSE
		        BEGIN


			      SET @Severity = 16

		          SET @XErrore = 'Lunghezza nulla per componente con codice: ' + @DEDIDC + '/' + @DEDREVC
 	              GOTO labelExit


			    END
			  END
				  

			  IF UPPER(@EntityMaga) = 'PESO'
		      BEGIN

		        IF @PesoNetto IS NOT NULL
			    BEGIN

			  	  SELECT TOP 1 
  	                @FatConv2 = conv
	              FROM ICM_UMConv
	              WHERE um1 = @UMSolidWorksMass
	                AND um2 = @UM

        	      IF @@ROWCOUNT = 0
	              BEGIN

	                SELECT TOP 1 
  	                  @FatConv2 = (1 / conv)
			        FROM ICM_UMConv
				    WHERE um1 = @UM
	                  AND um2 = @UMSolidWorksMass

		            IF @@ROWCOUNT = 0
		            BEGIN

				  
				      SET @Severity = 16

		              SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UMSolidWorksMass + ' e ' + @UM + ' non trovato'
 
	            
	                  GOTO labelExit				
				
				    END


				  END

			      SET @FattoreConversione = @PesoNetto * @FatConv2
				
			    END
		        ELSE
			    BEGIN


				  SET @Severity = 16

		          SET @XErrore = 'Peso netto nullo per componente con codice: ' + @DEDIDC + '/' + @DEDREVC
 
	            
	              GOTO labelExit
	            

			    END
					

			  END

			  IF UPPER(@EntityMaga) = 'SUP_GOMMATA'
			  BEGIN

		        IF @SuperficieGommata IS NOT NULL
			    BEGIN

			      SELECT TOP 1 
	                @FatConv2 = conv
	              FROM ICM_UMConv
	              WHERE um1 = @UMSolidWorksLinear
	                AND um2 = @UM

        	      IF @@ROWCOUNT = 0
	              BEGIN

	                SELECT TOP 1 
  	                  @FatConv2 = (1 / conv)
			        FROM ICM_UMConv
				    WHERE um1 = @UM
	                  AND um2 = @UMSolidWorksLinear

		            IF @@ROWCOUNT = 0
		            BEGIN

				  
				      SET @Severity = 16

		              SET @XErrore = 'Fattore di conversione tra unità di misura ' + @UMSolidWorksLinear + ' e ' + @UM + ' non trovato'
 
	            
	                  GOTO labelExit				
				
				    END


				  END

			      SET @FattoreConversione = @SuperficieGommata * @FatConv2 * @FatConv2

				
			    END
			    ELSE
			    BEGIN

				  SET @Severity = 16

		          SET @XErrore = 'Superficie Gommata nulla per componente con codice: ' + @DEDIDC + '/' + @DEDREVC
 
	                    
	              GOTO labelExit


		        END
			  END
		    END
		  END
		  ELSE
		  BEGIN
		    SET @Severity = 16

		    SET @XErrore = 'Unità di misura di magazzino non trovata per componente con codice: ' + @DEDIDC + '/' + @DEDREVC

		    GOTO labelExit

		  END


	    END
	    ELSE
	    BEGIN

	       SET @Severity = 16

		   SET @XErrore = 'Famiglia merceologica non trovata per componente con codice: ' + @DEDIDC + '/' + @DEDREVC

	     
	       GOTO labelExit

	    END


	    UPDATE SWBOM 
	      SET CONSUMO = CONSUMO + @QTA * @FattoreConversione
		    , UMCONSUMO = @UM
	    WHERE SessionID = @SessionID
	    AND DEDIDP = @DEDIDP
  	    AND DEDREVP = @DEDREVP
	    AND DEDIDC = @DEDIDC
	    AND DEDREVC = @DEDREVC

	    IF @@ERROR <> 0
		BEGIN
		  SET @Severity = 16

		  SET @XErrore = 'Errore aggiornamento Distinta per componente con codice: ' + @DEDIDC + '/' + @DEDREVC

	     
	      GOTO labelExit

		END


	  END

	  CLOSE SWBOM
	  DEALLOCATE SWBOM


	END 


	CLOSE SWANAG
	DEALLOCATE SWANAG


	labelExit:
	RETURN @Severity

END
