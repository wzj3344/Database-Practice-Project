USE BankDB
GO

ALTER PROCEDURE sp_add_product
    @pid CHAR(20),
    @pname VARCHAR(20),
    @pworth DECIMAL(10,2),
    @pleast DECIMAL(10,2),
    @prisk INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 1. 新增：空值检查 (LTRIM/RTRIM 去除首尾空格)
    IF LEN(LTRIM(RTRIM(@pid))) = 0
    BEGIN
        THROW 50010, '产品ID不能为空。', 1;
    END

    IF LEN(LTRIM(RTRIM(@pname))) = 0
    BEGIN
        THROW 50011, '产品名称不能为空。', 1;
    END

    -- 2. 检查ID是否存在
    IF EXISTS (SELECT 1 FROM financial_product WHERE pid = @pid)
    BEGIN
        THROW 50008, '产品ID已存在，无法重复发布。', 1;
    END

    -- 3. 检查风险等级
    IF @prisk < 1 OR @prisk > 5
    BEGIN
        THROW 50009, '风险等级必须在 1-5 之间。', 1;
    END

    -- 4. 插入数据
    INSERT INTO financial_product (pid, pname, pworth, pleast, prisk, pstatus)
    VALUES (@pid, @pname, @pworth, @pleast, @prisk, 1); 
END
GO

USE BankDB
GO

/*==============================================================*/
/* 2.1.14 删除理财产品 (sp_delete_product)                      */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_delete_product')
    DROP PROCEDURE sp_delete_product
GO

CREATE PROCEDURE sp_delete_product
    @pid CHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. 检查是否存在持仓记录
    -- 如果 with_product 表中有该产品的记录，说明有人买过（即使现在卖光了可能有历史数据，通常也不删，这里简化为检查持有记录）
    IF EXISTS (SELECT 1 FROM with_product WHERE pid = @pid)
    BEGIN
        THROW 50012, '该产品已有用户购买记录，为了保证账目完整，禁止删除！建议将其设置为“下架/停售”。', 1;
    END

    -- 2. 检查产品是否存在
    IF NOT EXISTS (SELECT 1 FROM financial_product WHERE pid = @pid)
    BEGIN
        THROW 50013, '产品不存在。', 1;
    END

    -- 3. 执行删除
    DELETE FROM financial_product WHERE pid = @pid;
END
GO

USE BankDB
GO

/*==============================================================*/
/* 1. 修复：更新理财产品 (增加名称非空检查)                     */
/*==============================================================*/
ALTER PROCEDURE sp_update_product
    @pid CHAR(20),
    @pname VARCHAR(20) = NULL,
    @pstatus INT = NULL,
    @pworth DECIMAL(10,2) = NULL,
    @prisk INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. 核心修复：检查名称是否为空字符串
    IF @pname IS NOT NULL AND LEN(LTRIM(RTRIM(@pname))) = 0
    BEGIN
        THROW 50014, '产品名称不能为空。', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM financial_product WHERE pid = @pid)
    BEGIN
        THROW 50013, '产品不存在。', 1;
    END

    UPDATE financial_product
    SET pname = ISNULL(@pname, pname),
        pstatus = ISNULL(@pstatus, pstatus),
        pworth = ISNULL(@pworth, pworth),
        prisk = ISNULL(@prisk, prisk)
    WHERE pid = @pid;
END
GO