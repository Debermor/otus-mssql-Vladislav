/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

create function sales.fn_GetCustoemr ()
returns table 
as 
return
(
	select top 1 
		 c.CustomerID
		,c.CustomerName
		,sum(il.quantity * il.unitprice) as Purchase_Amount
	from sales.Customers as c
	inner join sales.invoices as i on i.CustomerID = c.CustomerID
	inner join sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
	group by 
		 c.CustomerID
		, c.CustomerName
		, il.InvoiceID -- тут не уверен, суммой всех покупок или в рамках 1 инвойса, если всех то строчку можно убрать или закоментировать. 
	order by sum(il.quantity * il.unitprice) desc
)

select * from sales.fn_GetCustoemr()


/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

create procedure sales.sp_getcustomertotal (
    @customerid int
)
as
begin
    select  c.customerid
           ,c.customername
           ,sum(il.quantity * il.unitprice) as TotalAmount
    from sales.customers as c
    inner join sales.invoices as i on c.customerid = i.customerid
    inner join sales.invoicelines as il on i.invoiceid = il.invoiceid
    where c.customerid = @customerid
    group by c.customerid, c.customername;
end;

exec sales.sp_getcustomertotal @customerid = 834


/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

create function sales.fn_getcustomertotal(@customerid int)
returns table
as
return
(
    select  c.customerid
           ,c.customername
           ,sum(il.quantity * il.unitprice) as TotalAmount
    from sales.customers as c
    inner join sales.invoices as i on c.customerid = i.customerid
    inner join sales.invoicelines as il on i.invoiceid = il.invoiceid
    where c.customerid = @customerid
    group by c.customerid, c.customername
)

select * from sales.fn_getcustomertotal(834) -- можно встроить в запрос
/* Например:
	select i.* 
	from sales.fn_getcustomertotal(834) as f
	inner join sales.invoices as i on i.CustomerID = f.CustomerID
*/
exec sales.sp_getcustomertotal @customerid = 834 -- выполняется отдельно 


/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

create or alter function sales.fn_getcustomer_Max_OrderDate(@customerid int)
returns table
as
return
(
    select 
		 c.customerid
		,max(i.InvoiceDate) as Max_OrderDate
    from sales.customers as c
    inner join sales.invoices as i on c.customerid = i.customerid
    where c.customerid = @customerid
    group by c.customerid
)

select t.*,c.*
from sales.customers as c
cross apply sales.fn_getcustomer_Max_OrderDate(c.CustomerID) as t

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
