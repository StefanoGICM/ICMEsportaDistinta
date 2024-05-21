USE [EPDMSuite]
GO

/****** Object:  Table [dbo].[XPORT_Pro]    Script Date: 3/6/2023 4:25:23 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[XPORT_Pro](
	[DocumentID] [int] NOT NULL,
	[Configuration] [nvarchar](200) NOT NULL,
	[RevisionNo] [int] NOT NULL,
	[Promosso] [smallint] NOT NULL,
	[Changed] [smallint] NOT NULL,
 CONSTRAINT [PK_XPORT_Pro_1] PRIMARY KEY CLUSTERED 
(
	[DocumentID] ASC,
	[Configuration] ASC,
	[RevisionNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE INDEX IX_XPORT_Pro_Changed ON [dbo].[XPORT_Pro] ([Changed], [DocumentID], [Configuration], [RevisionNo]);
GO





