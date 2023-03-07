USE [EPDMSuite]
GO

/****** Object:  Table [dbo].[SWANAG]    Script Date: 12/13/2022 8:26:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[SWANAG](
	[DEDID] [nvarchar](50) NOT NULL,
	[DEDREV] [nvarchar](50) NOT NULL,
	[CATEGORIA1] [nvarchar](200) NULL,
	[CATEGORIA2] [nvarchar](200) NULL,
	[CATEGORIA3] [nvarchar](200) NULL,
	[CATEGORIA1_PREFIX] [nvarchar](200) NULL,
	[CATEGORIA2_PREFIX] [nvarchar](200) NULL,
	[CATEGORIA3_PREFIX] [nvarchar](200) NULL,
	[FAMIGLIA1] [nvarchar](200) NULL,
	[FAMIGLIA2] [nvarchar](200) NULL,
	[FAMIGLIA3] [nvarchar](200) NULL,
	[FAMIGLIA1_PREFIX] [nvarchar](200) NULL,
	[FAMIGLIA2_PREFIX] [nvarchar](200) NULL,
	[FAMIGLIA3_PREFIX] [nvarchar](200) NULL,
	[COMMESSA] [nvarchar](200) NULL,
	[DEDDATE] [nvarchar](200) NULL,
	[DBPATH] [nvarchar](200) NULL,
	[DED_COD] [nvarchar](200) NULL,
	[DED_DIS] [nvarchar](200) NULL,
	[DED_FILE] [nvarchar](200) NULL,
	[DEDREVDATE] [nvarchar](200) NULL,
	[DEDREVDESC] [nvarchar](200) NULL,
	[DEDREVUSER] [nvarchar](200) NULL,
	[DEDSTATEID] [nvarchar](200) NULL,
	[DEDDESC] [nvarchar](200) NULL,
	[LG] [nvarchar](200) NULL,
	[MATERIALE] [nvarchar](200) NULL,
	[NOTA_DI_TAGLIO] [nvarchar](200) NULL,
	[PESO] [nvarchar](200) NULL,
	[SUP_GOMMATA] [nvarchar](200) NULL,
	[TIPOLOGIA] [int] NULL,
	[TRATT_TERM] [nvarchar](200) NULL,
	[DEDSTATEID1] [nvarchar](200) NULL,
	[ITEM] [nvarchar](200) NULL,
	[POTENZA] [nvarchar](200) NULL,
	[N_MOTORI] [nvarchar](200) NULL,
	[SOTTOCOMMESSA] [nvarchar](200) NULL,
	[Standard_DIN] [nvarchar](200) NULL,
	[Standard_ISO] [nvarchar](200) NULL,
	[Standard_UNI] [nvarchar](200) NULL,
	[MPTH] [nvarchar](200) NULL,
	[Produttore] [nvarchar](200) NULL,
	[shmetal_AreaContorno_mm2] [nvarchar](200) NULL,
	[shmetal_L1_Contorno] [nvarchar](200) NULL,
	[shmetal_L2_Contorno] [nvarchar](200) NULL,
	[shmetal_Piegature] [nvarchar](200) NULL,
	[shmetal_RaggioDiPiegatura] [nvarchar](200) NULL,
	[shmetal_Sp_Lamiera] [nvarchar](200) NULL,
	[Designazione] [nvarchar](200) NULL,
	[DesignazioneGeometrica] [nvarchar](200) NULL,
	[DesignazioneGeometricaEN] [nvarchar](200) NULL,
	[DesignazioneGeometricaENG] [nvarchar](200) NULL,
	[DesignazioneGeometricaITA] [nvarchar](200) NULL,
	[IngombroX] [nvarchar](200) NULL,
	[IngombroY] [nvarchar](200) NULL,
	[IngombroZ] [nvarchar](200) NULL,
	[LargMacchina] [nvarchar](200) NULL,
	[LungMacchina] [nvarchar](200) NULL,
	[CATEGORIA4] [nvarchar](200) NULL,
	[CATEGORIA4_PREFIX] [nvarchar](200) NULL,
	[CodiceProduttore] [nvarchar](200) NULL,
	[CATEGORIA0] [nvarchar](200) NULL,
	[CATEGORIA0_PREFIX] [nvarchar](200) NULL,
	[FaiAcquista] [nvarchar](200) NULL,
	[Configurazione] [nvarchar](200) NULL,
	[DescTecnicaITA] [nvarchar](200) NULL,
	[DescTecnicaENG] [nvarchar](200) NULL,
	[DescCommercialeITA] [nvarchar](200) NULL,
	[DescCommercialeENG] [nvarchar](200) NULL,
	[TRATT_TERMICO] [nvarchar](200) NULL,
	[TrattFinitura] [nvarchar](200) NULL,
	[TrattGalvanico] [nvarchar](200) NULL,
	[TrattProtezione] [nvarchar](200) NULL,
	[TrattSuperficiale] [nvarchar](200) NULL,
	[TipoSW] [nvarchar](200) NULL,
	[DEDStart] [nvarchar](200) NULL,
	[DEDLinear] [nvarchar](200) NULL,
	[DEDMass] [nvarchar](200) NULL
 CONSTRAINT [PK_SWANAG] PRIMARY KEY CLUSTERED 
(
	[DEDID] ASC,
	[DEDREV] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[SWANAG] ADD  CONSTRAINT [DF_SWANAG_DEDStart]  DEFAULT ('N') FOR [DEDStart]
GO

CREATE INDEX IX_SWANAG_DEDStart ON [dbo].[SWANAG] ([DEDStart]);
GO