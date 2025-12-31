USE BankDB
GO

-- 给交易表增加 audit_admin 字段，用于区分是由管理员审核过的交易
ALTER TABLE transaction_record ADD audit_admin VARCHAR(20) NULL;
GO

-- 创建“已审核交易”视图
-- 逻辑：状态为 1(成功)或2(失败)，且 audit_admin 不为空
CREATE VIEW v_audited_log AS
SELECT 
    tr.tid,
    tr.ttime,
    tr.tmoney,
    tr.send_cid,
    tr.tstatus, -- 1通过 2驳回
    tr.audit_admin, -- 审核人
    u.bank_user_name AS sender_name,
    tr.get_cid
FROM 
    transaction_record tr
    JOIN account a ON tr.send_cid = a.cid
    JOIN bank_user u ON a.bank_user_id = u.bank_user_id
WHERE 
    tr.tstatus IN (1, 2) AND tr.audit_admin IS NOT NULL;
GO

-- 审核的存储过程
ALTER PROCEDURE sp_audit_transaction
    @tid CHAR(20),
    @result INT, -- 1通过, 2驳回
    @aid VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @money DECIMAL(18,2);
    DECLARE @sender CHAR(20);
    DECLARE @receiver CHAR(20);
    DECLARE @current_status INT;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 获取交易详情并锁行
        SELECT @money = tmoney, @sender = send_cid, @receiver = get_cid, @current_status = tstatus
        FROM transaction_record WITH (UPDLOCK)
        WHERE tid = @tid;

        IF @current_status IS NULL THROW 50005, '交易记录不存在', 1;
        IF @current_status != 3 THROW 50006, '该交易不是待审核状态', 1;

        IF @result = 2 -- 驳回
        BEGIN
            -- 记录审核员ID
            UPDATE transaction_record SET tstatus = 2, audit_admin = @aid WHERE tid = @tid;
        END
        ELSE IF @result = 1 -- 通过
        BEGIN
            -- 执行实质转账
            UPDATE account SET cur_balance = cur_balance - @money WHERE cid = @sender;
            UPDATE account SET cur_balance = cur_balance + @money WHERE cid = @receiver;
            -- 记录审核员ID
            UPDATE transaction_record SET tstatus = 1, audit_admin = @aid WHERE tid = @tid;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        -- 抛出错误以便后端捕获（例如余额不足）
        THROW; 
    END CATCH
END
GO

-- 撤回审核存储过程
CREATE PROCEDURE sp_revoke_audit
    @tid CHAR(20),
    @admin_id VARCHAR(20) -- 执行撤回的管理员
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @current_status INT;
    DECLARE @money DECIMAL(18,2);
    DECLARE @sender CHAR(20);
    DECLARE @receiver CHAR(20);

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. 获取当前状态
        SELECT @current_status = tstatus, @money = tmoney, @sender = send_cid, @receiver = get_cid
        FROM transaction_record WITH (UPDLOCK)
        WHERE tid = @tid;

        -- 2. 校验是否允许撤回
        IF @current_status NOT IN (1, 2)
        BEGIN
            THROW 50007, '当前交易状态无法撤回（非已审核状态）', 1;
        END

        -- 3. 如果原状态是“成功(1)”，则需要资金逆向划转（冲正）
        IF @current_status = 1
        BEGIN
            -- 收款方扣款（如果余额不足，触发器 trg_check_balance_negative 会报错回滚）
            UPDATE account SET cur_balance = cur_balance - @money WHERE cid = @receiver;
            -- 发起方回款
            UPDATE account SET cur_balance = cur_balance + @money WHERE cid = @sender;
        END

        -- 4. 状态重置为“待审核(3)”，并清空审核员字段
        UPDATE transaction_record 
        SET tstatus = 3, audit_admin = NULL 
        WHERE tid = @tid;

        COMMIT TRANSACTION;
        PRINT '撤回成功，交易已恢复为待审核状态。';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        -- 这里会捕获触发器的“余额不足”错误并返回给前端
        THROW;
    END CATCH
END
GO