-- xml 2 table
-- ----------------------
-- OPENJSON
-- ----------------------
-- Этот пример запустить сразу весь по [F5]
-- (предварительно проверив ниже путь к файлу 03-open_json.json)

DECLARE @json NVARCHAR(max);

SELECT @json = BulkColumn
FROM OPENROWSET(BULK 'D:\repos\sql-otus-repo\10-xml_json\demo\03-open_json.json', SINGLE_CLOB) AS data;

-- Проверяем, что в @json
SELECT @json AS [@json];

-- OPENJSON Явное описание структуры
--$ - корень, . - разделитель уровней вложенности

SELECT *
FROM OPENJSON (@json, '$.Suppliers') --путь к строкам
WITH (
    Id          INT,
    Supplier    NVARCHAR(100)   '$.SupplierInfo.Name',    
    Contact     NVARCHAR(MAX)   '$.Contact' AS JSON,
    City        NVARCHAR(100)   '$.CityName'
) t
OUTER APPLY OPENJSON(t.Contact) WITH (
        PrimaryContact   NVARCHAR(100) '$.Primary',
        AlternateContact NVARCHAR(100) '$.Alternate'
    ) AS c

-- OPENJSON Без структуры
SELECT * FROM OPENJSON(@json) -- массив

SELECT * FROM OPENJSON(@json, '$.Suppliers') -- элементы массива в строки, каждая строка - элемент 
-- Type:
--    0 = null
--    1 = string
--    2 = int
--    3 = bool
--    4 = array
--    5 = object

SELECT * FROM OPENJSON(@json, '$.Suppliers[0]') -- 1й поставщик (1й элемент массива)







-- доступ к элементам массива
declare @s nvarchar(max) = N'{
    "@Id": 1,
    "Supplier": {
        "Name": "Test",
        "Tags": ["A", "B"]
    }
}'
select * 
from openjson(@s) with (
	Id int '$."@Id"'
	, Supplier nvarchar(10) '$.Supplier.Name'
	, Tag1 nvarchar(10) '$.Supplier.Tags[0]'
	, Tag2 nvarchar(10) '$.Supplier.Tags[1]'
	)

-- Warehouse.StockItems - CustomFields (json)
select CustomFields, t.* 
from Warehouse.StockItems as i
outer apply openjson(CustomFields) with (
	CountryOfManufacture nvarchar(20) '$.CountryOfManufacture'
	, Tag2 nvarchar(20) '$.Tags[1]'
	) t

select CustomFields, t.*
from Warehouse.StockItems as i
outer apply openjson(CustomFields, '$.Tags') t
where t.value = N'16GB'
