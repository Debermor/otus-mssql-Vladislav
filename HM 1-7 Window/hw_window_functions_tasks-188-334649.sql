/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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

USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

with cte_sum_by_month as (
select 
  format(i.InvoiceDate, 'yyyyMM') as xmonth
 ,sum(ExtendedPrice) as sum_price
from [Sales].[Invoices] as i
inner join [Sales].[InvoiceLines] as il on il.InvoiceID = i.InvoiceID
where i.InvoiceDate >= '2015-01-01'
group by format(i.InvoiceDate, 'yyyyMM')
--order by format(i.InvoiceDate, 'yyyyMM')
),
cte_lag as (
select cte.xmonth, sum(cte2.sum_price) as month_by_month
from cte_sum_by_month as cte
inner join cte_sum_by_month as cte2 on cte2.xmonth <= cte.xmonth
group by cte.xmonth
)
select distinct
	 si.InvoiceID
	,CustomerName
	,si.InvoiceDate
	,sum(sil.ExtendedPrice) as ExtendedPrice
	,cte.month_by_month
from [Sales].[Invoices] as si 
inner join cte_lag as cte on cte.xmonth = format(si.InvoiceDate, 'yyyyMM')
inner join [Sales].[Customers] as sc on sc.CustomerID = si.CustomerID
inner join [Sales].[InvoiceLines] as sil on sil.InvoiceID = si.InvoiceID
group by 
	 si.InvoiceID
	,CustomerName
	,si.InvoiceDate
	,cte.month_by_month
order by si.InvoiceDate


/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

;with cte_price as (
select 
  format(i.InvoiceDate, 'yyyyMM') as xmonth
 ,sum(ExtendedPrice) as sum_price
from [Sales].[Invoices] as i
inner join [Sales].[InvoiceLines] as il on il.InvoiceID = i.InvoiceID
where i.InvoiceDate >= '2015-01-01'
group by format(i.InvoiceDate, 'yyyyMM')
)
,cte_price_by_month as (
select 
	 *	
	,sum(sum_price) over ( 
		order by xmonth
		rows between unbounded preceding and current row
	 )  as month_by_month
from cte_price
)

select distinct
	 si.InvoiceID
	,CustomerName
	,si.InvoiceDate
	,sum_price
	,month_by_month
from [Sales].[Invoices] as si 
inner join [Sales].[Customers] as sc on sc.CustomerID = si.CustomerID
inner join cte_price_by_month as sil on sil.xmonth = format(si.InvoiceDate, 'yyyyMM')
order by si.InvoiceDate


/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

;with cte_total_sales as ( 
select distinct
	 format(si.InvoiceDate, 'yyyyMM') as year_month
	,sum(sil.Quantity) as total_sales
	,sil.StockItemID
from [Sales].[Invoices] as si
inner join [Sales].[InvoiceLines]  as sil on sil.InvoiceID = si.InvoiceID
where year(si.InvoiceDate) = 2016
group by sil.StockItemID,format(si.InvoiceDate, 'yyyyMM')
)
,cte_rank as (
 select *
	,rank() over (partition by year_month order by total_sales desc) as popular_rank
 from cte_total_sales
)
select * 
from cte_rank 
where popular_rank < 3
order by year_month,popular_rank


/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select 
	 StockItemID
	,StockItemName
	,Brand
	,UnitPrice

	,count(StockItemID) over ()
	,* 
from [Warehouse].[StockItems]

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

напишите здесь свое решение

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

напишите здесь свое решение

Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 