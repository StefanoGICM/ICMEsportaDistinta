USE [EPDMSuite]
GO
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
  @XErrore nvarchar(200) OUTPUT
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
	, @QTA numeric (21, 6) 
	, @CONSUMO numeric (21, 6)
	, @UM nvarchar(50)
	, @FAMIGLIA1_PREFIX nvarchar(200)
	, @FAMIGLIA2_PREFIX nvarchar(200)
	, @FAMIGLIA3_PREFIX nvarchar(200)
	, @LG nvarchar(200)
	, @SUP_GOMMATA nvarchar(200)
	, @PESO nvarchar(200)
	, @iCount int
	, @NEWLG nvarchar(200)
	, @NEWSUP_GOMMATA nvarchar(200)
	, @NEWPESO nvarchar(200)
	, @PesoNetto numeric (21,6)
	, @SuperficieGommata numeric (21,6)
	, @FattoreConversione numeric (21,6)
	, @FatConv2 numeric (21,6)
	, @LgNumero numeric (21,6)
	, @DEDLinear varchar(200)
	, @DEDMass varchar(200)
	, @DEDLinearInt int
	, @DEDMassInt int
	, @UMSolidWorksLinear varchar(50)
	, @UMSolidWorksMass varchar(50)
	, @UMArcaLinear varchar(50)
	, @UMArcaMass varchar(50)
	, @iFamIndex int
	, @bFamFound smallint
	, @UMCod nvarchar(200)
	, @Entity nvarchar(200)
	, @id int



    SET @UMArcaLinear = 'MT'

	SET @UMArcaMass = 'KG'

	
	--print 'prima'

	DELETE FROM XPORT_DIST 


	DECLARE XPORT_DISTCrs CURSOR LOCAL STATIC FOR
	  SELECT 
	    id
	  , DEDIDP
	  , DEDREVP
	  , DEDIDC
	  , DEDREVC
	  , QTA
	  , FAMIGLIA1_PREFIX
	  , FAMIGLIA2_PREFIX
	  , FAMIGLIA3_PREFIX
	  , LG
	  , SUP_GOMMATA
	  , PESO
	  , DEDLinear
	  , DEDMass
	  FROM tmp_ICM_Consumo


	OPEN XPORT_DISTCrs

	WHILE (@Severity = 0)
	BEGIN

	  FETCH XPORT_DISTCrs INTO 
	    @id
	  , @DEDIDP
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

	  /* Calcolo fattore di conversione tra le unità di misura di SolidWorks e di Arca*/	



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
		  SET @PesoNetto =  (CAST(REPLACE(@PESO, ',' , '.') AS numeric(18,4)))
		ELSE
		  SET @PesoNetto = 0

      --print 'pippo52'
      SET @SuperficieGommata = NULL

	  IF @SUP_GOMMATA IS NULL
		SET @SuperficieGommata = 0
	  ELSE
	    IF ISNUMERIC(@SUP_GOMMATA) = 1
		  SET @SuperficieGommata = (CAST(REPLACE(@SUP_GOMMATA, ',' , '.') AS numeric(18,4)))
		ELSE
		  SET @SuperficieGommata = 0

      SET @LgNumero = NULL

	  --print 'pippo53'

	  IF @LG IS NULL
		SET @LgNumero = 0
	  ELSE
	    IF ISNUMERIC(@LG) = 1
		  SET @LgNumero = (CAST(REPLACE(@LG, ',' , '.') AS numeric(18,4)))
		ELSE
		  SET @LgNumero = 0

	  --print 'lglglglglglglglglglgl'
	  --print @LG
	  --print @LgNumero
	  --print @FattoreUMLinear
	  --print @DEDIDC
	  --print @DEDREVC
	  


	  /* Recupero unità di misura e entità */
	  SET @iFamIndex = 0
      SET @bFamFound = 1

      SELECT TOP 1 
		@iFamIndex = id
      FROM ICM_FamMerc
	  WHERE name = @FAMIGLIA1_PREFIX + '-' + @FAMIGLIA2_PREFIX + '-' + @FAMIGLIA3_PREFIX

      IF @@ROWCOUNT = 0
	  BEGIN

  		SELECT TOP 1 
		  @iFamIndex = id
		FROM ICM_FamMerc
		WHERE name = @FAMIGLIA1_PREFIX + '-' + @FAMIGLIA2_PREFIX

	    IF @@ROWCOUNT = 0
	    BEGIN

    	  SELECT TOP 1 
		    @iFamIndex = id
		  FROM ICM_FamMerc
		  WHERE name = @FAMIGLIA1_PREFIX

	      IF @@ROWCOUNT = 0 
		    SET @bFamFound = 0


	    END
		    

	   END




	   IF @bFamFound = 1
	   BEGIN		    

	     SELECT TOP 1 
	       @UMCod = name 
		 , @Entity = entity
	     FROM ICM_UMMaga
	     WHERE id = @iFamIndex

		IF @@ROWCOUNT = 1 AND ISNULL(@UMCod, '') <> '' AND ISNULL(@Entity, '') <> ''
		BEGIN

		  SET @UM = @UMCod

		  IF @Entity = 'QTA'
		  BEGIN

		    SET @FattoreConversione = 1
			--SET @UM = 'NR'

          END
		  ELSE
		  BEGIN

		    IF UPPER(@Entity) = 'LG'
		    BEGIN

		      IF @LgNumero IS NOT NULL
			  BEGIN

			    --print '------'

			    --print 'LG'
				--print @LgNumero
				--print @FattoreUMLinear

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
				  

			IF UPPER(@Entity) = 'PESO'
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
				--SET @UM = 'KG'
			  END
		      ELSE
			  BEGIN


				SET @Severity = 16

		        SET @XErrore = 'Peso netto nullo per componente con codice: ' + @DEDIDC + '/' + @DEDREVC
 
	            
	            GOTO labelExit
	            

			  END
					

			END

			IF UPPER(@Entity) = 'SUP_GOMMATA'
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

				--SET @UM = 'MQ'
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

	   --print '@FattoreConversione'
	   --print @FattoreConversione

	   IF NOT EXISTS (SELECT 1 FROM XPORT_DIST WHERE DEDIDP = @DEDIDP
												 AND DEDREVP = @DEDREVP
												 AND DEDIDC = @DEDIDC
												 AND DEDREVC = @DEDREVC)
	   BEGIN

	     INSERT INTO XPORT_DIST
		 ( DEDIDP
		 , DEDREVP
	     , DEDIDC
	     , DEDREVC
	     , CONSUMO
	     , UM
		 )
		 VALUES
		 (
				 
		   @DEDIDP
		 , @DEDREVP
	     , @DEDIDC
	     , @DEDREVC
	     , @QTA * @FattoreConversione
	     , @UM
		 
		 )

	   END
	   ELSE
	   BEGIN

	     UPDATE XPORT_DIST 
	       SET CONSUMO = CONSUMO + @QTA * @FattoreConversione
		     , UM = @UM
	     WHERE DEDIDP = @DEDIDP
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

	END 

	CLOSE XPORT_DISTCrs
	DEALLOCATE XPORT_DISTCrs


	labelExit:



	RETURN @Severity
END
