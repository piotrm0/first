SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ScheduleDetail]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[ScheduleDetail](
	[EventID] [int] NOT NULL,
	[ScheduleID] [int] NOT NULL,
	[Description] [nvarchar](50) NOT NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[TornamentLevel] [int] NULL,
 CONSTRAINT [PK_ScheduleDetail] PRIMARY KEY CLUSTERED 
(
	[ScheduleID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[RethrowError]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE  [dbo].[RethrowError] AS
    /* Return if there is no error information to retrieve. */
    IF ERROR_NUMBER() IS NULL
        RETURN;

    DECLARE
        @ErrorMessage    NVARCHAR(4000),
        @ErrorNumber     INT,
        @ErrorSeverity   INT,
        @ErrorState      INT,
        @ErrorLine       INT,
        @ErrorProcedure  NVARCHAR(200); 

    /* Assign variables to error-handling functions that
       capture information for RAISERROR. */

    SELECT
        @ErrorNumber = ERROR_NUMBER(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE(),
        @ErrorLine = ERROR_LINE(),
        @ErrorProcedure = ISNULL(ERROR_PROCEDURE(), ''-''); 

    /* Building the message string that will contain original
       error information. */

    SELECT @ErrorMessage = 
        N''Error %d, Level %d, State %d, Procedure %s, Line %d, '' + 
         ''Message: ''+ ERROR_MESSAGE(); 

    /* Raise an error: msg_str parameter of RAISERROR will contain
	   the original error information. */

    RAISERROR(@ErrorMessage, @ErrorSeverity, 1,
        @ErrorNumber,    /* parameter: original error number. */
        @ErrorSeverity,  /* parameter: original error severity. */
        @ErrorState,     /* parameter: original error state. */
        @ErrorProcedure, /* parameter: original error procedure name. */
        @ErrorLine       /* parameter: original error line number. */
        );


/* To prevent any potential data loss issues, you should review this script in detail before running it outside the context of the database designer.*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
IF NOT EXISTS (SELECT c.name FROM sys.columns AS c JOIN sys.types AS t ON c.user_type_id=t.user_type_id WHERE c.object_id = OBJECT_ID(''Ranking'') AND c.name=''qualifying_score'')
BEGIN
BEGIN TRANSACTION
	ALTER TABLE dbo.Ranking ADD
		qualifying_score decimal(18, 2) NULL,
		ranking_score decimal(18, 2) NULL,
		ranking int NULL,
		disqualified int NULL
	ALTER TABLE dbo.Ranking
		DROP COLUMN points, avg_score
COMMIT TRANSACTION 
END

' 
END;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FIRSTEvent]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[FIRSTEvent](
	[EventID] [int] NOT NULL,
	[Description] [varchar](255) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Location] [varchar](255) NULL,
	[Venue] [varchar](255) NULL,
	[VenueURL] [varchar](255) NULL,
	[EventCode] [varchar](255) NULL,
	[Active] [bit] NULL CONSTRAINT [DF_event_info_active]  DEFAULT ((0)),
	[TeamListURL] [varchar](255) NULL,
 CONSTRAINT [PK_event_info] PRIMARY KEY CLUSTERED 
(
	[EventID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TeamRanking]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[TeamRanking](
	[TeamID] [int] NOT NULL,
	[Wins] [int] NULL,
	[Losses] [int] NULL,
	[Ties] [int] NULL,
	[MaxPoint] [int] NULL,
	[MatchesPlayed] [int] NULL,
	[QualifyingScore] [decimal](18, 2) NULL,
	[RankingScore] [decimal](18, 2) NULL,
	[Ranking] [int] NULL,
	[Disqualified] [int] NULL,
 CONSTRAINT [PK_Ranking] PRIMARY KEY CLUSTERED 
(
	[TeamID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TournamentDefault]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[TournamentDefault](
	[TournamentDefaultID] [int] NOT NULL,
	[TournamentLevel] [int] NOT NULL,
	[AutoTime] [int] NULL,
	[ManualTime] [int] NULL,
	[StartTime] [datetime] NOT NULL,
	[EndTime] [datetime] NOT NULL,
	[MatchesPerTeam] [int] NULL,
	[MinTimeBetweenMatches] [datetime] NULL,
	[TimeBetweenMatchStarts] [datetime] NULL,
	[DayNumber] [int] NOT NULL,
	[Description] [varchar](50) NOT NULL,
	[TournamentDefaultCode] [char](10) NOT NULL,
 CONSTRAINT [PK_TournamentDefault] PRIMARY KEY CLUSTERED 
(
	[TournamentDefaultID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Award]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Award](
	[AwardID] [int] NOT NULL,
	[TeamID] [int] NULL,
	[TeamName] [varchar](100) NULL,
	[Description] [varchar](200) NOT NULL,
	[OrderNumber] [int] NULL,
	[Grouping] [char](10) NULL,
 CONSTRAINT [PK_Award] PRIMARY KEY CLUSTERED 
(
	[AwardID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Alliance]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Alliance](
	[AllianceID] [int] NOT NULL,
	[Captain] [varchar](50) NULL,
	[FirstRoundTeamID] [int] NULL,
	[SecondRoundTeamID] [int] NULL,
	[AlternateTeamID] [int] NULL,
 CONSTRAINT [PK_Alliances] PRIMARY KEY CLUSTERED 
(
	[AllianceID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Match]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Match](
	[MatchID] [int] NOT NULL,
	[EventID] [int] NOT NULL,
	[ScheduleID] [int] NULL,
	[TournamentLevel] [int] NOT NULL,
	[MatchStatus] [char](15) NOT NULL,
	[RedTeam1ID] [int] NULL,
	[RedTeam1Ready] [bit] NULL,
	[RedTeam1Bypass] [bit] NULL,
	[RedTeam1Disable] [bit] NULL,
	[RedTeam2ID] [int] NULL,
	[RedTeam2Ready] [bit] NULL,
	[RedTeam2Bypass] [bit] NULL,
	[RedTeam2Disable] [bit] NULL,
	[RedTeam3ID] [int] NULL,
	[RedTeam3Ready] [bit] NULL,
	[RedTeam3Bypass] [bit] NULL,
	[RedTeam3Disable] [bit] NULL,
	[BlueTeam1ID] [int] NULL,
	[BlueTeam1Ready] [bit] NULL,
	[BlueTeam1Bypass] [bit] NULL,
	[BlueTeam1Disable] [bit] NULL,
	[BlueTeam2ID] [int] NULL,
	[BlueTeam2Ready] [bit] NULL,
	[BlueTeam2Bypass] [bit] NULL,
	[BlueTeam2Disable] [bit] NULL,
	[BlueTeam3ID] [int] NULL,
	[BlueTeam3Ready] [bit] NULL,
	[BlueTeam3Bypass] [bit] NULL,
	[BlueTeam3Disable] [bit] NULL,
	[RedScore] [int] NULL,
	[BlueScore] [int] NULL,
	[AutoWinner] [char](10) NULL,
	[Winner] [char](10) NULL,
 CONSTRAINT [PK_Match] PRIMARY KEY CLUSTERED 
(
	[MatchID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Team]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Team](
	[TeamID] [int] NOT NULL,
	[TeamDetail] [ntext] NULL,
	[ShortName] [varchar](100) NULL,
	[NickName] [varchar](64) NULL,
	[RobotName] [varchar](64) NULL,
	[Location] [varchar](100) NULL,
	[RookieYear] [int] NULL,
	[TeamName] [varchar](256) NULL,
 CONSTRAINT [PK_team_info] PRIMARY KEY CLUSTERED 
(
	[TeamID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FIRSTEventParticipant]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[FIRSTEventParticipant](
	[TeamID] [int] NOT NULL,
	[EventID] [int] NOT NULL,
	[ParticipantID] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_FIRSTEventParticipant] PRIMARY KEY CLUSTERED 
(
	[ParticipantID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DBVersion]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DBVersion](
	[VersionID] [int] IDENTITY(1,1) NOT NULL,
	[AuditTimeStamp] [datetime] NOT NULL,
	[Script] [varchar](500) NOT NULL,
	[IsLatest] [bit] NOT NULL CONSTRAINT [DF_Version_IsLatest]  DEFAULT ((0)),
	[CausedErrors] [bit] NOT NULL CONSTRAINT [DF_Version_HasErrors]  DEFAULT ((0)),
	[Major] [int] NOT NULL,
	[Minor] [int] NOT NULL,
	[Build] [int] NOT NULL,
	[Revision] [int] NOT NULL,
	[ScriptType] [int] NOT NULL,
	[ErrorMessage] [ntext] NULL,
 CONSTRAINT [PK_Version] PRIMARY KEY CLUSTERED 
(
	[VersionID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[ViewRegisteredTeam]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[ViewRegisteredTeam]
AS
SELECT     dbo.Team.TeamID, dbo.Team.TeamDetail, dbo.Team.ShortName, dbo.Team.NickName, dbo.Team.RobotName, dbo.Team.Location, 
                      dbo.Team.RookieYear, dbo.FIRSTEventParticipant.EventID, dbo.FIRSTEventParticipant.ParticipantID, dbo.Team.TeamName
FROM         dbo.Team INNER JOIN
                      dbo.FIRSTEventParticipant ON dbo.Team.TeamID = dbo.FIRSTEventParticipant.TeamID
'; 

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Team"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 216
               Right = 189
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "FIRSTEventParticipant"
            Begin Extent = 
               Top = 6
               Left = 227
               Bottom = 155
               Right = 378
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' ,@level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'VIEW', @level1name=N'ViewRegisteredTeam';

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 ,@level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'VIEW', @level1name=N'ViewRegisteredTeam';

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ClearFIRSTEventParticipant]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ClearFIRSTEventParticipant] 
	-- Add the parameters for the stored procedure here
	@EventID int 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DELETE FROM FIRSTEventParticipant WHERE EventID = @EventID;
END
' 
END;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ClearFIRSTEventActiveFlag]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ClearFIRSTEventActiveFlag] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE FIRSTEvent SET Active=0;
END
' 
END;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ClearAwards]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ClearAwards] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DELETE FROM award;
END

' 
END;

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ClearIsLatestFlags]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ClearIsLatestFlags] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE DBVersion SET IsLatest=0;
END
' 
END;
