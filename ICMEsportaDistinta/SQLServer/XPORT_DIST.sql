USE [EPDMSuite]
GO

/****** Object:  Table [dbo].[XPORT_DIST]    Script Date: 12/1/2022 4:55:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[XPORT_DIST](
	[DEDIDP] [nvarchar](50) NOT NULL,
	[DEDREVP] [nvarchar](50) NOT NULL,
	[DEDIDC] [nvarchar](50) NOT NULL,
	[DEDREVC] [nvarchar](50) NOT NULL,
	[CONSUMO] [numeric] (21, 6) NOT NULL DEFAULT (0),
	[UM] [nvarchar](50) NOT NULL DEFAULT ('')
 CONSTRAINT [PK_XPORT_DIST] PRIMARY KEY CLUSTERED 
(
	[DEDIDP] ASC,
	[DEDREVP] ASC,
	[DEDIDC] ASC,
	[DEDREVC] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

