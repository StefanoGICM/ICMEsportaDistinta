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
ALTER PROCEDURE xSOLIDTTInsert
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
      if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME= 'ICM_UMLinear')
	    DROP TABLE ICM_UMLinear

	  CREATE TABLE ICM_UMLinear
	  (id INT,
	   um varchar(50),
	   PRIMARY KEY (id)
	  )


      if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME= 'ICM_UMMass')
	    DROP TABLE ICM_UMMass

	  CREATE TABLE ICM_UMMass
	  (id INT,
	   um varchar(50),
	   PRIMARY KEY (id)
	  )


	  if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME= 'ICM_UMConv')
	    DROP TABLE ICM_UMConv

	  --Conversione UM per Linear
	   CREATE TABLE ICM_UMConv
	  (id INT, 
	   um1 varchar(50),
	   um2 varchar(50),
	   conv decimal(23,11),
	   PRIMARY KEY (id),
	   UNIQUE NONCLUSTERED (um1, um2),
	   UNIQUE NONCLUSTERED (um2, um1)
	  )


	  if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME= 'ICM_FamMerc')
        DROP TABLE ICM_FamMerc


	  -- Assegnazione unità di misura di acquisto per famiglie merceologiche
	  CREATE TABLE ICM_FamMerc (id INT, 
	                            name varchar(50), 
								ummaga varchar(50),
								entitymaga varchar(100),
								umacq varchar(50),
								entityacq varchar(100),
								PRIMARY KEY (id), UNIQUE NONCLUSTERED (name) )
	  

    insert into ICM_UMLinear
	  values
	  (0, 'MM'),
	  (1, 'CM'),
	  (2, 'MT'),
	  (3, 'INCHES'),
	  (4, 'FEET'),
	  (5, 'FEET&INCHES'),
	  (9, 'MILS'),
	  (10, 'MICROINCHES')

    insert into ICM_UMMass
	  values
	  (1, 'MG'),
	  (2, 'GR'),
	  (3, 'KG'),
	  (4, 'POUNDS')

	insert into ICM_UMConv
	  values
	  (1, 'MM', 'CM', 0.1),
	  (2, 'MM', 'MT', 0.001),
	  (3, 'CM', 'MT', 0.01),
	  (4, 'MT', 'INCHES', 39.3701),
	  (5, 'CM', 'INCHES', 0.393701),
	  (6, 'MM', 'INCHES', 0.03937),
	  (7, 'MT', 'FEET', 3.2808),
	  (8, 'CM', 'FEET', 0.032808),
	  (9, 'MM', 'FEET', 0.00328084),
  	  (10, 'INCHES', 'FEET', 0.083333),
	  (11, 'MG', 'GR', 0.001),
	  (12, 'GR', 'KG', 0.001),
  	  (13, 'MG', 'KG', 0.000001),
	  (14, 'KG', 'POUNDS', 2.2046),
	  (15, 'GR', 'POUNDS', 0.00220462),
	  (16, 'MG', 'POUNDS', 0.0000022046),
	  (17, 'MM', 'MM', 1),
	  (18, 'CM', 'CM', 1),
	  (19, 'MT', 'MT', 1),
	  (20, 'FEET', 'FEET', 1),
	  (21, 'INCHES', 'INCHES', 1),
	  (22, 'MG', 'MG', 1),
	  (23, 'GR', 'GR', 1),
	  (24, 'KG', 'KG', 1),
	  (25, 'POUNDS', 'POUNDS', 1)



	  insert into ICM_FamMerc 
	  values
	  (1, '513', 'NR', 'QTA', 'NR', 'QTA'),     --ATTUATORI
	  (2, '500', 'NR', 'QTA', 'NR', 'QTA'),     --BULLONERIE
	  (3, '600', 'NR', 'QTA', 'KG', 'PESO'),     --CARPENTERIE
	  (4, '507', 'NR', 'QTA', 'NR', 'QTA'),     --COMPRESSORI
	  (5, '512', 'NR', 'QTA', 'NR', 'QTA'),     --CUSCINETTI
	  (6, '508', 'NR', 'QTA', 'NR', 'QTA'),     --FANCOIL
      (7, '504', 'NR', 'QTA', 'NR', 'QTA'),     --FERRAMENTA
	  (8, '515', 'NR', 'QTA', 'NR', 'QTA'),     --GRUPPI ELETTR.
	  (9, '502', 'NR', 'QTA', 'NR', 'QTA'),     --GUARNIZIONI
	  (10, '605', 'NR', 'QTA', 'NR', 'QTA'),    --LAVORATI A MACCHINA
	  (11, '510', 'NR', 'QTA', 'NR', 'QTA'),    --MATERIALE ELETTRICO
	  (12, '800', 'NR', 'QTA', 'NR', 'QTA'),    --MONTAGGI
	  (13, '511', 'NR', 'QTA', 'NR', 'QTA'),    --MOTORI
	  (14, '501', 'NR', 'QTA', 'NR', 'QTA'),    --PIPING
	  (15, '505', 'NR', 'QTA', 'NR', 'QTA'),    --POMPE
	  (16, '750', 'NR', 'QTA', 'NR', 'QTA'),    --PRODOTTI IN PLASTICA
	  (17, '514', 'NR', 'QTA', 'NR', 'QTA'),    --RALLE
	  (18, '503', 'NR', 'QTA', 'NR', 'QTA'),    --SENSORI
	  --(19, 'LAG'),    -- ??LAMIERE GOMMATE
	  --(20, 'TAP'),    -- ??TAPPETI
	  --(21, 'GRI'),    -- ??GRIGLIATI
	  (22, '509', 'NR', 'QTA', 'NR', 'QTA'),    -- APPARECCHIATURE ELTTRICHE CUSTOM
	  (23, '506', 'NR', 'QTA', 'NR', 'QTA'),    --FILTRI
	  (24, '700', 'NR', 'QTA', 'NR', 'QTA'),    --COMMERCIALI 
	  (25, '540', 'NR', 'QTA', 'NR', 'QTA'),    --PIPING
	  (26, '560', 'NR', 'QTA', 'NR', 'QTA'),    --GUARNIZIONI E TENUTE
	  --(27, 'BAV-000-000')     -- ??GREZZO BAVETTA
	  (27, '517', 'NR', 'QTA', 'NR', 'QTA'),     -- RIVESTIMENTI
	  (28, '516', 'NR', 'QTA', 'NR', 'QTA')      -- GUARNIZIONI CUSTOM
	  



END
GO
