/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

USE otus_WideWorldImporters

/*

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

declare @SQL nvarchar(max);
declare @People nvarchar(max) = N'';

-- формируем список клиентов для столбцов
select @People = @People + N',' + quotename(customername) 
from (select distinct customername from sales.customers) as cust
order by customername;

set @people = stuff(@People, 1, 1, N'');

set @sql = N'
select 
    format(invoicemonth, ''dd.MM.yyyy'') as invoicemonth, 
    ' + @People + '
from 
(
    select 
        datefromparts(year(i.invoicedate), month(i.invoicedate), 1) as invoicemonth,
        c.customername,
        count(*) as purchasecount
    from sales.invoices as i
    inner join sales.customers as c on i.customerid = c.customerid
    group by datefromparts(year(i.invoicedate), month(i.invoicedate), 1), c.customername
) as sourcetable
pivot
(
    sum(purchasecount)
    for customername in (' + @People + ')
) as pivottable
order by  year(InvoiceMonth),month(InvoiceMonth)';

-- выполняем динамический sql
exec sp_executesql @sql;