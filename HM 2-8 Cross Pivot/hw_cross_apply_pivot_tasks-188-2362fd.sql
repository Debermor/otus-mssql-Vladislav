/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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

USE OTUS_WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

;with cte_prep as (
select
	substring(
		CustomerName,
		charindex('(', CustomerName) + 1,
		charindex(')', CustomerName) - charindex('(', CustomerName) - 1
	) AS [Address]
	,InvoiceID
	,format(datefromparts(year(InvoiceDate), month(InvoiceDate), 1), 'dd.MM.yyyy') as InvoiceMonth
from Sales.Customers as c
inner join Sales.Invoices as i on i.CustomerID = c.CustomerID
where c.CustomerID between 2 and 6
),  cte_agr as(
select
	 [Address]
	,cast(InvoiceMonth as date) as InvoiceMonth
	,count(InvoiceID) as InvoiceCount
from cte_prep
group by [Address],InvoiceMonth
)
select *
from cte_agr
pivot (
    sum(InvoiceCount)
    for [Address] IN (
		[Peeples Valley, AZ],
		[Medicine Lodge, KS],
		[Gasport, NY],
		[Sylvanite, MT],
		[Jessie, ND]
    )
) as PivotResult
order by year(InvoiceMonth),month(InvoiceMonth);

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select
     c.CustomerName
	,AddressLine
from Sales.Customers as c
cross apply (
	values
		(DeliveryAddressLine1),
		(DeliveryAddressLine2),
		(PostalAddressLine1),
		(PostalAddressLine2)
) as  Addresses(AddressLine)
where CustomerName like '%Tailspin Toys%'

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так,
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select
	 CountryID
	,CountryName
	,Code
from Application.Countries
cross apply (
	values
		(cast(IsoAlpha3Code  as varchar(20))),
		(cast(IsoNumericCode as varchar(20)))
) as Codes(Code)

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

-- Не совсем понял задание, вот 2 варианта решения.
select
	c.CustomerID,
	c.CustomerName,
	TopPrice.StockItemID,
	TopPrice.UnitPrice,
	TopPrice.InvoiceDate
from Sales.Customers c
cross apply(
	select top 2
		il.StockItemID,
		il.UnitPrice,
		i.InvoiceDate
	from Sales.Invoices as i
	join Sales.InvoiceLines as il on i.InvoiceID = il.InvoiceID
	where i.CustomerID = c.CustomerID
	order by il.UnitPrice desc
) as TopPrice
order by c.CustomerID, TopPrice.UnitPrice desc, InvoiceDate;

;with Ranked_Items as (
	select
		c.CustomerID,
		c.CustomerName,
		il.StockItemID,
		il.UnitPrice,
		i.InvoiceDate,
		ROW_NUMBER() over (
		 	partition by c.CustomerID, il.StockItemID
		 	order by il.UnitPrice desc
		) as rn
	from Sales.Customers c
	join Sales.Invoices i on i.CustomerID = c.CustomerID
	join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
)
, cte_top_item as(
	select
		*
		,ROW_NUMBER() over (
			partition by CustomerID
			order by UnitPrice desc
		) as Distinct_items
	from Ranked_Items
	where rn = 1
)
select
	CustomerID,
	CustomerName,
	StockItemID,
	UnitPrice,
	InvoiceDate
from cte_top_item
where Distinct_items <= 2
order by CustomerID, UnitPrice desc;
