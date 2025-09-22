create function [dbo].SplitStringCLR(@text [nvarchar](max), @delimiter [nchar](1))
returns table ( 
	part nvarchar(max),
	ID_ODER int
) with execute as caller 
as 
external name StringSplit.UserDefinedFunctions.SplitString

select part into #tmpIDs from SplitStringCLR('11,22,33,44', ',')
select * from #tmpIDs