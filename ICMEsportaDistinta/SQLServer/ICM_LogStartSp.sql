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
CREATE PROCEDURE ICM_LogStartSp 
	-- Add the parameters for the stored procedure here
	(
	  @Vault As nvarchar(500)
	, @DocumentID int
	, @FileName nvarchar(500)
	, @Id bigint OUTPUT

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
	, StartDate
	, Vault
	) 
	VALUES 
	(
	  @DocumentID
	, @FileName
	, GETDATE()
	, @Vault	
	)

	SET @Id = @@IDENTITY

END

GO
