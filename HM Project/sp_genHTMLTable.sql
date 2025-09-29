USE [Notification_Project]
GO

/****** Object:  StoredProcedure [dbo].[sp_genHTMLTable]    Script Date: 29.09.2025 13:47:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
	Процедура для динамического формирования html
*/
CREATE procedure [dbo].[sp_genHTMLTable] 	
	@db_name      as sysname = 'tempdb',	-- Имя БД
	@db_schema    as sysname = 'dbo',		-- Имя схемы
	@table_name   as sysname,			    -- Имя таблицы
	@html_table   as nvarchar(max)	OUTPUT  -- Таблица БД в виде HTML-таблицы (<table>...</table>)
as
begin
set nocount on;
set textsize 2147483647;
set transaction isolation level read committed;
declare @sSQL as nvarchar(max)    = '',           -- Для динамических запросов
		-- Ограничения на кол-во возвращаемых данных
		@maxRowsToReturn as nvarchar(max) = 'top 500', 	   -- Не более 500 строк в таблице	
		@html_table_header as nvarchar(max) = '', -- Заголовок таблицы в виде HTML
		@html_table_data   as nvarchar(max) = '' -- Данные таблицы в виде HTML

	begin 		  
		set @html_table = ''
-- 1. Получение имен колонок переданной таблицы
-- Временная таблица для хранения имен колонок
		create table #tmp_vt_genHTMLTable_col_names(nstr nvarchar(max))		
-- Формирование динамического запроса для выборки имен колонок переданной таблицы.		
		set @sSQL = 'insert into #tmp_vt_genHTMLTable_col_names(nstr)
					select COLUMN_NAME
					from ' + @db_name + '.INFORMATION_SCHEMA.COLUMNS
					where     TABLE_SCHEMA  = ''' + @db_schema + '''
				  and TABLE_NAME = (select name from ' + @db_name + '.sys.tables
										where name like ''' + @table_name + ''' + ''%'' 
										and object_id = object_id(''' + @db_name + ''' + ''.'' + ''' + @db_schema + ''' + ''.'' + ''' + @table_name + '''))				
					order by ORDINAL_POSITION;'
-- Запуск динамического запроса с сохранением результатов во временной таблице
		execute sp_executesql @sSQL		

		if @@ROWCOUNT = 0 begin		
			return;
		end		
		
-- 2. Формирование HTML-таблицы	
-- 2.1 Заголовок таблицы		
		select @html_table_header = @html_table_header + '<td>' + nstr + '</td>'
		from #tmp_vt_genHTMLTable_col_names
	
-- 2.2 Тело таблицы с данными		
-- Выражение полей для динамического запроса
		declare @fieldClause as nvarchar(max) = (select '''<td>'' + isnull(nullif(cast([' + nstr + '] as nvarchar(max)),''''),''-'') + ''</td>''+' as 'data()'
													from #tmp_vt_genHTMLTable_col_names for xml path(''))
-- Очистка после преобразования for xml path('')
		set @fieldClause = REPLACE(REPLACE(LEFT(@fieldClause, LEN(@fieldClause) - 1),'&lt;','<'),'&gt;','>')		
	
-- Полный динамический запрос
		set @sSQL = N'
			select @str = (select ' + @maxRowsToReturn + ' (''<tr bgcolor="#EEEEEE">'' + 
				' + @fieldClause + ' + ''</tr>'') as ''data()'' 
			from [' + @db_name + '].[' + @db_schema + '].[' + @table_name + ']
			for xml path(''''))'	

		exec sp_executesql @sSQL, N'@str nvarchar(max) output', @str = @html_table_data output			
		set @html_table_data =  REPLACE(REPLACE(@html_table_data,'&lt;','<'),'&gt;','>')	
		set @html_table = N'<table border="0" align="center" cellpadding="3" cellspacing="1" width="100%" bgcolor="#A4BED4">
								<tr align="center" bgcolor="#729BBC" style="color:#FFFFFF; font-weight:bold;">
				' + @html_table_header + ' </tr> ' + @html_table_data + ' </table>'		
	end 	
end
GO


