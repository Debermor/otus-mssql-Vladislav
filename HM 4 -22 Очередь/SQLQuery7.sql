use OTUS_WideWorldImporters;
go

drop procedure if exists dbo.EnqueueCustomerReport;
drop procedure if exists dbo.ProcessCustomerReportQueue;
drop table if exists dbo.CustomerOrdersReport;

create table dbo.CustomerOrdersReport
(
    ReportID int identity primary key,
    CustomerID int,
    DateFrom date,
    DateTo date,
    OrdersCount int,
    CreatedAt datetime2 not null default sysutcdatetime()
);
go

create message type [CustomerReportRequest] validation = well_formed_xml;
create message type [CustomerReportResponse] validation = well_formed_xml;

create contract [CustomerReportContract]
(
    [CustomerReportRequest] sent by initiator,
    [CustomerReportResponse] sent by target
);
go

create queue [CustomerReportQueue];
go

create service [CustomerReportService]
    on queue [CustomerReportQueue]
    ([CustomerReportContract]);
go

alter queue [CustomerReportQueue]
with activation
(
    status = on,
    procedure_name = dbo.ProcessCustomerReportQueue,
    max_queue_readers = 1,
    execute as self
);
go
---------------------------------------------------
create procedure dbo.EnqueueCustomerReport
    @CustomerID int,
    @DateFrom date,
    @DateTo date
as 
begin
    set nocount on;

    declare @DialogHandle uniqueidentifier;
    declare @MessageBody xml;

    begin try
        select @MessageBody =
            (select @CustomerID as CustomerID,
                    @DateFrom   as DateFrom,
                    @DateTo     as DateTo
             for xml path('CustomerReportRequest'), type);

        begin dialog conversation @DialogHandle
            from service [CustomerReportService]
            to service 'CustomerReportService'
            on contract [CustomerReportContract]
            with encryption = off;

        send on conversation @DialogHandle
            message type [CustomerReportRequest] (@MessageBody);

        end conversation @DialogHandle;
    end try
    begin catch
        if @DialogHandle is not null
            end conversation @DialogHandle with cleanup;

        declare @ErrMsg nvarchar(4000) = error_message();
        raiserror(@ErrMsg, 16, 1);
    end catch
end;
go
---------------------------------------------------
create procedure dbo.ProcessCustomerReportQueue
as 
begin
    set nocount on;

    declare @DialogHandle uniqueidentifier,
            @MessageType sysname,
            @MessageBody xml;

    while (1 = 1)
    begin
        waitfor
        (
            receive top(1)
                   @DialogHandle = conversation_handle,
                   @MessageType = message_type_name,
                   @MessageBody = cast(message_body as xml)
            from CustomerReportQueue
        ), timeout 2000;

        if @@rowcount = 0 break;

        if @MessageType = 'CustomerReportRequest'
        begin
            declare @CustomerID int, @DateFrom date, @DateTo date, @OrdersCount int;

            set @CustomerID = @MessageBody.value('(/CustomerReportRequest/CustomerID)[1]', 'int');
            set @DateFrom   = @MessageBody.value('(/CustomerReportRequest/DateFrom)[1]', 'date');
            set @DateTo     = @MessageBody.value('(/CustomerReportRequest/DateTo)[1]', 'date');

            select @OrdersCount = count(*)
            from Sales.Orders o
            inner join Sales.Invoices i on i.OrderID = o.OrderID
            where i.CustomerID = @CustomerID
              and o.OrderDate between @DateFrom and @DateTo;

            insert into dbo.CustomerOrdersReport (CustomerID, DateFrom, DateTo, OrdersCount)
            values (@CustomerID, @DateFrom, @DateTo, @OrdersCount);

            end conversation @DialogHandle;
        end
        else if @MessageType in 
             ('http://schemas.microsoft.com/sql/servicebroker/enddialog',
              'http://schemas.microsoft.com/sql/servicebroker/error')
        begin
            end conversation @DialogHandle;
        end
    end
end;
go
---------------------------------------------------

exec dbo.EnqueueCustomerReport @CustomerID = 1, @DateFrom = '2015-01-01', @DateTo = '2016-01-01';
exec dbo.ProcessCustomerReportQueue;

select * from dbo.CustomerOrdersReport;
go
