DECLARE @TableName NVARCHAR(128) 
DECLARE @ForeignKeyName NVARCHAR(128) 
DECLARE @SchemaName NVARCHAR(128) 
DECLARE @SQL NVARCHAR(MAX)
DECLARE cur_cursor CURSOR FOR 
SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS SchemaName,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    fk.name AS ForeignKeyName 
FROM
    sys.foreign_keys fk 
    INNER JOIN
        sys.tables t 
        ON fk.parent_object_id = t.object_id 
WHERE
    t.is_ms_shipped = 0 -- Exclude system tables
    OPEN cur_cursor FETCH NEXT 
FROM
    cur_cursor INTO @SchemaName,
    @TableName,
    @ForeignKeyName WHILE @@FETCH_STATUS = 0 
    BEGIN
SET
    @SQL = 'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' DROP CONSTRAINT ' + QUOTENAME(@ForeignKeyName) 	-- Execute the DROP statement
    PRINT @SQL
    EXEC sp_executesql @SQL FETCH NEXT 
FROM
    cur_cursor INTO @SchemaName,
    @TableName,
    @ForeignKeyName 
    END
    CLOSE cur_cursor DEALLOCATE cur_cursor
