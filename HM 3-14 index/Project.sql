/*
Тема:
«Система управления уведомлениями для пользователей»

Проблема:
По всей DB и Job'ах находятся вызовы exec msdb.dbo.sp_send_dbmail с параметрами указанными "хардкодом". При изменениях в параметрах нотификации, необходимо вносить изменения в код процедур. Клиент хочет управлять этим на своей стороне. 


Решение:
Создание процедуры со входящими параметрами "Имя нотификации" и "Вариация нотификации", которая сформирует письмо, получателей и отправит его на почту. 
	Создание структуры для работы процедуры. 

P.S. 
	У клиента уже имется внешний интерфейс для взаимодействия с таблицами (не в рамках проекта)

P.S. Коментарий Людмилы
"Добрый день. Да, вашу задачу можно оформить в выпускной проект.  Схема + процедура + возможно показать результат работы 1 хп или джоба."
*/




/*
1. Пользователи
- Имя пользователя
- Его Email
- Флаг активности записи
*/
create table Notification_User (
    ID int identity primary key,
    User_Name varchar(100) not null,
    User_Email varchar(150) not null,
    User_Email_ActiveFlag bit not null default(1)
);

/*
2. Роли
Роли позволяют группировать пользователей для рассылки
*/
create table Notification_Role (
    ID int identity primary key,
    Role_Name varchar(50) not null
);

/*
3. Объекты уведомлений
- Имя обьекта 
- Идентификатор объекта в БД (если имеется)
*/
create table Notification_Object (
    ID int identity primary key,
    Object_Name varchar(100) not null,
    Object_DB_ID int null
);

/*
4. Тексты тела писем
- SQL-шаблон, генерирующий текст тела письма
*/

create table Notofication_Body (
    ID int identity primary key,
    Body_Text nvarchar(2500) not null
);

/*
5. Заголовок письма
- SQL-шаблон, генерирующий заголовок письма
*/

create table Notofication_Subject (
    ID int identity primary key,
    Subject_Text Nvarchar(2500) not null
);

/*
6. Уведомления
- Название нотификации
- Вариация нотификации 
- Описание нотификации
*/
create table Notification (
    ID int identity primary key,
    Notification varchar(50) not null,
    Notification_Variant int not null default(1),
    Notifaction_Description varchar(500) null,
    ID_Notification_Object int null,
    ID_Notofication_Subject int null,
    ID_Notofication_Body int null,
    constraint FK_Notification_Object foreign key (ID_Notification_Object) 
        references Notification_Object(ID),
    constraint FK_Notification_Subject foreign key (ID_Notofication_Subject) 
        references Notofication_Subject(ID),
    constraint FK_Notification_Body foreign key (ID_Notofication_Body) 
        references Notofication_Body(ID)
);

/*
7. Связь получателей и уведомлений
Логика должна поддерживать как рассылку по роли пользователя, так и отправку определенному пользователю.
*/

create table Notification_Recipient (
    ID int identity primary key,
    ID_Notification int not null,
    ID_Notification_Role int null,
    ID_Notification_User int null,
    constraint FK_Recipient_Notification foreign key (ID_Notification) 
        references Notification(ID),
    constraint FK_Recipient_Role foreign key (ID_Notification_Role) 
        references Notification_Role(ID),
    constraint FK_Recipient_User foreign key (ID_Notification_User) 
        references Notification_User(ID)
);

/*
8. Связь пользователи ↔ роли
*/
create table Notification_User_Role (
    ID int identity primary key,
    Id_Notification_Role int not null,
    Id_Notification_User int not null,
    constraint FK_UserRole_Role foreign key (Id_Notification_Role) 
        references Notification_Role(ID),
    constraint FK_UserRole_User foreign key (Id_Notification_User) 
        references Notification_User(ID)
);
