-- xml 2 table
-- ------------
-- 1. OPEN XML
---------------
-- Этот пример запустить сразу весь по [F5]
-- предварительно проверив ниже путь к файлу 02-open_xml.xml

-- Переменная, в которую считаем XML-файл
DECLARE @xmlDocument XML;

-- Считываем XML-файл в переменную
-- !!! измените путь к XML-файлу
SELECT @xmlDocument = BulkColumn
FROM OPENROWSET(BULK 'D:\repos\sql-otus-repo\10-xml_json\demo\02-open_xml.xml', SINGLE_CLOB) as t
/*читает файл как текстовые данные*/


-- Проверяем, что в @xmlDocument
SELECT @xmlDocument AS [@xmlDocument];

DECLARE @docHandle INT;
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument;

-- docHandle - это просто число
SELECT @docHandle AS docHandle

SELECT *
FROM OPENXML(@docHandle, N'/Orders/Order') --путь к строкам
WITH ( 
	[ID] INT  '@ID', -- атрибут
	[OrderNum] INT 'OrderNumber', -- элемент
	[CustomerNum] INT 'CustomerNumber',
	[City] NVARCHAR(10) 'Address/City',
	[Address] xml 'Address',
	[OrderDate] DATE 'OrderDate')

-- удаляем handle
EXEC sp_xml_removedocument @docHandle;

-- 2. XQuery => nodes() + value()