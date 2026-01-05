USE [BankDB]
GO

-- 增加 credit_limit 字段，默认为 0
ALTER TABLE account ADD credit_limit DECIMAL(18,2) NOT NULL DEFAULT 0;
GO

-- 更新现有信用卡的额度（默认给 20000 额度），防止老数据无法透支
UPDATE account SET credit_limit = 20000 WHERE atype = 2;
GO

USE [BankDB]
GO

ALTER TRIGGER trg_check_balance_negative
ON account
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. 检查储蓄卡 (atype=1)：余额不能小于 0
    IF EXISTS (SELECT 1 FROM inserted WHERE atype = 1 AND cur_balance < 0)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50020, '交易失败：储蓄账户余额不足，不允许透支。', 1;
        RETURN;
    END

    -- 2. 检查信用卡 (atype=2)：余额不能小于 -credit_limit
    -- 例如：额度 20000，则余额最低只能是 -20000
    IF EXISTS (SELECT 1 FROM inserted WHERE atype = 2 AND cur_balance < -credit_limit)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50021, '交易失败：信用卡透支超过信用额度。', 1;
        RETURN;
    END
END
GO

USE [BankDB]
GO

ALTER PROCEDURE sp_open_account
    @uid VARCHAR(20),
    @atype INT -- 1储蓄，2信用
    -- 删除 @limit 参数
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @new_cid CHAR(20);
    DECLARE @init_credit_limit DECIMAL(18,2);
    DECLARE @default_trans_limit DECIMAL(18,2) = 20000.00; -- 默认交易限额 2万

    -- 设置初始信用额度
    IF @atype = 2 
        SET @init_credit_limit = 20000.00; -- 信用卡默认 2万 透支额度
    ELSE
        SET @init_credit_limit = 0.00;     -- 储蓄卡无透支额度
    
    -- 生成唯一卡号
    SET @new_cid = '622' + RIGHT(REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '-', ''), ' ', ''), ':', ''), 6) + CAST(FLOOR(RAND() * 9000 + 1000) AS VARCHAR(4));
    WHILE EXISTS (SELECT 1 FROM account WHERE cid = @new_cid)
    BEGIN
         SET @new_cid = '622' + RIGHT(REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '-', ''), ' ', ''), ':', ''), 6) + CAST(FLOOR(RAND() * 9000 + 1000) AS VARCHAR(4));
    END

    BEGIN TRY
        INSERT INTO account (cid, bank_user_id, cur_balance, transaction_limit, credit_limit, atype, astatus, open_time)
        VALUES (@new_cid, @uid, 0.00, @default_trans_limit, @init_credit_limit, @atype, 1, GETDATE());

        SELECT '开户成功' AS msg, @new_cid AS card_number;
    END TRY
    BEGIN CATCH
        THROW; 
    END CATCH
END
GO

USE [BankDB]
GO

ALTER PROCEDURE sp_update_account_limit
    @cid CHAR(20),
    @new_trans_limit DECIMAL(18,2), -- 原交易限额
    @new_credit_limit DECIMAL(18,2) = NULL -- 新增：信用额度 (默认NULL，兼容旧调用)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM account WHERE cid = @cid)
    BEGIN
        THROW 50001, '账户不存在。', 1;
    END

    -- 更新逻辑：
    -- 1. 总是更新交易限额 (transaction_limit)
    -- 2. 如果传入了 new_credit_limit 且不为 NULL，则更新信用额度 (credit_limit)
    --    注意：这里暂不强制检查 atype，由后端或前端逻辑控制储蓄卡不传 credit_limit 即可
    
    UPDATE account 
    SET transaction_limit = @new_trans_limit,
        credit_limit = ISNULL(@new_credit_limit, credit_limit)
    WHERE cid = @cid;

    PRINT '账户额度已更新。';
END
GO