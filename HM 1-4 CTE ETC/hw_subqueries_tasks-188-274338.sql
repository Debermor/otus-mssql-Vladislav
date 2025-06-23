/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------


/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/
with cte_Invoices as (
select * 
from sales.Invoices 
where InvoiceDate = '2015-07-04'
)
select * 
from Application.People	 as p
left join cte_Invoices as i on i.SalespersonPersonID = p.PersonID
where IsSalesperson = 1 and i.InvoiceID is null


select 
	 PersonID
	,SearchName
from Application.People	 as p
left join (
	select * 
	from sales.Invoices 
	where InvoiceDate = '2015-07-04'
) as i on i.SalespersonPersonID = p.PersonID
where IsSalesperson = 1 and i.InvoiceID is null


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

select 
	 StockItemID
	,StockItemName
	,UnitPrice
from Warehouse.StockItems
where UnitPrice = (select min(UnitPrice) from Warehouse.StockItems)

select top 1 WITH TIES 
	 StockItemID
	,StockItemName
	,UnitPrice
from(	select 
			 StockItemID
			,StockItemName
			,min(UnitPrice) as UnitPrice
		from Warehouse.StockItems
		group by 
			 StockItemID
			,StockItemName
		) as si
order by UnitPrice asc


/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/


;with cte_CustomerTransactions as (
	select 
		 * 
		,rank()	over (order by TransactionAmount desc) as amount
	from Sales.CustomerTransactions
)
select  
	 CustomerName
	,PhoneNumber
	,count(TransactionAmount) as Max_Payments
from cte_CustomerTransactions	as ct
inner join sales.Customers		as c on c.CustomerID = ct.CustomerID
where amount <= 5
group by 
	 CustomerName
	,PhoneNumber

select distinct
	 ct.CustomerName
	,ct.PhoneNumber
from sales.Customers	 as ct
inner join (
	select top 5 WITH TIES 
		* 
	from Sales.CustomerTransactions
	order by TransactionAmount desc
) as hz on hz.CustomerID = ct.CustomerID

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

;with cte_top3_price as (
select distinct top 3 with ties
	StockItemID,UnitPrice
from [Sales].[InvoiceLines]
order by UnitPrice desc
)
select 
	 sc.DeliveryCityID
	,ac.CityName
	,p.FullName as PackedBy
from [Sales].[InvoiceLines]			as il
inner join cte_top3_price			as t3p on t3p.StockItemID = il.StockItemID
inner join [Sales].[Invoices]		as i on i.InvoiceID = il.InvoiceID
inner join [Application].[People]	as p on p.PersonID = i.PackedByPersonID
inner join [Sales].[Customers]		as sc on sc.CustomerID = i.CustomerID
inner join [Application].[Cities]	as ac on ac.CityID = sc.DeliveryCityID


-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
