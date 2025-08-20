/*
Первичные и внешние ключи были созданы ранее.
Для некоторых таблиц ранее были созданы default(1) значения
*/

-- Notification_User
-- Проверка Email
alter table Notification_User
add constraint CK_Notification_User_Email_Format
check (User_Email like '%@%.%');

-- Уникальный индекс по Email
create unique index UX_Notification_User_Email
on Notification_User (User_Email);

-- Notification_Role 
create unique index UX_Notification_Role_RoleName
on Notification_Role (Role_Name);

-- Notification_Object 
create unique index UX_Notification_Object_ObjectName
on Notification_Object (Object_Name);

-- Notification_Recipient 
create unique index UX_Notification_Recipient
on Notification_Recipient (ID_Notification, ID_Notification_User, ID_Notification_Role);

-- Notification 
create unique index UX_Notification_Name_Variant
on Notification (Notification, Notification_Variant);

-- Notification_User_Role
create unique index UX_Notification_User_Role
on Notification_User_Role (Id_Notification_Role, Id_Notification_User);
