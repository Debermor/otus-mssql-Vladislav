-- select * from vw_Notification_Log order by Notification_DateTime desc


/*
	Представление для получение логов по отправленым сообщениям, их получателям и времени отправки
*/
create view vw_Notification_Log as(
select 
	 n.Notification
	,nb.Body_Name
	,nu.User_Name
	,nu.User_Email
	,nl.Notification_DateTime
from [dbo].[Notification_log] as nl
inner join dbo.Notification as n on n.ID = nl.ID_Notification
inner join dbo.Notification_Body as nb on nb.ID = nl.ID_Notification_Body
inner join dbo.Notification_User as nu on nu.ID = nl.ID_Notification_User
)

