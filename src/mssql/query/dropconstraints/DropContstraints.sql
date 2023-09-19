DECLARE @TableName NVARCHAR(128)
DECLARE @ConstraintName NVARCHAR(128)
DECLARE @SchemaName NVARCHAR(128)
DECLARE @ConstraintType NVARCHAR(128)

DECLARE cur_constraints CURSOR FOR
SELECT
    OBJECT_SCHEMA_NAME(parent_object_id) AS SchemaName,
    OBJECT_NAME(parent_object_id) AS TableName,
    name AS ConstraintName,
    type_desc AS ConstraintType
FROM
    sys.objects
WHERE
    type_desc LIKE '%CONSTRAINT%'
    AND OBJECTPROPERTY(OBJECT_ID, 'IsMSShipped') = 0

OPEN cur_constraints
FETCH NEXT FROM cur_constraints INTO @SchemaName, @TableName, @ConstraintName, @ConstraintType

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX)

        IF @ConstraintType NOT IN ('PRIMARY_KEY_CONSTRAINT', 'FOREIGN_KEY_CONSTRAINT', 'INDEX_CONSTRAINT')
        BEGIN
            SET @SQL = 'ALTER TABLE [' + @SchemaName + '].[' + @TableName + '] DROP CONSTRAINT [' + @ConstraintName + ']'
            PRINT @SQL
            EXEC sp_executesql @SQL
        END
    END TRY
    BEGIN CATCH
    END CATCH

    FETCH NEXT FROM cur_constraints INTO @SchemaName, @TableName, @ConstraintName, @ConstraintType
END

CLOSE cur_constraints
DEALLOCATE cur_constraints
