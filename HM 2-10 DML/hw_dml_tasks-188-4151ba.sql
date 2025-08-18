/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

select * from [Sales].[Customers]

insert into [Sales].[Customers](
	 CustomerName
	,BillToCustomerID
	,CustomerCategoryID
	,BuyingGroupID
	,PrimaryContactPersonID
	,AlternateContactPersonID
	,DeliveryMethodID
	,DeliveryCityID
	,PostalCityID
	,CreditLimit
	,AccountOpenedDate
	,StandardDiscountPercentage
	,IsStatementSent
	,IsOnCreditHold
	,PaymentDays
	,PhoneNumber
	,FaxNumber
	,DeliveryRun
	,RunPosition
	,WebsiteURL
	,DeliveryAddressLine1
	,DeliveryAddressLine2
	,DeliveryPostalCode
	,DeliveryLocation
	,PostalAddressLine1
	,PostalAddressLine2
	,PostalPostalCode
	,LastEditedBy
)
values 
	 (N'Agrita Abele1', 1061,5, NULL, 3261,NULL,3,19881, 19881,1600.00, '2016-05-07',0.000, 0, 0, 7, N'(206) 555-0100', N'(206) 555-0101',NULL, NULL, N'http://www.microsoft.com/',N'Shop 12',N'652 Victoria Lane',N'90243', 0xE6100000010C11154FE2182D4740159ADA087A035FC0, N'PO Box 8112',N'Milicaville', N'90243',1	)
	,(N'Agrita Abele2', 1061,5, NULL, 3261,NULL,3,19881, 19881,1600.00, '2016-05-07',0.000, 0, 0, 7, N'(206) 555-0100', N'(206) 555-0101',NULL, NULL, N'http://www.microsoft.com/',N'Shop 12',N'652 Victoria Lane',N'90243', 0xE6100000010C11154FE2182D4740159ADA087A035FC0, N'PO Box 8112',N'Milicaville', N'90243',1	)
	,(N'Agrita Abele3', 1061,5, NULL, 3261,NULL,3,19881, 19881,1600.00, '2016-05-07',0.000, 0, 0, 7, N'(206) 555-0100', N'(206) 555-0101',NULL, NULL, N'http://www.microsoft.com/',N'Shop 12',N'652 Victoria Lane',N'90243', 0xE6100000010C11154FE2182D4740159ADA087A035FC0, N'PO Box 8112',N'Milicaville', N'90243',1	)
	,(N'Agrita Abele4', 1061,5, NULL, 3261,NULL,3,19881, 19881,1600.00, '2016-05-07',0.000, 0, 0, 7, N'(206) 555-0100', N'(206) 555-0101',NULL, NULL, N'http://www.microsoft.com/',N'Shop 12',N'652 Victoria Lane',N'90243', 0xE6100000010C11154FE2182D4740159ADA087A035FC0, N'PO Box 8112',N'Milicaville', N'90243',1	)
	,(N'Agrita Abele5', 1061,5, NULL, 3261,NULL,3,19881, 19881,1600.00, '2016-05-07',0.000, 0, 0, 7, N'(206) 555-0100', N'(206) 555-0101',NULL, NULL, N'http://www.microsoft.com/',N'Shop 12',N'652 Victoria Lane',N'90243', 0xE6100000010C11154FE2182D4740159ADA087A035FC0, N'PO Box 8112',N'Milicaville', N'90243',1	)

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

delete [Sales].[Customers]
where CustomerName = 'Agrita Abele1'


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

update t 
	set CustomerName = 'Agrita Abele55'
from [Sales].[Customers] as t
where CustomerName = 'Agrita Abele5'

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

merge [Sales].[Customers] AS t
using (
    select 
		 N'Agrita Abele5' as CustomerName
		,BillToCustomerID
		,CustomerCategoryID
		,BuyingGroupID
		,PrimaryContactPersonID
		,AlternateContactPersonID
		,DeliveryMethodID
		,DeliveryCityID
		,PostalCityID
		,CreditLimit
		,AccountOpenedDate
		,StandardDiscountPercentage
		,IsStatementSent
		,IsOnCreditHold
		,PaymentDays
		,PhoneNumber
		,FaxNumber
		,DeliveryRun
		,RunPosition
		,WebsiteURL
		,DeliveryAddressLine1
		,DeliveryAddressLine2
		,DeliveryPostalCode
		,DeliveryLocation
		,PostalAddressLine1
		,PostalAddressLine2
		,PostalPostalCode
		,LastEditedBy
    from [Sales].[Customers] AS s
	where CustomerName = 'Agrita Abele55'
) as s on (t.CustomerName = s.CustomerName)
when not matched by target 
    then insert 
		( CustomerName
		 ,BillToCustomerID
		 ,CustomerCategoryID
		 ,BuyingGroupID
		 ,PrimaryContactPersonID
		 ,AlternateContactPersonID
		 ,DeliveryMethodID
		 ,DeliveryCityID
		 ,PostalCityID
		 ,CreditLimit
		 ,AccountOpenedDate
		 ,StandardDiscountPercentage
		 ,IsStatementSent
		 ,IsOnCreditHold
		 ,PaymentDays
		 ,PhoneNumber
		 ,FaxNumber
		 ,DeliveryRun
		 ,RunPosition
		 ,WebsiteURL
		 ,DeliveryAddressLine1
		 ,DeliveryAddressLine2
		 ,DeliveryPostalCode
		 ,DeliveryLocation
		 ,PostalAddressLine1
		 ,PostalAddressLine2
		 ,PostalPostalCode
		 ,LastEditedBy
		)
	values
		( s.CustomerName
		 ,s.BillToCustomerID
		 ,s.CustomerCategoryID
		 ,s.BuyingGroupID
		 ,s.PrimaryContactPersonID
		 ,s.AlternateContactPersonID
		 ,s.DeliveryMethodID
		 ,s.DeliveryCityID
		 ,s.PostalCityID
		 ,s.CreditLimit
		 ,s.AccountOpenedDate
		 ,s.StandardDiscountPercentage
		 ,s.IsStatementSent
		 ,s.IsOnCreditHold
		 ,s.PaymentDays
		 ,s.PhoneNumber
		 ,s.FaxNumber
		 ,s.DeliveryRun
		 ,s.RunPosition
		 ,s.WebsiteURL
		 ,s.DeliveryAddressLine1
		 ,s.DeliveryAddressLine2
		 ,s.DeliveryPostalCode
		 ,s.DeliveryLocation
		 ,s.PostalAddressLine1
		 ,s.PostalAddressLine2
		 ,s.PostalPostalCode
		 ,s.LastEditedBy
		)
when matched
	then update 
		set 						   	
		  t.CustomerName			   	= s.CustomerName
		 ,t.BillToCustomerID		   	= s.BillToCustomerID
		 ,t.CustomerCategoryID		   	= s.CustomerCategoryID
		 ,t.BuyingGroupID			   	= s.BuyingGroupID
		 ,t.PrimaryContactPersonID	   	= s.PrimaryContactPersonID
		 ,t.AlternateContactPersonID   	= s.AlternateContactPersonID
		 ,t.DeliveryMethodID		   	= s.DeliveryMethodID
		 ,t.DeliveryCityID			   	= s.DeliveryCityID
		 ,t.PostalCityID			   	= s.PostalCityID
		 ,t.CreditLimit				   	= s.CreditLimit
		 ,t.AccountOpenedDate		   	= s.AccountOpenedDate
		 ,t.StandardDiscountPercentage 	= s.StandardDiscountPercentage
		 ,t.IsStatementSent				= s.IsStatementSent
		 ,t.IsOnCreditHold				= s.IsOnCreditHold
		 ,t.PaymentDays					= s.PaymentDays
		 ,t.PhoneNumber					= s.PhoneNumber
		 ,t.FaxNumber					= s.FaxNumber
		 ,t.DeliveryRun					= s.DeliveryRun
		 ,t.RunPosition					= s.RunPosition
		 ,t.WebsiteURL					= s.WebsiteURL
		 ,t.DeliveryAddressLine1		= s.DeliveryAddressLine1
		 ,t.DeliveryAddressLine2		= s.DeliveryAddressLine2
		 ,t.DeliveryPostalCode			= s.DeliveryPostalCode
		 ,t.DeliveryLocation			= s.DeliveryLocation
		 ,t.PostalAddressLine1			= s.PostalAddressLine1
		 ,t.PostalAddressLine2			= s.PostalAddressLine2
		 ,t.PostalPostalCode			= s.PostalPostalCode
		 ,t.LastEditedBy				= s.LastEditedBy
;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

-- bcp "OTUS_WideWorldImporters.Sales.Customers" out "D:\Git\github\Otus\otus-mssql-Vladislav\bcp\Customers.dat" -N -T -S localhost

-- create schema Archive

-- select top 0 *
-- into Archive.Customers
-- from Sales.Customers;

bulk insert archive.Customers
from 'D:\Git\github\Otus\otus-mssql-Vladislav\bcp\Customers.txt'
with
(
    datafiletype = 'char',
    fieldterminator = '|',
    rowterminator = '\n',
    keepnulls,
    tablock
);

