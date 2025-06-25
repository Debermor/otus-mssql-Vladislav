/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
	 sales_year		= year(i.InvoiceDate)
	,sales_month	= month(i.InvoiceDate)
	,sales_avg		= avg(il.UnitPrice)
	,sales_sum		= sum(il.Quantity * il.UnitPrice) 
from Sales.Invoices as i
left join sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
group by year(i.InvoiceDate),month(i.InvoiceDate)



/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
	 sales_year		= year(i.InvoiceDate)
	,sales_month	= month(i.InvoiceDate)
	,sales_sum		= sum(il.Quantity * il.UnitPrice)
from Sales.Invoices as i
left join sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
group by year(i.InvoiceDate),month(i.InvoiceDate)
having cast(sum(il.Quantity * il.UnitPrice) as int) > 4600000

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
	 sales_year		= year(i.InvoiceDate)
	,sales_month	= month(i.InvoiceDate)
	,Item_Name		= si.StockItemName
	,sales_sum		= sum(il.Quantity * il.UnitPrice)
	,first_sale		= min(InvoiceDate)
	,sales_amount	= sum(i.totaldryitems)
from Sales.Invoices as i
left join [Sales].Orderlines				as ol on ol.OrderID = i.OrderID
left join Warehouse.StockItems				as si on si.StockItemID = ol.StockItemID
left join sales.InvoiceLines				as il on il.InvoiceID = i.InvoiceID
group by 
	 year(i.InvoiceDate)
	,month(i.InvoiceDate)
	,si.StockItemName
having sum(i.totaldryitems) < 50


-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
