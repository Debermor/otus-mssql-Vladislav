USE [Notification_Project]
GO

/****** Object:  StoredProcedure [dbo].[sp_UpdateStatus]    Script Date: 29.09.2025 13:48:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/*
	Процедура для тестирования работоспособности.
*/

-- exec sp_UpdateStatus @xmode = 0 



CREATE procedure [dbo].[sp_UpdateStatus](@xmode  int = 1) as

declare @xdate date = cast(getdate() as date)

begin try

-- 1. В случаи пересчета данных (@xmode = 0) удаляем данные о обновлении. 
if @xmode = 0
	begin 
		delete tbl_UpdateDate 
		where UpdateDate = @xdate
	end

-- 2. Заносим в таблицу данные о старте обновления
if not exists (select 1 from tbl_UpdateDate where UpdateDate = @xdate and UpdateStep in (1,0))
	begin
		Insert into tbl_UpdateDate (UpdateDate,UpdateStatus,UpdateStep)
		select 
			 @xdate
			,'Start'
			,1
	

		exec sp_Send_Notificaion  @xNotification = 'DailyUpdate',@xNotification_Variant = 1

waitfor delay '00:00:05'
-- 3. Заносим в таблицу данные о окончании обновления
		Insert into tbl_UpdateDate (UpdateDate,UpdateStatus,UpdateStep)
		select 
			 @xdate
			,'Done'
			,2

		exec sp_Send_Notificaion  @xNotification = 'DailyUpdate',@xNotification_Variant = 2
end

end try 
begin catch
    throw;
end catch

GO


