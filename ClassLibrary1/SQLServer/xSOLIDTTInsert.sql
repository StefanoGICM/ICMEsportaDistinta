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
	  CREATE TABLE ICM_FamMerc (id INT, name varchar(50), PRIMARY KEY (id), UNIQUE NONCLUSTERED (name) )


	  if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME= 'ICM_UMMaga')
        DROP TABLE ICM_UMMaga
	
	  CREATE TABLE ICM_UMMaga (id INT, name varchar(50), entity varchar(100), PRIMARY KEY (id))

	
	   if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME= 'ICM_UMAcq')
        DROP TABLE ICM_UMAcq
	

	  CREATE TABLE ICM_UMAcq (id INT, name varchar(50), entity varchar(100), PRIMARY KEY (id))

	  if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME= 'tmp_ICM_Consumo')
	    DROP TABLE tmp_ICM_Consumo

	  CREATE TABLE tmp_ICM_Consumo
	  (id INT,
		DEDIDP nvarchar(50)
	  , DEDREVP nvarchar(50)
	  , DEDIDC nvarchar(50)
	  , DEDREVC nvarchar(50)
	  , QTA numeric(21,6)
  	  , FAMIGLIA1_PREFIX nvarchar(200)
	  , FAMIGLIA2_PREFIX nvarchar(200)
	  , FAMIGLIA3_PREFIX nvarchar(200)
	  , LG nvarchar(200)
	  , SUP_GOMMATA nvarchar(200)
	  , PESO nvarchar(200)
	  , DEDLinear nvarchar(200)
	  , DEDMass nvarchar(200)
	   PRIMARY KEY (id)
	  )





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
	  (1, '513'),     --ATTUATORI
	  (2, '500'),     --BULLONERIE
	  (3, '600'),     --CARPENTERIE
	  (4, '507'),     --COMPRESSORI
	  (5, '512'),     --CUSCINETTI
	  (6, '508'),     --FANCOIL
      (7, '504'),     --FERRAMENTA
	  (8, '515'),     --GRUPPI ELETTR.
	  (9, '502'),     --GUARNIZIONI
	  (10, '605'),    --LAVORATI A MACCHINA
	  (11, '510'),    --MATERIALE ELETTRICO
	  (12, '800'),    --MONTAGGI
	  (13, '511'),    --MOTORI
	  (14, '501'),    --PIPING
	  (15, '505'),    --POMPE
	  (16, '750'),    --PRODOTTI IN PLASTICA
	  (17, '514'),    --RALLE
	  (18, '503'),    --SENSORI
	  --(19, 'LAG'),    -- ??LAMIERE GOMMATE
	  --(20, 'TAP'),    -- ??TAPPETI
	  --(21, 'GRI'),    -- ??GRIGLIATI
	  (22, '509'),    -- APPARECCHIATURE ELTTRICHE CUSTOM
	  (23, '506'),    --FILTRI
	  (24, '700'),    --COMMERCIALI 
	  (25, '540'),    --PIPING
	  (26, '560'),    --GUARNIZIONI E TENUTE
	  --(27, 'BAV-000-000')     -- ??GREZZO BAVETTA
	  (27, '517'),     -- RIVESTIMENTI
	  (28, '516'),      -- GUARNIZIONI CUSTOM
	  (29, '518'),      -- RULLI
	  (30, '400'),   -- ASSIEMI DI MONTAGGIO
	  (31, 'AP'),   -- ASSIEMI PROMOSSI
	  (32, '521'),   --- RETI
	  (33, '522'),   --- CALETTATORI
	  (34, '530'),   --- FISSAGGI
	  (35, '550'),   --- TRAVERSE AUTOCENTRANTI
	  (36, '555')   --- FERRAMENTA



	  insert into ICM_UMMaga 
	  values
	  (1, 'NR', 'QTA'),     --ATTUATORI
	  (2, 'NR', 'QTA'),     --BULLONERIE
	  (3, 'NR', 'QTA'),     --CARPENTERIE
	  (4, 'NR', 'QTA'),     --COMPRESSORI
	  (5, 'NR', 'QTA'),     --CUSCINETTI
	  (6, 'NR', 'QTA'),     --FANCOIL
      (7, 'NR', 'QTA'),     --FERRAMENTA
	  (8, 'NR', 'QTA'),     --GRUPPI ELETTR.
	  (9, 'NR', 'QTA'),     --GUARNIZIONI
	  (10, 'NR', 'QTA'),    --LAVORATI A MACCHINA
	  (11, 'NR', 'QTA'),    --MATERIALE ELETTRICO
	  (12, 'NR', 'QTA'),    --MONTAGGI
	  (13, 'NR', 'QTA'),    --MOTORI
	  (14, 'NR', 'QTA'),    --PIPING
	  (15, 'NR', 'QTA'),    --POMPE
	  (16, 'NR', 'QTA'),    --PRODOTTI IN PLASTICA
	  (17, 'NR', 'QTA'),    --RALLE
	  (18, 'NR', 'QTA'),    --SENSORI
	 -- (19, 'NR', 'QTA'),    -- ??LAMIERE GOMMATE
	 -- (20, 'NR', 'QTA'),    -- ??TAPPETI
	 -- (21, 'NR', 'QTA'),    -- ??GRIGLIATI
	  (22, 'NR', 'QTA'),    -- APPARECCHIATURE ELTTRICHE CUSTOM
	  (23, 'NR', 'QTA'),    --FILTRI
	  (24, 'NR', 'QTA'),    --COMMERCIALI 
	  (25, 'NR', 'QTA'),    --PIPING
	  (26, 'NR', 'QTA'),    --GUARNIZIONI E TENUTE
	  --(27, 'MT', 'LG')     -- ??GREZZO BAVETTA
	  (27, 'NR', 'QTA'),     --RIVESTIMENTI
	  (28, 'NR', 'QTA'),      -- GUARNIZIONI CUSTOM
	  (29, 'NR', 'QTA'),     --RULLI
	  (30, 'NR', 'QTA'),      --MONTAGGI
	  (31, 'NR', 'QTA'),      -- ASSIEMI PROMOSSI
	  (32, 'NR', 'QTA'),      -- RETI
	  (33, 'NR', 'QTA'),      -- CALETTATORI
	  (34, 'NR', 'QTA'),   --- FISSAGGI
	  (35, 'NR', 'QTA'),   --- TRAVERSE AUTOCENTRANTI
	  (36, 'NR', 'QTA')   --- FERRAMENTA


	  insert into ICM_UMAcq 
	  values
	  (1, 'NR', 'QTA'),	   --ATTUATORI
	  (2, 'NR', 'QTA'),    --BULLONERIE
	  (3, 'KG', 'PESO'),   --CARPENTERIE
	  (4, 'NR', 'QTA'),	   --COMPRESSORI
	  (5, 'NR', 'QTA'),	   --CUSCINETTI
	  (6, 'NR', 'QTA'),	   --FANCOIL
      (7, 'NR', 'QTA'),	   --FERRAMENTA
	  (8, 'NR', 'QTA'),	   --GRUPPI ELETTR.
	  (9, 'NR', 'QTA'),	   --GUARNIZIONI
	  (10, 'NR', 'QTA'),   --LAVORATI A MACCHINA
	  (11, 'NR', 'QTA'),   --MATERIALE ELETTRICO
	  (12, 'NR', 'QTA'),   --MONTAGGI
	  (13, 'NR', 'QTA'),   --MOTORI
	  (14, 'NR', 'QTA'),    --PIPING
	  (15, 'NR', 'QTA'),   --POMPE
	  (16, 'NR', 'QTA'),   --PRODOTTI IN PLASTICA
	  (17, 'NR', 'QTA'),   --RALLE
	  (18, 'NR', 'QTA'),   --SENSORI
	  --(19, 'MQ', 'SUP_GOMMATA'),    -- ??LAMIERE GOMMATE
	  --(20, 'MT', 'LG'),    -- ??TAPPETI
	  --(21, 'MTGRI', 'PESO'), -- ??GRIGLIATI
	  (22, 'NR', 'QTA'),   -- APPARECCHIATURE ELTTRICHE CUSTOM
	  (23, 'NR', 'QTA'),   --FILTRI
	  (24, 'NR', 'QTA'),   --COMMERCIALI 
	  (25, 'NR', 'QTA'),   --PIPING
	  (26, 'NR', 'QTA'),   --GUARNIZIONI E TENUTE
	  --(27, 'MT', 'LG')    -- ??GREZZO BAVETTA
	  (27, 'NR', 'QTA'),    --RIVESTIMENTI
	  (28, 'NR', 'QTA'),      -- GUARNIZIONI CUSTOM
	  (29, 'NR', 'QTA'),    -- RULLI
	  (30, 'NR', 'QTA'),      --MONTAGGI
	  (31, 'NR', 'QTA'),     -- ASSIEMI PROMOSSI
	  (32, 'NR', 'QTA'),      -- RETI
	  (33, 'NR', 'QTA'),      -- CALETTATORI
	  (34, 'NR', 'QTA'),   --- FISSAGGI
	  (35, 'NR', 'QTA'),   --- TRAVERSE AUTOCENTRANTI
	  (36, 'NR', 'QTA')   --- FERRAMENTA



END
GO
