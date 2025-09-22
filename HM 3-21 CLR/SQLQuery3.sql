create function SplitString (@text nvarchar(max), @delimiter nchar(1))
returns @Tbl table (part nvarchar(max), ID_ORDER integer) as
begin
  declare @index integer
  declare @part  nvarchar(max)
  declare @i   integer
  set @index = -1
  set @i=1
  while (len(@text) > 0) begin
    set @index = charindex(@delimiter, @text)
    if (@index = 0) and (LEN(@text) > 0) begin
      set @part = @text
      set @text = ''
    end else if (@index > 1) begin
      set @part = left(@text, @index - 1)
      set @text = right(@text, (len(@text) - @index))
    end else begin
      set @text = right(@text, (len(@text) - @index)) 
    end
    insert into @Tbl(part, ID_ORDER) values(@part, @i)
    set @i=@i+1
  end
  return
end
go