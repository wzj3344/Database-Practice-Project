USE BankDB
GO

-- 更新账户交易限额 (sp_update_account_limit)
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_update_account_limit')
    DROP PROCEDURE sp_update_account_limit
GO

CREATE PROCEDURE sp_update_account_limit
    @cid CHAR(20),
    @new_limit DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM account WHERE cid = @cid)
    BEGIN
        PRINT '账户不存在。';
        RETURN;
    END

    UPDATE account SET transaction_limit = @new_limit WHERE cid = @cid;
    PRINT '交易限额已更新。';
END
GO

-- 添加管理员 (sp_add_admin)
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_add_admin')
    DROP PROCEDURE sp_add_admin
GO

CREATE PROCEDURE sp_add_admin
    @aid VARCHAR(20),
    @password VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM admini WHERE aid = @aid)
    BEGIN
        PRINT '管理员ID已存在，添加失败。';
        RETURN;
    END

    INSERT INTO admini (aid, apassword) VALUES (@aid, @password);
    PRINT '管理员添加成功。';
END
GO

USE BankDB
GO

/*==============================================================*/
/* 修改：添加管理员 (增加重复检查和空值检查)                    */
/*==============================================================*/
ALTER PROCEDURE sp_add_admin
    @aid VARCHAR(20),
    @password VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 1. 检查是否为空
    IF LEN(LTRIM(RTRIM(@aid))) = 0
    BEGIN
        THROW 50015, '管理员ID不能为空。', 1;
    END

    -- 2. 检查ID是否已存在
    IF EXISTS (SELECT 1 FROM admini WHERE aid = @aid)
    BEGIN
        -- 使用 THROW 抛出异常，让后端捕获
        THROW 50016, '管理员ID已存在，添加失败。', 1;
    END

    -- 3. 插入数据
    INSERT INTO admini (aid, apassword) VALUES (@aid, @password);
END
GO