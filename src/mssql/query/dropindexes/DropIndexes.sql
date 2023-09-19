DECLARE @table_name NVARCHAR(255)
DECLARE @schema_name NVARCHAR(255)
DECLARE @index_name NVARCHAR(255)
DECLARE @index_type_desc NVARCHAR(60)
DECLARE @constraint_name NVARCHAR(255)

DECLARE @sql NVARCHAR(MAX)

DECLARE table_cursor CURSOR FOR
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

OPEN table_cursor

FETCH NEXT FROM table_cursor INTO @schema_name, @table_name

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Table: ' + @schema_name + '.' + @table_name

    DECLARE index_cursor CURSOR FOR
    SELECT name, type_desc
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name)) AND is_primary_key = 0 AND is_unique_constraint = 0 AND type_desc <> 'CLUSTERED' AND type <> 4

    OPEN index_cursor

    FETCH NEXT FROM index_cursor INTO @index_name, @index_type_desc

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT '- Dropping index: ' + @index_name
        
        SET @sql = 'DROP INDEX ' + QUOTENAME(@index_name) + ' ON ' + QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name)

        BEGIN TRY
            EXEC sp_executesql @sql
            PRINT '- Index dropped successfully.'
        END TRY
        BEGIN CATCH
            PRINT '- Error occurred while dropping index: ' + ERROR_MESSAGE()
        END CATCH

        FETCH NEXT FROM index_cursor INTO @index_name, @index_type_desc
    END

    CLOSE index_cursor
    DEALLOCATE index_cursor

    -- Drop foreign key constraints that use clustered indexes
    DECLARE fk_cursor CURSOR FOR
    SELECT CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_TYPE = 'FOREIGN KEY' AND TABLE_SCHEMA = @schema_name AND TABLE_NAME = @table_name AND EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name)) AND name = (
            SELECT name
            FROM sys.index_columns
            WHERE object_id = sys.indexes.object_id AND column_id = sys.index_columns.column_id AND is_included_column = 0
        ) AND type_desc = 'CLUSTERED'
    )

    OPEN fk_cursor

    FETCH NEXT FROM fk_cursor INTO @constraint_name

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT '- Dropping foreign key constraint: ' + @constraint_name
        
        SET @sql = 'ALTER TABLE ' + QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name) + ' DROP CONSTRAINT ' + QUOTENAME(@constraint_name)

        BEGIN TRY
            EXEC sp_executesql @sql
            PRINT '- Foreign key constraint dropped successfully.'
        END TRY
        BEGIN CATCH
            PRINT '- Error occurred while dropping foreign key constraint: ' + ERROR_MESSAGE()
        END CATCH

        FETCH NEXT FROM fk_cursor INTO @constraint_name
    END

    CLOSE fk_cursor
    DEALLOCATE fk_cursor

    FETCH NEXT FROM table_cursor INTO @schema_name, @table_name
END

CLOSE table_cursor
DEALLOCATE table_cursor

BEGIN TRY
    DECLARE @IndexName NVARCHAR(128)
    DECLARE @SchemaName NVARCHAR(128)
    DECLARE @TableName NVARCHAR(128)
    DECLARE @DropStatement NVARCHAR(MAX)

    DECLARE IndexCursor CURSOR FOR
        SELECT 
            SCHEMA_NAME(t.schema_id) AS SchemaName,
            t.name AS TableName,
            i.name AS IndexName
        FROM 
            sys.indexes i
            INNER JOIN sys.tables t ON i.object_id = t.object_id
        WHERE 
            i.type_desc = 'CLUSTERED'
        ORDER BY 
            SchemaName,
            TableName

    OPEN IndexCursor

    FETCH NEXT FROM IndexCursor INTO @SchemaName, @TableName, @IndexName

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @DropStatement = 'DROP INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName)
        BEGIN TRY
            PRINT @DropStatement
			EXEC sp_executesql @DropStatement
        END TRY
        BEGIN CATCH
            PRINT 'Error dropping index ' + QUOTENAME(@IndexName) + ' on table ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ': ' + ERROR_MESSAGE()
        END CATCH
        FETCH NEXT FROM IndexCursor INTO @SchemaName, @TableName, @IndexName
    END

    CLOSE IndexCursor
    DEALLOCATE IndexCursor

END TRY
BEGIN CATCH
    PRINT 'An error occurred while dropping the clustered indexes.'
    PRINT ERROR_MESSAGE()
END CATCH
