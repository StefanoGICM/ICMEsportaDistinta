USE [EPDMSuite]
GO

/****** Object:  Table [dbo].[XPORT_Elab]    Script Date: 3/3/2023 10:09:20 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[XPORT_Elab](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[DocumentID] [int] NOT NULL,
	[Filename] [nvarchar](500) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Completed] [smallint] NOT NULL,
	[Failed] [smallint] NOT NULL,
	[Vault] [nvarchar](500) NOT NULL,
 CONSTRAINT [PK_XPORT_Elab] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[XPORT_Elab] ADD  CONSTRAINT [DF_XPORT_Elab_DocumentID]  DEFAULT ((0)) FOR [DocumentID]
GO

ALTER TABLE [dbo].[XPORT_Elab] ADD  CONSTRAINT [DF_Table_1_Coompleted]  DEFAULT ((0)) FOR [Completed]
GO

ALTER TABLE [dbo].[XPORT_Elab] ADD  CONSTRAINT [DF_XPORT_Elab_Failed]  DEFAULT ((0)) FOR [Failed]
GO

ALTER TABLE [dbo].[XPORT_Elab] ADD  CONSTRAINT [DF_XPORT_Elab_Vault]  DEFAULT (N'("")') FOR [Vault]
GO


CREATE INDEX IX_XPORT_Elab_Failed ON [dbo].[XPORT_Elab] ([Failed]);
GO