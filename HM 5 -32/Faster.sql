set statistics time, io on;
go

select ord.CustomerID, det.StockItemID, sum(det.UnitPrice), sum(det.Quantity), count(ord.OrderID)    
from Sales.Orders as ord
    join Sales.OrderLines as det
        on det.OrderID = ord.OrderID
    join Sales.Invoices as inv 
        on inv.OrderID = ord.OrderID
    join Sales.CustomerTransactions as trans
        on trans.InvoiceID = inv.InvoiceID
    join Warehouse.StockItemTransactions as itemtrans
        on itemtrans.StockItemID = det.StockItemID
where inv.BillToCustomerID != ord.CustomerID
    and (select SupplierId
         from Warehouse.StockItems as it
         where it.StockItemID = det.StockItemID) = 12
    and (select sum(total.UnitPrice * total.Quantity)
         from Sales.OrderLines as total
             join Sales.Orders as ordtotal
                 on ordtotal.OrderID = total.OrderID
         where ordtotal.CustomerID = inv.CustomerID) > 250000
    and datediff(dd, inv.InvoiceDate, ord.OrderDate) = 0
group by ord.CustomerID, det.StockItemID
order by ord.CustomerID, det.StockItemID;

/*

 Время работы SQL Server:
   Время ЦП = 390 мс, затраченное время = 3808 мс.
*/

------------------------------------------------
drop index if exists IX_Orders_CustomerID_OrderDate			on Sales.Orders;
drop index if exists IX_Invoices_OrderID_BillToCustomerID	on Sales.Invoices;
drop index if exists IX_Invoices_InvoiceDate_OrderID		on Sales.Invoices;
drop index if exists IX_OrderLines_OrderID_StockItemID		on Sales.OrderLines;
drop index if exists IX_CustomerTransactions_InvoiceID		on Sales.CustomerTransactions;

-- Добавил индексов и предагрегацию в cte (Итог 4 секунды против 0), тем самым поменял 
create index IX_Orders_CustomerID_OrderDate			on Sales.Orders(CustomerID, OrderDate);
create index IX_Invoices_OrderID_BillToCustomerID	on Sales.Invoices(OrderID, BillToCustomerID);
create index IX_Invoices_InvoiceDate_OrderID		on Sales.Invoices(InvoiceDate, OrderID);
create index IX_OrderLines_OrderID_StockItemID		on Sales.OrderLines(OrderID, StockItemID);
create index IX_CustomerTransactions_InvoiceID		on Sales.CustomerTransactions(InvoiceID); 

set statistics time, io on;
go


;with filtered_customers as (
    select ordtotal.customerid
    from Sales.Orders as ordtotal
    join Sales.OrderLines as total
        on total.orderid = ordtotal.orderid
    group by ordtotal.customerid
    having sum(total.unitprice * total.quantity) > 250000
)
select ord.customerid,
       det.stockitemid,
       sum(det.unitprice),
       sum(det.quantity),
       count(ord.orderid)
from Sales.Orders as ord
join Sales.OrderLines as det
    on det.orderid = ord.orderid
join Sales.Invoices as inv
    on inv.orderid = ord.orderid
join Sales.CustomerTransactions as trans
    on trans.invoiceid = inv.invoiceid
join Warehouse.StockItemTransactions as itemtrans
    on itemtrans.stockitemid = det.stockitemid
join Warehouse.StockItems as it
    on it.stockitemid = det.stockitemid
    and it.supplierid = 12
join filtered_customers fc
    on fc.customerid = inv.customerid
where inv.billtocustomerid <> ord.customerid
  and datediff(dd, inv.InvoiceDate, ord.OrderDate) = 0
group by ord.customerid, det.stockitemid
order by ord.customerid, det.stockitemid;

/*
 Время работы SQL Server:
   Время ЦП = 313 мс, затраченное время = 427 мс.
*/