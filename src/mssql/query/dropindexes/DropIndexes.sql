DECLARE @TableName NVARCHAR(255) 
DECLARE table_cursor CURSOR FOR 
SELECT
    QUOTENAME(s.name) + '.' + QUOTENAME(t.name) AS TableName 
FROM
    sys.tables t 
    INNER JOIN
        sys.schemas s 
        ON t.schema_id = s.schema_id OPEN table_cursor FETCH NEXT 
FROM
    table_cursor INTO @TableName WHILE @@FETCH_STATUS = 0 
    BEGIN
        BEGIN
            TRY
            DECLARE @ConstraintName NVARCHAR(255) 
            DECLARE constraint_cursor CURSOR FOR 
            SELECT
            name 
            FROM
            sys.objects 
            WHERE
            parent_object_id = OBJECT_ID(@TableName) 
            AND type = 'F' OPEN constraint_cursor FETCH NEXT 
            FROM
            constraint_cursor INTO @ConstraintName WHILE @@FETCH_STATUS = 0 
            BEGIN
                DECLARE @DisableConstraintSQL NVARCHAR(MAX) 
            SET
            @DisableConstraintSQL = 'ALTER TABLE ' + @TableName + ' NOCHECK CONSTRAINT ' + @ConstraintName EXEC sp_executesql @DisableConstraintSQL FETCH NEXT 
            FROM
            constraint_cursor INTO @ConstraintName 
            END
            CLOSE constraint_cursor DEALLOCATE constraint_cursor
            DECLARE @IndexName NVARCHAR(255) 
            DECLARE index_cursor CURSOR FOR 
            SELECT
                name 
            FROM
                sys.indexes 
            WHERE
                object_id = OBJECT_ID(@TableName) 
                AND type = 2 OPEN index_cursor FETCH NEXT 
            FROM
                index_cursor INTO @IndexName WHILE @@FETCH_STATUS = 0 
                BEGIN
                    DECLARE @DropIndexSQL NVARCHAR(MAX) 
            SET
                @DropIndexSQL = 'DROP INDEX ' + @TableName + '.' + @IndexName EXEC sp_executesql @DropIndexSQL FETCH NEXT 
            FROM
                index_cursor INTO @IndexName 
                END
                CLOSE index_cursor DEALLOCATE index_cursor
                DECLARE @ClusteredIndexName NVARCHAR(255) 
                SELECT
                    TOP 1 @ClusteredIndexName = name 
                FROM
                    sys.indexes 
                WHERE
                    object_id = OBJECT_ID(@TableName) 
                    AND type = 1 IF @ClusteredIndexName IS NOT NULL 
                    BEGIN
                        DECLARE @DropClusteredIndexSQL NVARCHAR(MAX) 
                SET
                    @DropClusteredIndexSQL = 'DROP INDEX ' + @TableName + '.' + @ClusteredIndexName EXEC sp_executesql @DropClusteredIndexSQL 
                    END
                    -- Re-enable constraints
                    DECLARE enable_constraint_cursor CURSOR FOR 
                    SELECT
                        name 
                    FROM
                        sys.objects 
                    WHERE
                        parent_object_id = OBJECT_ID(@TableName) 
                        AND type = 'F' OPEN enable_constraint_cursor FETCH NEXT 
                    FROM
                        enable_constraint_cursor INTO @ConstraintName WHILE @@FETCH_STATUS = 0 
                        BEGIN
                        DECLARE @EnableConstraintSQL NVARCHAR(MAX) 
                    SET
                        @EnableConstraintSQL = 'ALTER TABLE ' + @TableName + ' CHECK CONSTRAINT ' + @ConstraintName EXEC sp_executesql @EnableConstraintSQL FETCH NEXT 
                    FROM
                        enable_constraint_cursor INTO @ConstraintName 
                        END
                        CLOSE enable_constraint_cursor DEALLOCATE enable_constraint_cursor 
        END
        TRY 
        BEGIN
            CATCH 
        END
        CATCH FETCH NEXT 
                    FROM
                        table_cursor INTO @TableName 
    END
    CLOSE table_cursor DEALLOCATE table_cursor
