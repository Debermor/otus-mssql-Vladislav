/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE OTUS_WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select 
	 StockItemID
	,StockItemName
from Warehouse.StockItems
where StockItemName like '%urgent%' or StockItemName like 'Animal%' -- поправил

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select
	 s.SupplierID
	,s.SupplierName
from Purchasing.Suppliers as s
left join Purchasing.PurchaseOrders as po on po.SupplierID = s.SupplierID
where po.SupplierID is null -- Делал в разные дни, извиняюсь проморгал



/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

with cte_orders as (
select
	  o.OrderID
	 ,Order_Date	=	format(o.OrderDate, 'dd-MM-yyyy')
	 ,Order_Month	=	month(o.OrderDate)
	 ,Order_Quarter	=	datepart(quarter,o.OrderDate)
	 ,Trimester		=	case 
							when month(o.OrderDate) between 1 and 4 
								then 1
							when month(o.OrderDate) between 5 and 8 
								then 2
							when month(o.OrderDate) between 9 and 12
								then 3
						end
	,CustomerID
from Sales.Orders as o
)
select 
	 o.OrderID
	,Order_Date	
	,Order_Month	
	,Order_Quarter	
	,Trimester		
	,c.CustomerName
from cte_orders				as o
left join Sales.OrderLines	as ol on ol.OrderID = o.OrderID
left join Sales.Customers	as c on c.CustomerID = o.CustomerID
where ol.quantity > 20 
		or ( UnitPrice > 100  and PickingCompletedWhen is not null)
order by 
	 o.Order_Quarter
	,o.Trimester
	,o.Order_Date

-- C Постраничной разбивкой 
with cte_orders as (
select
	  o.OrderID
	 ,Order_Date	=	format(o.OrderDate, 'dd-MM-yyyy')
	 ,Order_Month	=	month(o.OrderDate)
	 ,Order_Quarter	=	datepart(quarter,o.OrderDate)
	 ,Trimester		=	case 
							when month(o.OrderDate) between 1 and 4 
								then 1
							when month(o.OrderDate) between 5 and 8 
								then 2
							when month(o.OrderDate) between 9 and 12
								then 3
						end
	,CustomerID
from Sales.Orders as o
)
select 
	 o.OrderID
	,Order_Date	
	,Order_Month	
	,Order_Quarter	
	,Trimester		
	,c.CustomerName
from cte_orders				as o
left join Sales.OrderLines	as ol on ol.OrderID = o.OrderID
left join Sales.Customers	as c on c.CustomerID = o.CustomerID
where ol.quantity > 20 
		or ( UnitPrice > 100  and PickingCompletedWhen is not null)
order by 
	 o.Order_Quarter
	,o.Trimester
	,o.Order_Date
offset 1000 rows
fetch next 100 row only

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select
	 dm.DeliveryMethodName
	,po.ExpectedDeliveryDate
	,s.SupplierName
	,p.FullName
from Purchasing.Suppliers				as s
inner join Purchasing.PurchaseOrders	as po on po.SupplierID = s.SupplierID 
												and po.ExpectedDeliveryDate >= '2013-01-01' and po.ExpectedDeliveryDate < '2013-02-01' -- поправил так (ещё вариант year(po.ExpectedDeliveryDate) = 2013 and month(po.ExpectedDeliveryDate) = 1)
												and IsOrderFinalized = 1
inner join Application.DeliveryMethods	as dm on dm.DeliveryMethodID = po.DeliveryMethodID
												and DeliveryMethodName in ('Air Freight','Refrigerated Air Freight')
inner join Application.People 			as p on p.PersonID = po.ContactPersonID


/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select top 10  -- или с with ties если нужны все пападающие под условие даты
	 o.OrderID
	,c.CustomerName
	,ContactEmployee = p.FullName
from Sales.Orders				as o
inner join sales.Customers		as c on c.CustomerID = o.CustomerID
inner join Application.People	as p on p.PersonID = o.SalespersonPersonID
order by o.orderdate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select top 10  
	 c.CustomerID
	,c.CustomerName
	,c.PhoneNumber
	--,si.StockItemName
from Sales.Orders							as o
inner join sales.Customers					as c	on c.CustomerID = o.CustomerID
inner join Sales.OrderLines					as ol	on ol.orderid = o.OrderID -- Поправил
inner join Warehouse.StockItems				as si	on si.StockItemID = ol.StockItemID 
														and StockItemName = 'Chocolate frogs 250g'

