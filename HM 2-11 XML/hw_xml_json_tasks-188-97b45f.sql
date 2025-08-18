/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

/*
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

declare @xml xml;

set @xml = (select * from openrowset (bulk N'D:\Git\github\Otus\otus-mssql-Vladislav\xml\StockItems-188-1fb5df.xml', single_blob) as x);

--Xquery
merge Warehouse.StockItems as t
using (
    select 
         x.value('@Name', 'nvarchar(100)') as StockItemName
        ,x.value('(SupplierID/text())[1]', 'int') as SupplierID
        ,x.value('(Package/UnitPackageID/text())[1]', 'int') as UnitPackageID
        ,x.value('(Package/OuterPackageID/text())[1]', 'int') as OuterPackageID
        ,x.value('(Package/QuantityPerOuter/text())[1]', 'int') as QuantityPerOuter
        ,x.value('(Package/TypicalWeightPerUnit/text())[1]', 'decimal(18,3)') as TypicalWeightPerUnit
        ,x.value('(LeadTimeDays/text())[1]', 'int') as LeadTimeDays
        ,x.value('(IsChillerStock/text())[1]', 'bit') as IsChillerStock
        ,x.value('(TaxRate/text())[1]', 'decimal(18,3)') as TaxRate
        ,x.value('(UnitPrice/text())[1]', 'decimal(18,2)') as UnitPrice
    from @xml.nodes('/StockItems/Item') as t(x)
) as s
on t.StockItemName = s.StockItemName
when matched then
    update set
         SupplierID = s.SupplierID
        ,UnitPackageID = s.UnitPackageID
        ,OuterPackageID = s.OuterPackageID
        ,QuantityPerOuter = s.QuantityPerOuter
        ,TypicalWeightPerUnit = s.TypicalWeightPerUnit
        ,LeadTimeDays = s.LeadTimeDays
        ,IsChillerStock = s.IsChillerStock
        ,TaxRate = s.TaxRate
        ,UnitPrice = s.UnitPrice
when not matched then
    insert (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy)
    values (s.StockItemName, s.SupplierID, s.UnitPackageID, s.OuterPackageID, s.QuantityPerOuter, s.TypicalWeightPerUnit, s.LeadTimeDays, s.IsChillerStock, s.TaxRate, s.UnitPrice, 1);
;

--open
declare @doc int;
exec sp_xml_preparedocument @doc output, @xml;

merge Warehouse.StockItems as t
using (
    select *
    from openxml(@doc, '/StockItems/Item', 2)
    with (
         StockItemName nvarchar(100) '@Name'
        ,SupplierID int 'SupplierID'
        ,UnitPackageID int 'Package/UnitPackageID'
        ,OuterPackageID int 'Package/OuterPackageID'
        ,QuantityPerOuter int 'Package/QuantityPerOuter'
        ,TypicalWeightPerUnit decimal(18,3) 'Package/TypicalWeightPerUnit'
        ,LeadTimeDays int 'LeadTimeDays'
        ,IsChillerStock bit 'IsChillerStock'
        ,TaxRate decimal(18,3) 'TaxRate'
        ,UnitPrice decimal(18,2) 'UnitPrice'
    )
) as s
on t.StockItemName = s.StockItemName
when matched then
    update set
         SupplierID = s.SupplierID
        ,UnitPackageID = s.UnitPackageID
        ,OuterPackageID = s.OuterPackageID
        ,QuantityPerOuter = s.QuantityPerOuter
        ,TypicalWeightPerUnit = s.TypicalWeightPerUnit
        ,LeadTimeDays = s.LeadTimeDays
        ,IsChillerStock = s.IsChillerStock
        ,TaxRate = s.TaxRate
        ,UnitPrice = s.UnitPrice
when not matched then
    insert (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy)
    values (s.StockItemName, s.SupplierID, s.UnitPackageID, s.OuterPackageID, s.QuantityPerOuter, s.TypicalWeightPerUnit, s.LeadTimeDays, s.IsChillerStock, s.TaxRate, s.UnitPrice, 1);

exec sp_xml_removedocument @doc;
;
/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/
;

select 
    StockItemName as "@Name"
    ,SupplierID
    ,(
        select 
            UnitPackageID as "UnitPackageID"
            ,OuterPackageID as "OuterPackageID"
            ,QuantityPerOuter as "QuantityPerOuter"
            ,TypicalWeightPerUnit as "TypicalWeightPerUnit"
        for xml path('Package'), type
     )
    ,LeadTimeDays
    ,IsChillerStock
    ,TaxRate
    ,UnitPrice
from Warehouse.StockItems
for xml path('Item'), root('StockItems')


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select 
    StockItemID,
    StockItemName,
    json_value(CustomFields, '$.CountryOfManufacture') as CountryOfManufacture,
    json_value(CustomFields, '$.Tags[0]') as FirstTag
from  Warehouse.StockItems;

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


select 
    StockItemID,
    StockItemName,
    string_agg(value, ', ') as Tags
from Warehouse.StockItems
cross apply openjson(CustomFields, '$.Tags')
where value = 'Vintage'
GROUP BY StockItemID, StockItemName;
