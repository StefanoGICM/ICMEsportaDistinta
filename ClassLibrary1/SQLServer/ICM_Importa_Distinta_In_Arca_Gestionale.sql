/****** Object:  StoredProcedure [dbo].[xICM_Importa_Distinta_In_ArcaSp]    Script Date: 11/8/2022 10:16:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

ALTER PROCEDURE [dbo].[xICM_Importa_Distinta_In_ArcaSp] 
	-- Add the parameters for the stored procedure here
(   @POnlyTop int = 1
  , @XWarning varchar(max) OUTPUT )
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE 
	  @DEDID nvarchar(30)
   ,  @DEDREV nvarchar(30)

   DECLARE @Severity int

   DECLARE @Error varchar(1000)
   DECLARE @date smalldatetime

   SET @date = GETDATE()

    -- Insert statements for procedure here
	SELECT TOP 1 @DEDID = DEDID
	           , @DEDREV =  DEDREV
    FROM [WS91].[EPDMSuite].[dbo].[XPORT_anag]
	WHERE DEDStart = 'S'

	IF @@ROWCOUNT = 1 
	BEGIN

	  IF @DEDID IS NOT NULL AND @DEDREV IS NOT NULL
	  BEGIN

	    SET @Error = NULL

	    EXECUTE @Severity = xSOLIDCreaArticoloSp
			@DedId = @DEDID,
			@DedRev = @DEDREV,
			@Transaction = 1,
			@Azione = 'U',
			----@ForzaFantaKit = 0,
			@CodPadre = '',
			--  @LivelloMax int,
			--  @Livello int,
			--  @ParDove varchar(3),
			@XErrore = @Error OUTPUT,
			@XWarning = @XWarning OUTPUT,
			@DistDate = @date,
			@UltRev = 0,
			----@UltBBT = 0,
			@DedIdPadre = NULL,
			@Livello = 0,
			@First = 1,
			@OnlyTop = @POnlyTop

		  IF (@Severity <> 0) OR (@Error  IS NOT NULL)
		  BEGIN


		    RAISERROR (@Error, -- Message text.  
             16, -- Severity,  
             1) -- State) -- First argum

			

		  END

	  END

	END
END
