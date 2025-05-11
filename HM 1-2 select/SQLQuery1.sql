/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "02 - �������� SELECT � ������� �������, JOIN".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� WideWorldImporters ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE OTUS_WideWorldImporters

/*
1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal".
�������: �� ������ (StockItemID), ������������ ������ (StockItemName).
�������: Warehouse.StockItems.
*/

select 
	 StockItemID
	,StockItemName
from Warehouse.StockItems
where StockItemName like '%urgent%' or StockItemName like '%Animal%'

/*
2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders).
������� ����� JOIN, � ����������� ������� ������� �� �����.
�������: �� ���������� (SupplierID), ������������ ���������� (SupplierName).
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.
�� ����� �������� ������ JOIN ��������� ��������������.
*/

select
	 s.SupplierID
	,s.SupplierName
from Purchasing.Suppliers as s
inner join Purchasing.PurchaseOrders as po on po.SupplierID = s.SupplierID



/*
3. ������ (Orders) � ����� ������ (UnitPrice) ����� 100$ 
���� ����������� ������ (Quantity) ������ ����� 20 ����
� �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
�������:
* OrderID
* ���� ������ (OrderDate) � ������� ��.��.����
* �������� ������, � ������� ��� ������ �����
* ����� ��������, � ������� ��� ������ �����
* ����� ����, � ������� ��������� ���� ������ (������ ����� �� 4 ������)
* ��� ��������� (Customer)
�������� ������� ����� ������� � ������������ ��������,
��������� ������ 1000 � ��������� ��������� 100 �������.

���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).

�������: Sales.Orders, Sales.OrderLines, Sales.Customers.
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

-- C ������������ ��������� 
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
4. ������ ����������� (Purchasing.Suppliers),
������� ������ ���� ��������� (ExpectedDeliveryDate) � ������ 2013 ����
� ��������� "Air Freight" ��� "Refrigerated Air Freight" (DeliveryMethodName)
� ������� ��������� (IsOrderFinalized).
�������:
* ������ �������� (DeliveryMethodName)
* ���� �������� (ExpectedDeliveryDate)
* ��� ����������
* ��� ����������� ���� ������������ ����� (ContactPerson)

�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select
	 dm.DeliveryMethodName
	,po.ExpectedDeliveryDate
	,s.SupplierName
	,p.FullName
from Purchasing.Suppliers				as s
inner join Purchasing.PurchaseOrders	as po on po.SupplierID = s.SupplierID 
												and po.ExpectedDeliveryDate like '2013-01%'
												and IsOrderFinalized = 1
inner join Application.DeliveryMethods	as dm on dm.DeliveryMethodID = po.DeliveryMethodID
												and DeliveryMethodName in ('Air Freight','Refrigerated Air Freight')
inner join Application.People 			as p on p.PersonID = po.ContactPersonID


/*
5. ������ ��������� ������ (�� ���� �������) � ������ ������� � ������ ����������,
������� ������� ����� (SalespersonPerson).
������� ��� �����������.
*/

select top 10  -- ��� � with ties ���� ����� ��� ���������� ��� ������� ����
	 o.OrderID
	,c.CustomerName
	,ContactEmployee = p.FullName
from Sales.Orders				as o
inner join sales.Customers		as c on c.CustomerID = o.CustomerID
inner join Application.People	as p on p.PersonID = o.ContactPersonID
order by o.orderdate desc

/*
6. ��� �� � ����� �������� � �� ���������� ��������,
������� �������� ����� "Chocolate frogs 250g".
��� ������ �������� � ������� Warehouse.StockItems.
*/

select top 10  
	 c.CustomerID
	,c.CustomerName
	,c.PhoneNumber
	--,si.StockItemName
from Sales.Orders							as o
inner join sales.Customers					as c	on c.CustomerID = o.CustomerID
inner join Purchasing.PurchaseOrderLines	as pol	on pol.PurchaseOrderID = o.OrderID -- ����� ��� ������ ����� ���� ��� ����������
inner join Warehouse.StockItems				as si	on si.StockItemID = pol.StockItemID 
														and StockItemName = 'Chocolate frogs 250g'

