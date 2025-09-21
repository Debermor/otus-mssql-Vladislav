/*
Если в проекте нет такой таблицы, то делаем анализ базы данных из первого модуля, 
	выбираем таблицу и делаем ее секционирование, с переносом данных по секциям (партициям) - исходя из того, 
		что таблица большая, пишем скрипты миграции в секционированную таблицу
*/

--select distinct
--	FORMAT(orderdate, 'yyyyMM') AS NPart_YearMonth
--from [Sales].[Orders]

create partition function pfMonthlyPartition (int)
as range right for values (
    201301, 201302, 201303, 201304, 201305, 201306, 201307, 201308, 201309, 201310, 201311, 201312,
    201401, 201402, 201403, 201404, 201405, 201406, 201407, 201408, 201409, 201410, 201411, 201412,
    201501, 201502, 201503, 201504, 201505, 201506, 201507, 201508, 201509, 201510, 201511, 201512,
    201601, 201602, 201603, 201604, 201605
);

create partition scheme psMonthlyPartition
as partition pfMonthlyPartition
all to ([PRIMARY]);

CREATE TABLE [Sales].[Orders_Partitioned](
	[OrderID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[PickedByPersonID] [int] NULL,
	[ContactPersonID] [int] NOT NULL,
	[BackorderOrderID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[ExpectedDeliveryDate] [date] NOT NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
	[IsUndersupplyBackordered] [bit] NOT NULL,
	[Comments] [nvarchar](max) NULL,
	[DeliveryInstructions] [nvarchar](max) NULL,
	[InternalComments] [nvarchar](max) NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
	NPart_YearMonth int not null,  -- !!!
 CONSTRAINT [PK_Sales_Orders_Partitioned] PRIMARY KEY CLUSTERED 
(
	[OrderID] ASC,
	NPart_YearMonth ASC   -- !!!
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, 
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, 
       OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) 
ON psMonthlyPartition(NPart_YearMonth)	 -- !!!
) ON psMonthlyPartition(NPart_YearMonth) -- !!!
GO


-- truncate table [Sales].[Orders_Partitioned]
-- select * from [Sales].[Orders_Partitioned]

-- скрипт поэтапной миграции данных для больших таблиц
truncate table [Sales].[Orders_Partitioned]
set nocount on;
declare @BatchSize int = 100000; 
declare @RowsAffected int = 1;
declare @TotalRows int = 0;
declare @StartTime datetime = getdate();

select @TotalRows = count(*) from [Sales].[Orders];

print N'Начало миграции ' + cast(@TotalRows as varchar) + N' строк...';
print N'Время начала: ' + convert(varchar, @StartTime, 120);

while @RowsAffected > 0
begin
    begin try
        begin transaction;

        insert into [Sales].[Orders_Partitioned] (
            [OrderID], [CustomerID], [SalespersonPersonID], [PickedByPersonID],
            [ContactPersonID], [BackorderOrderID], [OrderDate], [ExpectedDeliveryDate],
            [CustomerPurchaseOrderNumber], [IsUndersupplyBackordered], [Comments],
            [DeliveryInstructions], [InternalComments], [PickingCompletedWhen],
            [LastEditedBy], [LastEditedWhen], NPart_YearMonth
        )
        select top (@BatchSize)
            o.[OrderID], o.[CustomerID], o.[SalespersonPersonID], o.[PickedByPersonID],
            o.[ContactPersonID], o.[BackorderOrderID], o.[OrderDate], o.[ExpectedDeliveryDate],
            o.[CustomerPurchaseOrderNumber], o.[IsUndersupplyBackordered], o.[Comments],
            o.[DeliveryInstructions], o.[InternalComments], o.[PickingCompletedWhen],
            o.[LastEditedBy], o.[LastEditedWhen],
            convert(int, format(o.[OrderDate], 'yyyyMM')) as NPart_YearMonth
        from [Sales].[Orders] o
        where not exists (
            select 1 from [Sales].[Orders_Partitioned] op 
            where op.OrderID = o.OrderID
        )
        order by o.OrderID;

        set @RowsAffected = @@ROWCOUNT;

        commit transaction;

        -- логирование прогресса
       declare @ProcessedRows int = (select count(*) from [Sales].[Orders_Partitioned]);
        declare @Progress decimal(10,2) = case when @TotalRows > 0 
                                          then (@ProcessedRows * 100.0) / @TotalRows 
                                          else 0 end;
        declare @ElapsedTime int = datediff(second, @StartTime, getdate());
        declare @EstimatedTotalTime int = case when @Progress > 0 
                                         then @ElapsedTime * 100 / @Progress 
                                         else 0 end;
        declare @RemainingTime int = @EstimatedTotalTime - @ElapsedTime;

        print N'Перенесено: ' + cast(@ProcessedRows as varchar) + N' из ' + cast(@TotalRows as varchar) +
              N' (' + cast(@Progress as varchar(10)) + N'%). ' +
              N'Осталось: ~' + cast(@RemainingTime/60 as varchar) + N' мин.';

        -- небольшая пауза для уменьшения нагрузки на систему
        waitfor delay '00:00:01';

    end try
    begin catch
        if @@TRANCOUNT > 0 rollback transaction;
        
        print N'Ошибка при миграции: ' + error_message();
        print N'Номер ошибки: ' + cast(error_number() as varchar);
        break;
    end catch
end

print N'Миграция завершена!';
print N'Общее время: ' + cast(datediff(minute, @StartTime, getdate()) as varchar) + N' минут';