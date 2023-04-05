/****** Object:  Table [dbo].[XPORT_Elab]    Script Date: 3/17/2023 5:23:40 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[XPORT_Elab](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[DocumentID] [int] NULL,
	[Filename] [nvarchar](500) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Completed] [smallint] NULL,
	[Failed] [smallint] NULL,
	[Vault] [nvarchar](50) NULL,
	[InsertDate] [datetime] NULL,
	[SessionID] [uniqueidentifier] NULL,
	[Versione] [int] NULL,
	[Configurazioni] [nvarchar](max) NULL,
	[OnlyTop] [smallint] NULL,
	[EsplodiPar1] [nvarchar](1000) NULL,
	[EsplodiPar2] [nvarchar](1000) NULL,
	[DittaARCA] [nvarchar](1000) NULL,
	[Priority] [int] NULL,
	[IPLog] [nvarchar](100) NULL,
	[PortLog] [nvarchar](100) NULL
 CONSTRAINT [PK_XPORT_Elab] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Index [IX_XPORT_Elab_Failed]    Script Date: 3/17/2023 5:23:40 PM ******/
CREATE NONCLUSTERED INDEX [IX_XPORT_Elab_Failed] ON [dbo].[XPORT_Elab]
(
	[Failed] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Index [IX_XPORT_Elab_Priority]    Script Date: 3/17/2023 5:23:40 PM ******/
CREATE NONCLUSTERED INDEX [IX_XPORT_Elab_Priority] ON [dbo].[XPORT_Elab]
(
	[Priority] ASC,
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_XPORT_Elab_Vault]    Script Date: 3/17/2023 5:23:40 PM ******/
CREATE NONCLUSTERED INDEX [IX_XPORT_Elab_Vault] ON [dbo].[XPORT_Elab]
(
	[Vault] ASC,
	[DocumentID] ASC,
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

ALTER TABLE [dbo].[XPORT_Elab] ADD  CONSTRAINT [DF_XPORT_Elab_DocumentID]  DEFAULT ((0)) FOR [DocumentID]
GO

ALTER TABLE [dbo].[XPORT_Elab] ADD  CONSTRAINT [DF_Table_1_Coompleted]  DEFAULT ((0)) FOR [Completed]
GO

ALTER TABLE [dbo].[XPORT_Elab] ADD  CONSTRAINT [DF_XPORT_Elab_Failed]  DEFAULT ((0)) FOR [Failed]
GO

ALTER TABLE [dbo].[XPORT_Elab] ADD  CONSTRAINT [DF_XPORT_Elab_Vault]  DEFAULT (N'("")') FOR [Vault]
GO

ALTER TABLE [dbo].[XPORT_Elab] ADD  CONSTRAINT [DF_XPORT_Elab_OnlyTop]  DEFAULT ((0)) FOR [OnlyTop]
GO

ALTER TABLE [dbo].[XPORT_Elab] ADD  CONSTRAINT [DF_XPORT_Elab_Priority_1]  DEFAULT ((0)) FOR [Priority]
GO


GO