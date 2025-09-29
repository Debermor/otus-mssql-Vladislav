USE [Notification_Project]
GO

/****** Object:  StoredProcedure [dbo].[sp_Send_Notificaion]    Script Date: 29.09.2025 13:48:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/*
	Процедура формирования письма и его отправки
*/


-- exec sp_Send_Notificaion  @xNotification = 'DailyUpdate',@xNotification_Variant = 1
CREATE procedure [dbo].[sp_Send_Notificaion] (@xNotification varchar(50), @xNotification_Variant int)
as
declare  @Xrecipients       nvarchar(max)	= N''
		,@Xcopy_recipients  nvarchar(max)	= N''
		,@Xbody             nvarchar(max)   = ''
		,@Xsubject          nvarchar(255)   = ''
		,@Xbody_format      varchar(20)     = N'HTML'
		,@sql				nvarchar(max)
declare @html_out			nvarchar(max)	= N''

begin
-- 1. Получатели
;with cte_User_Email as (
	select u.User_Email
	from [dbo].[Notification] as n
	inner join [dbo].[Notification_Recipient] as nr on nr.ID_Notification = n.ID
	inner join [dbo].[Notification_Role] as r on r.id = nr.ID_Notification_Role
	inner join [dbo].[Notification_User_Role] as ur on ur.Id_Notification_Role = r.ID
	inner join [dbo].[Notification_User] as u on u.id = ur.Id_Notification_User and u.User_Email_ActiveFlag = 1
	where n.Notification = @xNotification and n.Notification_Variant = @xNotification_Variant

	union  

	select u.User_Email
	from [dbo].[Notification] as n
	inner join [dbo].[Notification_Recipient] as nr on nr.ID_Notification = n.ID
	inner join [dbo].[Notification_User] as u on u.id = nr.Id_Notification_User and u.User_Email_ActiveFlag = 1
	where n.Notification = @xNotification and n.Notification_Variant = @xNotification_Variant
)
select @Xrecipients = @Xrecipients + case when @Xrecipients = '' then u.User_Email + ';' else ' ' + u.User_Email + ';' end
from cte_User_Email as u 

-- 2. Тема письма
select @sql = s.Subject_Text 
from [dbo].[Notification] as n
inner join [dbo].[notification_Subject] as s on s.ID = n.ID_notification_Subject
where n.Notification = @xNotification and n.Notification_Variant = @xNotification_Variant


exec sp_executesql @sql, N'@XSubjectOut nvarchar(max) OUTPUT', @XSubjectOut=@XSubject output;


-- 3. Тело письма
drop table if exists ##tmp_object 

-- 3.1 Если есть в письме есть таблица
SELECT @sql = o.Object_Text 
from [dbo].[Notification] as n
inner join dbo.Notification_Object as o on o.ID = n.ID_Notification_Object
where n.Notification = @xNotification and n.Notification_Variant = @xNotification_Variant

exec sp_executesql @sql

-- Получаем стили
exec dbo.sp_genHTMLTable                                               
        @db_name    = 'tempdb', 
        @db_schema  = 'dbo', 
        @table_name = '##tmp_object', 
        @html_table = @html_out output

-- 3.2 Заполняем тело сообщения 
SELECT @sql = b.Body_Text 
from [dbo].[Notification] as n
inner join dbo.notification_Body as b on b.ID = n.ID_notification_Body
where n.Notification = @xNotification and n.Notification_Variant = @xNotification_Variant

exec sp_executesql @sql, N'@XbodyOut nvarchar(max) output, @html_out nvarchar(max)', @XbodyOut=@Xbody output,@html_out = @html_out;

drop table if exists ##tmp_object 

exec msdb.dbo.sp_send_dbmail
         @recipients = @Xrecipients
        ,@copy_recipients = @Xcopy_recipients
        ,@body = @Xbody
        ,@subject = @Xsubject
		,@body_format  = @Xbody_format

insert into Notification_log (ID_Notification,ID_Notification_Body,ID_Notification_User,Notification_DateTime)
select 
	 n.id
	,b.ID
	,u.id
	,getdate()
from Notification as n
inner join dbo.Notification_Recipient as nr on nr.ID_Notification = n.ID
inner join dbo.Notification_Role as r on r.id = nr.ID_Notification_Role
inner join dbo.Notification_User_Role as ur on ur.Id_Notification_Role = r.ID
inner join dbo.Notification_User as u on u.id = ur.Id_Notification_User and u.User_Email_ActiveFlag = 1
inner join dbo.notification_Body as b on b.ID = n.ID_notification_Body
where n.Notification = @xNotification and n.Notification_Variant = @xNotification_Variant

end

GO


