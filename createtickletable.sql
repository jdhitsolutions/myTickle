SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[EventData](
	[EventID] [int] IDENTITY(100,1) NOT NULL,
	[EventDate] [datetime2](7) NOT NULL,
	[EventName] [nvarchar](50) NOT NULL,
	[EventComment] [nvarchar](50) NULL,
	[Archived] [bit] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[EventData] ADD CONSTRAINT [DF_EventData_Archived]  DEFAULT (N'0') FOR [Archived]
