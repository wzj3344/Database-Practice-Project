USE [BankDB]
GO

/*==============================================================*/
/* 1. 新建利率表 (deposit_rate)                                 */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[deposit_rate]') AND type in (N'U'))
    DROP TABLE [deposit_rate]
GO

CREATE TABLE deposit_rate (
    [month] INT NOT NULL,        -- 存期 (月)
    [rate] DECIMAL(5,4) NOT NULL, -- 年利率 (如 0.0275)
    [desc] VARCHAR(20) NOT NULL,  -- 描述 (如 "3个月")
    CONSTRAINT PK_DEPOSIT_RATE PRIMARY KEY ([month])
)
GO

-- 初始化数据 (默认值)
INSERT INTO deposit_rate ([month], [rate], [desc]) VALUES 
(3, 0.0150, '3个月'),
(6, 0.0175, '6个月'),
(12, 0.0200, '1年'),
(24, 0.0275, '2年');
GO

/*==============================================================*/
/* 2. 获取利率列表 (sp_get_deposit_rates)                       */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_get_deposit_rates')
    DROP PROCEDURE sp_get_deposit_rates
GO

CREATE PROCEDURE sp_get_deposit_rates
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [month], [rate], [desc] FROM deposit_rate ORDER BY [month] ASC;
END
GO

/*==============================================================*/
/* 3. 管理员更新利率 (sp_update_deposit_rate)                   */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_update_deposit_rate')
    DROP PROCEDURE sp_update_deposit_rate
GO

CREATE PROCEDURE sp_update_deposit_rate
    @month INT,
    @new_rate DECIMAL(5,4)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @new_rate <= 0 OR @new_rate > 1
    BEGIN
        THROW 50040, '利率数值异常 (应在 0~1 之间)。', 1;
    END

    UPDATE deposit_rate 
    SET rate = @new_rate 
    WHERE [month] = @month;

    IF @@ROWCOUNT = 0
    BEGIN
        THROW 50041, '未找到指定的存期配置。', 1;
    END

    PRINT '利率更新成功';
END
GO

/*==============================================================*/
/* 4. 修改存款办理逻辑 (sp_create_deposit)                      */
/* 修改点：删除 @rate 参数，改为内部查表获取                    */
/*==============================================================*/
ALTER PROCEDURE sp_create_deposit
    @cid CHAR(20),
    @money DECIMAL(18,2),
    @months INT
    -- 删除 @rate 参数
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @did CHAR(20);
    DECLARE @ac_status INT;
    DECLARE @ac_type INT;
    DECLARE @cur_bal DECIMAL(18,2);
    DECLARE @current_rate DECIMAL(5,4); -- 查表得到的利率

    -- 1. 检查账户信息
    SELECT 
        @ac_status = astatus,
        @ac_type = atype,
        @cur_bal = cur_balance
    FROM account WHERE cid = @cid;

    -- 2. 基础校验
    IF @ac_status IS NULL THROW 50001, '办理失败：账户不存在。', 1;
    IF @ac_status <> 1 THROW 50002, '办理失败：账户处于异常状态（挂失或冻结）。', 1;
    IF @ac_type <> 1 THROW 50003, '办理失败：仅支持储蓄卡办理定期存款。', 1;
    IF @cur_bal < @money THROW 50004, '办理失败：账户余额不足。', 1;

    -- 3. 获取对应存期的利率 (核心修改)
    SELECT @current_rate = rate FROM deposit_rate WHERE [month] = @months;
    
    IF @current_rate IS NULL
    BEGIN
        THROW 50042, '办理失败：不支持该存期。', 1;
    END

    -- 生成存单号
    SET @did = 'DEP' + REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '-', ''), ' ', ''), ':', '') + CAST(FLOOR(RAND() * 99) AS VARCHAR(2));

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 4. 扣除余额
        UPDATE account SET cur_balance = cur_balance - @money WHERE cid = @cid;

        -- 5. 插入存单 (使用查到的 @current_rate)
        INSERT INTO deposit (did, cid, dnumber, drate, dstart, dover)
        VALUES (@did, @cid, @money, @current_rate, GETDATE(), DATEADD(MONTH, @months, GETDATE()));

        COMMIT TRANSACTION;
        SELECT 'SUCCESS' as status, '存款办理成功' as msg, @did as deposit_id;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO