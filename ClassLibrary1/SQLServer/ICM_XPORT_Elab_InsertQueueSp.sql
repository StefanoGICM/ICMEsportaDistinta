/****** Object:  StoredProcedure [dbo].[ICM_LogStartSp]    Script Date: 3/17/2023 6:27:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[ICM_XPORT_Elab_InsertQueueSp] 
	-- Add the parameters for the stored procedure here
	(
	  @Vault As nvarchar(500)
	, @DocumentID int
	, @FileName nvarchar(500)
	, @Versione int
	, @Configurazioni nvarchar(max)
	, @OnlyTop int
	, @EspandiPar1 nvarchar(500)
	, @EspandiPar2 nvarchar(500)
	, @DittaARCA nvarchar(1000)
	, @Priority int
	, @SessionID uniqueidentifier
	, @Id bigint OUTPUT
	, @IPLog nvarchar(100)
	, @PortLog nvarchar(100)
	)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO [dbo].[XPORT_Elab]
	(	
	   DocumentID
	 , Filename
--	 , StartDate
--	 , EndDate
--	 , Completed
--	 , Failed
	 , Vault
	 , InsertDate
	 , SessionID
	 , Versione
	 , Configurazioni
	 , OnlyTop
	 , EsplodiPar1
	 , EsplodiPar2
	 , DittaARCA
	 , Priority
	 , IPLog
	 , PortLog
	) 
	VALUES 
	(
	  @DocumentID
	, @FileName
	, @Vault	
	, GETDATE()
	, @SessionID
	, @Versione
	, @Configurazioni
	, @OnlyTop
	, @EspandiPar1
	, @EspandiPar2
	, @DittaARCA
	, @Priority
	, @IPLog
	, @PortLog
	)

	SET @Id = @@IDENTITY

END

