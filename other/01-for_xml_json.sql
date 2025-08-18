-- table 2 xml/json (выгрузка)

USE WideWorldImporters

--------------------------
-- FOR XML RAW
--------------------------

-- Простой FOR XML RAW: строка => элемент, столбцы => атрибуты, корневого элемента нет
SELECT TOP 3 SupplierID,  CityName
FROM Website.Suppliers
ORDER BY 1
FOR XML RAW

-- Переименование <row> и корневого элемента, атрибуты остались
SELECT TOP 3 SupplierID,  CityName
FROM Website.Suppliers
ORDER BY 1
FOR XML RAW('Supplier'), ROOT('Suppliers')

-- ELEMENTS: каждая колонка => элемент, без атрибутов
SELECT TOP 3 SupplierID,  CityName
FROM Website.Suppliers
ORDER BY 1 DESC
FOR XML RAW('Supplier'), ROOT('Suppliers'), ELEMENTS

--------------------------
-- FOR XML/JSON PATH - более сложная структура
-- м посмотреть через Azure Data Studio: JSON, XML  
--------------------------
-- иерархия - через алиасы колонок 
-- FOR XML PATH
SELECT TOP 3
    SupplierID AS [@Id], --@ - атрибут, а не дочерний элемент
    SupplierName AS [SupplierInfo/@Name], -- дочерний с атрибутом
    'some_value' AS [SupplierInfo/Name/@some_attribute],
    SupplierCategoryName AS [SupplierInfo/Category],
    PrimaryContact AS [Contact/Primary],
    AlternateContact AS [Contact/Alternate],
    WebsiteURL [WebsiteURL],
    CityName AS [CityName],
    'SupplierReference: ' + SupplierReference AS 'comment()' -- коментарий
FROM Website.Suppliers
FOR XML PATH('Supplier'), ROOT('Suppliers')
GO

-- FOR JSON PATH
-- структура https://codebeautify.org/jsonviewer
SELECT TOP 3
    SupplierID AS [Id],
    SupplierName AS [SupplierInfo.Name],
    SupplierCategoryName AS [SupplierInfo.Category],
    PrimaryContact AS [Contact.Primary],
    AlternateContact AS [Contact.Alternate],
    WebsiteURL [WebsiteURL],
    CityName AS [CityName]
FROM Website.Suppliers
FOR JSON PATH, INCLUDE_NULL_VALUES

-- аналог STRING_AGG() в версиях до SQL Server 2017
SELECT TOP 10 
    s.StateProvinceName AS [StateName],    
    STRING_AGG(cast(c.CityName AS NVARCHAR(max)), ', ') within group (order by CityName) AS Cities
FROM Application.Cities c 
JOIN Application.StateProvinces s ON s.StateProvinceID = c.StateProvinceID
GROUP BY s.StateProvinceName

-- вывести имя штата и список городов в этом штате (в одной строке)
-- data() - https://docs.microsoft.com/ru-ru/sql/relational-databases/xml/column-names-with-the-path-specified-as-data
SELECT TOP 10 StateProvinceName, (
		SELECT CityName + ',' AS 'data()' -- имя столбца указано как data() === string_split()
		FROM Application.Cities
		WHERE StateProvinceID = s.StateProvinceID
		ORDER BY 1
		FOR XML PATH('')
		) AS Cities
FROM Application.StateProvinces AS s






-- Про другие варианты (FOR XML/JSON AUTO, FOR XML EXPLICIT)
-- на самостоятельное изучение
-- XML - https://docs.microsoft.com/ru-ru/sql/relational-databases/xml/for-xml-sql-server
-- JSON -  https://docs.microsoft.com/ru-ru/sql/relational-databases/json/format-query-results-as-json-with-for-json-sql-server?view=sql-server-ver15#option-2---select-statement-controls-output-with-for-json-auto