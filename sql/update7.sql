USE [BankDB]
GO

ALTER PROCEDURE sp_query_account
    @uid VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT cid, cur_balance, transaction_limit, credit_limit, atype,
           CASE atype WHEN 1 THEN '储蓄卡' WHEN 2 THEN '信用卡' END AS account_type,
           CASE astatus WHEN 1 THEN '正常' WHEN 2 THEN '挂失' WHEN 3 THEN '冻结' END AS account_status,
           open_time
    FROM account
    WHERE bank_user_id = @uid
    ORDER BY open_time DESC; -- 按时间倒序排列
END
GO

USE [BankDB]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_update_phone')
    DROP PROCEDURE sp_update_phone
GO

CREATE PROCEDURE sp_update_phone
    @uid VARCHAR(20),
    @password VARCHAR(20),
    @new_phone CHAR(11)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. 验证密码是否正确
    IF NOT EXISTS (SELECT 1 FROM bank_user WHERE bank_user_id = @uid AND passward = @password)
    BEGIN
        THROW 50030, '密码错误，无法修改手机号。', 1;
    END

    -- 2. 检查新手机号是否已被其他用户使用 (排除自己)
    IF EXISTS (SELECT 1 FROM bank_user WHERE phone = @new_phone AND bank_user_id != @uid)
    BEGIN
        THROW 50031, '该手机号已被注册，请更换。', 1;
    END

    -- 3. 执行更新
    BEGIN TRY
        UPDATE bank_user 
        SET phone = @new_phone 
        WHERE bank_user_id = @uid;

        PRINT '手机号修改成功';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO


USE [BankDB]
GO

ALTER PROCEDURE sp_transfer_transaction
    @send_cid CHAR(20),    -- 发起方卡号
    @get_cid CHAR(20),     -- 收款方卡号
    @money DECIMAL(18,2),  -- 金额
    @trans_type INT        -- 1:转账, 2:消费
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @tid CHAR(20);
    DECLARE @limit DECIMAL(18,2);
    DECLARE @s_status INT; -- 发起方状态
    DECLARE @r_status INT; -- 收款方状态
    
    DECLARE @cur_bal DECIMAL(18,2);
    DECLARE @cred_lim DECIMAL(18,2);
    DECLARE @ac_type INT;

    -- 新增：用于存储当日已交易总额
    DECLARE @today_spent DECIMAL(18,2);
    
    -- 【0. 基础校验】
    
    -- 1. 校验交易类型
    IF @trans_type NOT IN (1, 2) THROW 50001, '交易类型错误', 1;

    -- 2. 校验收款方是否存在及状态
    SELECT @r_status = astatus FROM account WHERE cid = @get_cid;
    
    IF @r_status IS NULL
    BEGIN
        THROW 50002, '交易失败：收款方/商户卡号不存在。', 1;
    END

    -- 检查收款方状态
    IF @r_status IN (2, 3)
    BEGIN
        THROW 50006, '交易失败：收款账户异常（挂失或冻结），无法入账。', 1;
    END

    -- 3. 校验发起方是否存在，并获取 余额、限额、透支额度、类型
    SELECT 
        @limit = transaction_limit, 
        @s_status = astatus,
        @cur_bal = cur_balance,
        @cred_lim = credit_limit,
        @ac_type = atype
    FROM account WHERE cid = @send_cid;
    
    IF @limit IS NULL THROW 50003, '交易失败：付款账户不存在。', 1;
        
    -- 4. 校验发起方状态
    IF @s_status != 1 THROW 50004, '交易失败：付款账户非正常状态（挂失或冻结）。', 1;

    -- 5. 余额/透支额度检查
    -- 储蓄卡: 余额 < 金额
    -- 信用卡: (余额 - 金额) < -信用额度
    IF (@ac_type = 1 AND @cur_bal < @money) 
       OR 
       (@ac_type = 2 AND (@cur_bal - @money) < -@cred_lim)
    BEGIN
        THROW 50005, '交易失败：账户余额不足 (或超出透支额度)。', 1;
    END

    -- 生成流水号
    SET @tid = 'TXN' + REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '-', ''), ' ', ''), ':', '') + CAST(FLOOR(RAND() * 999) AS VARCHAR(3));

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 6. 检查是否超过单日限额
        -- 修改逻辑：统计当日已成功交易总额 + 当前金额 > 限额
        
        -- 计算当日已用额度 (只统计成功的交易，状态为1)
        SELECT @today_spent = ISNULL(SUM(tmoney), 0)
        FROM transaction_record
        WHERE send_cid = @send_cid 
          AND tstatus = 1 
          AND DATEDIFF(day, ttime, GETDATE()) = 0; -- SQL Server 判断是否为同一天

        -- 判断是否超限
        IF (@today_spent + @money) > @limit
        BEGIN
            -- 超过限额，写入待审核记录 (tstatus=3)
            INSERT INTO transaction_record (tid, send_cid, get_cid, tmoney, tstatus, ttype, ttime)
            VALUES (@tid, @send_cid, @get_cid, @money, 3, @trans_type, GETDATE());
            
            COMMIT TRANSACTION;
            
            -- 返回 WARN 状态给后端
            SELECT 'WARN' as status, '交易后将超过单日累计限额，本次交易已提交审核。' as msg;
            RETURN;
        END

        -- 7. 正常交易 (扣款 + 入账)
        UPDATE account SET cur_balance = cur_balance - @money WHERE cid = @send_cid;
        UPDATE account SET cur_balance = cur_balance + @money WHERE cid = @get_cid;
        
        INSERT INTO transaction_record (tid, send_cid, get_cid, tmoney, tstatus, ttype, ttime)
        VALUES (@tid, @send_cid, @get_cid, @money, 1, @trans_type, GETDATE());

        COMMIT TRANSACTION;
        
        SELECT 'SUCCESS' as status, '交易成功！' as msg;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO