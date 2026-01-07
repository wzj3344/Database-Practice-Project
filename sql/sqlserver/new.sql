-- 在 VS Code 的 SQL 查询中运行这个
SELECT 
    '你在 VS Code 中连接的服务器' as Info,
    @@SERVERNAME as ServerName,
    HOST_NAME() as HostName,
    DB_NAME() as CurrentDatabase,
    @@VERSION as Version;

-- 然后查看 BankDB 中的表
USE BankDB;
SELECT 
    'BankDB 中的表' as Info,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    TABLE_TYPE as TableType
FROM INFORMATION_SCHEMA.TABLES
ORDER BY TABLE_NAME;

-- 查看用户数据
SELECT 
    '用户数据' as Info,
    bank_user_id as UserID,
    bank_user_name as UserName,
    passward as Password,
    phone as Phone
FROM bank_user;

SELECT 
    *
FROM admini;


SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE='BASE TABLE';