insert into Notification_User (User_Name,User_Email)
values ('Vladislav Borodulin','debnipts@gmail.com')

insert into Notification_Role (Role_Name)
values ('Admin')

insert into Notification_Object (Object_Name)
values ('None')

insert into Notofication_Body (Body_Text)
values ('None')

insert into Notofication_Subject (Subject_Text)
values ('None')

insert into Notification (Notification,Notification_Variant,Notifaction_Description,ID_Notification_Object,ID_Notofication_Subject,ID_Notofication_Body)
values ('Test_Notification',1,'Тестовая нотификация',1,1,1)

insert into Notification_Recipient (ID_Notification,ID_Notification_Role)
values (1,1)

insert into Notification_User_Role (Id_Notification_Role,Id_Notification_User)
values (1,1)

select nus.*
from Notification_Recipient			as nre
inner join Notification_Role		as nro on nro.id = nre.ID_Notification_Role
inner join Notification_User_Role	as nur on nur.Id_Notification_Role = nro.ID
inner join Notification_User		as nus on nus.id = nur.Id_Notification_User
where nus.User_Name = 'Vladislav Borodulin'