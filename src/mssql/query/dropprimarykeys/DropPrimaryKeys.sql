DECLARE @TableName NVARCHAR(128) 
DECLARE @ConstraintName NVARCHAR(128) 
DECLARE primaryKeyCursor CURSOR FOR 
SELECT
    OBJECT_NAME(object_id) AS TableName,
    name AS ConstraintName 
FROM
    sys.indexes 
WHERE
    is_primary_key = 1 
    AND OBJECTPROPERTY(object_id, 'IsUserTable') = 1 	-- Exclude system tables
    OPEN primaryKeyCursor FETCH NEXT 
FROM
    primaryKeyCursor INTO @TableName,
    @ConstraintName WHILE @@FETCH_STATUS = 0 
    BEGIN
        DECLARE @DropPrimaryKeySQL NVARCHAR(MAX) 
SET
    @DropPrimaryKeySQL = 'ALTER TABLE [' + @TableName + '] DROP CONSTRAINT [' + @ConstraintName + ']' 
    BEGIN
        TRY
        PRINT @DropPrimaryKeySQL
        EXEC sp_executesql @DropPrimaryKeySQL
    END
    TRY 
    BEGIN
        CATCH
    END
    CATCH FETCH NEXT 
FROM
    primaryKeyCursor INTO @TableName,
    @ConstraintName 
    END
    CLOSE primaryKeyCursor DEALLOCATE primaryKeyCursor
