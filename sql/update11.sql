USE [BankDB]
GO

/*==============================================================*/
/* 新增：定期存款取回 (sp_withdraw_deposit)                     */
/* 逻辑：                                                       */
/* 1. 校验存单归属                                              */
/* 2. 计算利息 (到期全额，未到期为0)                            */
/* 3. 本金+利息 入账                                            */
/* 4. 物理删除存单记录 (代表已结清)                             */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_withdraw_deposit')
    DROP PROCEDURE sp_withdraw_deposit
GO

CREATE PROCEDURE sp_withdraw_deposit
    @did CHAR(20),
    @cid CHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @amount DECIMAL(18,2);
    DECLARE @rate DECIMAL(5,4);
    DECLARE @start DATE;
    DECLARE @end DATE;
    DECLARE @interest DECIMAL(18,2) = 0.00;
    DECLARE @ac_status INT;

    -- 1. 验证存单是否存在且属于该卡
    SELECT @amount = dnumber, @rate = drate, @start = dstart, @end = dover
    FROM deposit WHERE did = @did AND cid = @cid;

    IF @amount IS NULL THROW 50060, '取回失败：存单不存在或不属于该卡。', 1;

    -- 2. 验证账户状态
    SELECT @ac_status = astatus FROM account WHERE cid = @cid;
    IF @ac_status <> 1 THROW 50061, '取回失败：账户异常（挂失或冻结），无法入账。', 1;

    -- 3. 计算利息
    -- 规则：只有当前时间 >= 到期日，才发放利息；否则利息为0
    IF CAST(GETDATE() AS DATE) >= @end
    BEGIN
        -- 利息 = 本金 * 年利率 * (存款天数 / 365)
        SET @interest = @amount * @rate * (DATEDIFF(DAY, @start, @end) / 365.0);
    END
    ELSE
    BEGIN
        -- 提前支取，无利息 (提示信息由前端处理，后端只执行逻辑)
        SET @interest = 0.00;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

            -- 4. 资金入账 (本金 + 利息)
            UPDATE account 
            SET cur_balance = cur_balance + @amount + @interest 
            WHERE cid = @cid;

            -- 5. 删除存单记录 (物理删除表示结清)
            DELETE FROM deposit WHERE did = @did;

        COMMIT TRANSACTION;
        
        -- 返回结果供前端展示
        SELECT 'SUCCESS' as status, 
               '取回成功！本金: ' + CAST(@amount AS VARCHAR) + ', 利息: ' + CAST(CAST(@interest AS DECIMAL(18,2)) AS VARCHAR) as msg;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

USE [BankDB]
GO

/*==============================================================*/
/* 1. 修改表结构：增加 dstatus 状态字段                         */
/*==============================================================*/
-- 如果字段不存在则添加
IF NOT EXISTS(SELECT * FROM sys.columns WHERE Name = N'dstatus' AND Object_ID = Object_ID(N'deposit'))
BEGIN
    ALTER TABLE deposit ADD dstatus INT NOT NULL DEFAULT 1; -- 1:持有中, 2:已取回
END
GO

-- 刷新现有数据的状态为 1
UPDATE deposit SET dstatus = 1 WHERE dstatus IS NULL;
GO

/*==============================================================*/
/* 2. 修改：定期存款办理 (sp_create_deposit)                    */
/* 变更：插入时设置 dstatus = 1                                 */
/*==============================================================*/
ALTER PROCEDURE sp_create_deposit
    @cid CHAR(20),
    @money DECIMAL(18,2),
    @months INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @did CHAR(20);
    DECLARE @ac_status INT;
    DECLARE @ac_type INT;
    DECLARE @cur_bal DECIMAL(18,2);
    DECLARE @current_rate DECIMAL(5,4);

    SELECT @ac_status = astatus, @ac_type = atype, @cur_bal = cur_balance
    FROM account WHERE cid = @cid;

    IF @ac_status IS NULL THROW 50001, '办理失败：账户不存在。', 1;
    IF @ac_status <> 1 THROW 50002, '办理失败：账户处于异常状态。', 1;
    IF @ac_type <> 1 THROW 50003, '办理失败：仅支持储蓄卡。', 1;
    IF @cur_bal < @money THROW 50004, '办理失败：账户余额不足。', 1;

    SELECT @current_rate = rate FROM deposit_rate WHERE [month] = @months;
    IF @current_rate IS NULL THROW 50042, '办理失败：不支持该存期。', 1;

    SET @did = 'DEP' + REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '-', ''), ' ', ''), ':', '') + CAST(FLOOR(RAND() * 99) AS VARCHAR(2));

    BEGIN TRY
        BEGIN TRANSACTION;
            UPDATE account SET cur_balance = cur_balance - @money WHERE cid = @cid;

            -- 插入时明确 dstatus = 1
            INSERT INTO deposit (did, cid, dnumber, drate, dstart, dover, dstatus)
            VALUES (@did, @cid, @money, @current_rate, GETDATE(), DATEADD(MONTH, @months, GETDATE()), 1);

        COMMIT TRANSACTION;
        SELECT 'SUCCESS' as status, '存款办理成功' as msg, @did as deposit_id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/*==============================================================*/
/* 3. 修改：定期存款取回 (sp_withdraw_deposit)                  */
/* 变更：不再 DELETE，而是 UPDATE dstatus = 2                   */
/*==============================================================*/
ALTER PROCEDURE sp_withdraw_deposit
    @did CHAR(20),
    @cid CHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @amount DECIMAL(18,2);
    DECLARE @rate DECIMAL(5,4);
    DECLARE @start DATE;
    DECLARE @end DATE;
    DECLARE @interest DECIMAL(18,2) = 0.00;
    DECLARE @ac_status INT;
    DECLARE @current_dstatus INT;

    -- 获取存单信息，同时获取当前状态
    SELECT @amount = dnumber, @rate = drate, @start = dstart, @end = dover, @current_dstatus = dstatus
    FROM deposit WHERE did = @did AND cid = @cid;

    IF @amount IS NULL THROW 50060, '取回失败：存单不存在或不属于该卡。', 1;
    
    -- 校验：如果已经是已取回状态(2)，则报错
    IF @current_dstatus = 2 THROW 50062, '取回失败：该存单已取回，请勿重复操作。', 1;

    SELECT @ac_status = astatus FROM account WHERE cid = @cid;
    IF @ac_status <> 1 THROW 50061, '取回失败：账户异常，无法入账。', 1;

    IF CAST(GETDATE() AS DATE) >= @end
        SET @interest = @amount * @rate * (DATEDIFF(DAY, @start, @end) / 365.0);
    ELSE
        SET @interest = 0.00;

    BEGIN TRY
        BEGIN TRANSACTION;
            UPDATE account 
            SET cur_balance = cur_balance + @amount + @interest 
            WHERE cid = @cid;

            -- 核心修改：软删除，更新状态为 2
            UPDATE deposit SET dstatus = 2 WHERE did = @did;

        COMMIT TRANSACTION;
        SELECT 'SUCCESS' as status, '取回成功！' as msg;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO