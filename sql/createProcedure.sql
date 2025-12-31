USE [BankDB]
GO

/*==============================================================*/
/* 2.1.1 用户注册 (sp_user_register)                            */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_user_register')
    DROP PROCEDURE sp_user_register
GO

CREATE PROCEDURE sp_user_register
    @uid VARCHAR(20),
    @uname VARCHAR(20),
    @id_card CHAR(18),
    @pwd VARCHAR(20),
    @phone CHAR(11)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- 1. 检查身份证号是否已存在
        IF EXISTS (SELECT 1 FROM bank_user WHERE shen_id = @id_card)
        BEGIN
            PRINT '注册失败：该身份证号已被注册。';
            RETURN;
        END

        -- 2. 检查用户ID是否已存在
        IF EXISTS (SELECT 1 FROM bank_user WHERE bank_user_id = @uid)
        BEGIN
            PRINT '注册失败：该用户ID已存在。';
            RETURN;
        END

        -- 3. 插入新用户
        INSERT INTO bank_user (bank_user_id, shen_id, bank_user_name, passward, phone, reg_time)
        VALUES (@uid, @id_card, @uname, @pwd, @phone, GETDATE());

        PRINT '注册成功！';
    END TRY
    BEGIN CATCH
        PRINT '注册发生错误：' + ERROR_MESSAGE();
    END CATCH
END
GO

/*==============================================================*/
/* 2.1.2 重置密码 (sp_reset_password)                           */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_reset_password')
    DROP PROCEDURE sp_reset_password
GO

CREATE PROCEDURE sp_reset_password
    @uid VARCHAR(20),
    @new_pwd VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM bank_user WHERE bank_user_id = @uid)
    BEGIN
        PRINT '用户不存在。';
        RETURN;
    END

    UPDATE bank_user 
    SET passward = @new_pwd 
    WHERE bank_user_id = @uid;

    PRINT '密码重置成功。';
END
GO

/*==============================================================*/
/* 2.1.3 账户开设 (sp_open_account)                             */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_open_account')
    DROP PROCEDURE sp_open_account
GO

CREATE PROCEDURE sp_open_account
    @uid VARCHAR(20),
    @atype INT, -- 1储蓄，2信用
    @limit DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @new_cid CHAR(20);
    
    -- 简单的卡号生成逻辑：622 + 时间戳后6位 + 随机4位 (模拟)
    -- 实际生产中应有更严格的发号器
    SET @new_cid = '622' + RIGHT(REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '-', ''), ' ', ''), ':', ''), 6) + CAST(FLOOR(RAND() * 9000 + 1000) AS VARCHAR(4));

    -- 循环确保卡号唯一
    WHILE EXISTS (SELECT 1 FROM account WHERE cid = @new_cid)
    BEGIN
         SET @new_cid = '622' + RIGHT(REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '-', ''), ' ', ''), ':', ''), 6) + CAST(FLOOR(RAND() * 9000 + 1000) AS VARCHAR(4));
    END

    BEGIN TRY
        INSERT INTO account (cid, bank_user_id, cur_balance, transaction_limit, atype, astatus, open_time)
        VALUES (@new_cid, @uid, 0.00, @limit, @atype, 1, GETDATE()); -- 默认余额0，状态1正常

        SELECT '开户成功' AS msg, @new_cid AS card_number;
    END TRY
    BEGIN CATCH
        SELECT '开户失败' AS msg, ERROR_MESSAGE() AS error;
    END CATCH
END
GO

/*==============================================================*/
/* 2.1.4 账户查询 (sp_query_account)                            */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_query_account')
    DROP PROCEDURE sp_query_account
GO

CREATE PROCEDURE sp_query_account
    @uid VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    -- 利用 idx_user_id 索引查询
    SELECT cid, cur_balance, transaction_limit, 
           CASE atype WHEN 1 THEN '储蓄卡' WHEN 2 THEN '信用卡' END AS account_type,
           CASE astatus WHEN 1 THEN '正常' WHEN 2 THEN '挂失' WHEN 3 THEN '冻结' END AS account_status,
           open_time
    FROM account
    WHERE bank_user_id = @uid;
END
GO

/*==============================================================*/
/* 2.1.5 银行卡状态管理 (sp_manage_card_status)                 */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_manage_card_status')
    DROP PROCEDURE sp_manage_card_status
GO

CREATE PROCEDURE sp_manage_card_status
    @cid CHAR(20),
    @target_status INT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM account WHERE cid = @cid)
    BEGIN
        PRINT '卡号不存在。';
        RETURN;
    END

    UPDATE account SET astatus = @target_status WHERE cid = @cid;
    PRINT '账户状态已更新。';
END
GO

/*==============================================================*/
/* 2.1.6 资金交易/消费 (sp_transfer_transaction)                */
/* 核心逻辑：转账或消费 + 自动触发审核机制                      */
/* 修改说明：增加 @trans_type 参数以支持消费(2)                 */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_transfer_transaction')
    DROP PROCEDURE sp_transfer_transaction
GO

CREATE PROCEDURE sp_transfer_transaction
    @send_cid CHAR(20),    -- 发起方卡号
    @get_cid CHAR(20),     -- 收款方卡号 (若是消费，则是商户号)
    @money DECIMAL(18,2),  -- 金额
    @trans_type INT        -- 1:转账, 2:消费
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @tid CHAR(20);
    DECLARE @limit DECIMAL(18,2);
    
    -- 校验交易类型参数
    IF @trans_type NOT IN (1, 2)
    BEGIN
        PRINT '交易类型错误：只能为 1(转账) 或 2(消费)';
        RETURN;
    END

    -- 生成交易流水号
    SET @tid = 'TXN' + REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '-', ''), ' ', ''), ':', '') + CAST(FLOOR(RAND() * 999) AS VARCHAR(3));

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. 检查发起方是否存在及限额
        SELECT @limit = transaction_limit FROM account WHERE cid = @send_cid;
        IF @limit IS NULL
        BEGIN
            THROW 50001, '发起账户不存在', 1;
        END

        -- 2. 检查是否超过限额
        -- 逻辑补充：如果超过限额，不直接报错，而是转入“待审核”状态 (tstatus=3)
        IF @money > @limit
        BEGIN
            INSERT INTO transaction_record (tid, send_cid, get_cid, tmoney, tstatus, ttype, ttime)
            VALUES (@tid, @send_cid, @get_cid, @money, 3, @trans_type, GETDATE()); -- tstatus=3:待审核
            
            COMMIT TRANSACTION;
            PRINT '金额超过单日限额，交易已提交审核，请联系管理员。';
            RETURN;
        END

        -- 3. 正常交易逻辑 (tstatus=1)
        -- 3.1 扣款 (余额检查由触发器 trg_check_balance_negative 负责)
        -- 如果触发器报错，会直接跳到 CATCH 块
        UPDATE account SET cur_balance = cur_balance - @money WHERE cid = @send_cid;
        
        -- 3.2 入账
        UPDATE account SET cur_balance = cur_balance + @money WHERE cid = @get_cid;
        
        -- 3.3 记录流水
        INSERT INTO transaction_record (tid, send_cid, get_cid, tmoney, tstatus, ttype, ttime)
        VALUES (@tid, @send_cid, @get_cid, @money, 1, @trans_type, GETDATE()); -- 使用传入的类型

        COMMIT TRANSACTION;
        PRINT '交易成功！';
    END TRY
    BEGIN CATCH
        -- 优化错误处理：
        -- 如果触发器已经回滚了事务，@@TRANCOUNT 可能为 0，此时再 ROLLBACK 会报错
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END
        
        -- 打印具体的错误信息（包含触发器抛出的错误）
        PRINT '交易失败：' + ERROR_MESSAGE();
    END CATCH
END
GO

/*==============================================================*/
/* 2.1.7 理财/基金购买 (sp_purchase_investment)                 */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_purchase_investment')
    DROP PROCEDURE sp_purchase_investment
GO

CREATE PROCEDURE sp_purchase_investment
    @cid CHAR(20),
    @item_id CHAR(20), -- pid or fid
    @amount DECIMAL(18,2), -- 购买金额
    @type INT -- 1:理财, 2:基金
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @price DECIMAL(10,2);
    DECLARE @shares DECIMAL(10,2);
    DECLARE @least DECIMAL(10,2);

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. 获取产品信息
        IF @type = 1 -- 理财
        BEGIN
            SELECT @price = pworth, @least = pleast FROM financial_product WHERE pid = @item_id;
            IF @price IS NULL THROW 50002, '理财产品不存在', 1;
        END
        ELSE -- 基金
        BEGIN
            SELECT @price = fworth, @least = fleast FROM fund WHERE fid = @item_id;
            IF @price IS NULL THROW 50003, '基金产品不存在', 1;
        END

        -- 2. 检查起购份额 (假设 amount 是金额，这里需要换算，或者假设文档意思amount是份额？通常amount指钱)
        -- 修正：根据文档"起购份额"，我们计算份额 = 金额 / 净值
        SET @shares = @amount / @price;
        
        IF @shares < @least
        BEGIN
            THROW 50004, '购买金额不足以支付起购份额', 1;
        END

        -- 3. 扣款
        UPDATE account SET cur_balance = cur_balance - @amount WHERE cid = @cid;

        -- 4. 更新持仓 (使用 MERGE 或 IF EXISTS)
        IF @type = 1 -- 理财
        BEGIN
            IF EXISTS (SELECT 1 FROM with_product WHERE cid = @cid AND pid = @item_id)
                UPDATE with_product 
                SET pnumber = pnumber + @shares, buy_pspend = buy_pspend + @amount 
                WHERE cid = @cid AND pid = @item_id;
            ELSE
                INSERT INTO with_product (cid, pid, pnumber, ptime, buy_pspend, sold_pget)
                VALUES (@cid, @item_id, @shares, GETDATE(), @amount, 0.00);
        END
        ELSE -- 基金
        BEGIN
            IF EXISTS (SELECT 1 FROM with_fund WHERE cid = @cid AND fid = @item_id)
                UPDATE with_fund 
                SET fnumber = fnumber + @shares, buy_fspend = buy_fspend + @amount 
                WHERE cid = @cid AND fid = @item_id;
            ELSE
                INSERT INTO with_fund (cid, fid, fnumber, ftime, buy_fspend, sold_fget)
                VALUES (@cid, @item_id, @shares, GETDATE(), @amount, 0.00);
        END

        COMMIT TRANSACTION;
        PRINT '申购成功！';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT '申购失败：' + ERROR_MESSAGE();
    END CATCH
END
GO

/*==============================================================*/
/* 2.1.8 定期存款办理 (sp_create_deposit)                       */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_create_deposit')
    DROP PROCEDURE sp_create_deposit
GO

CREATE PROCEDURE sp_create_deposit
    @cid CHAR(20),
    @money DECIMAL(18,2),
    @rate DECIMAL(5,4),
    @months INT -- 存款月数
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @did CHAR(20);
    SET @did = 'DEP' + REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '-', ''), ' ', ''), ':', '') + CAST(FLOOR(RAND() * 99) AS VARCHAR(2));

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. 扣除活期余额
        UPDATE account SET cur_balance = cur_balance - @money WHERE cid = @cid;

        -- 2. 插入存单记录
        INSERT INTO deposit (did, cid, dnumber, drate, dstart, dover)
        VALUES (@did, @cid, @money, @rate, GETDATE(), DATEADD(MONTH, @months, GETDATE()));

        COMMIT TRANSACTION;
        SELECT '存款办理成功' AS msg, @did AS deposit_id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT '存款办理失败：' + ERROR_MESSAGE();
    END CATCH
END
GO

/*==============================================================*/
/* 2.1.9 交易审核 (sp_audit_transaction)                        */
/* 功能：管理员审核大额交易。通过后才真正划转资金               */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_audit_transaction')
    DROP PROCEDURE sp_audit_transaction
GO

CREATE PROCEDURE sp_audit_transaction
    @tid CHAR(20),
    @result INT, -- 1通过, 2驳回
    @aid VARCHAR(20) -- 管理员ID (日志留存用，本系统简化未单独建日志表)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @money DECIMAL(18,2);
    DECLARE @sender CHAR(20);
    DECLARE @receiver CHAR(20);
    DECLARE @current_status INT;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 获取交易详情
        SELECT @money = tmoney, @sender = send_cid, @receiver = get_cid, @current_status = tstatus
        FROM transaction_record WITH (UPDLOCK) -- 锁行
        WHERE tid = @tid;

        IF @current_status IS NULL
        BEGIN
            THROW 50005, '交易记录不存在', 1;
        END

        IF @current_status != 3
        BEGIN
            THROW 50006, '该交易不是待审核状态', 1;
        END

        IF @result = 2 -- 驳回
        BEGIN
            UPDATE transaction_record SET tstatus = 2 WHERE tid = @tid;
            PRINT '交易已驳回。';
        END
        ELSE IF @result = 1 -- 通过
        BEGIN
            -- 执行实质转账
            UPDATE account SET cur_balance = cur_balance - @money WHERE cid = @sender;
            UPDATE account SET cur_balance = cur_balance + @money WHERE cid = @receiver;
            
            UPDATE transaction_record SET tstatus = 1 WHERE tid = @tid;
            PRINT '审核通过，资金已划转。';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT '审核操作失败：' + ERROR_MESSAGE();
    END CATCH
END
GO

/*==============================================================*/
/* 2.1.10 发布理财产品 (sp_add_product)                         */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_add_product')
    DROP PROCEDURE sp_add_product
GO

CREATE PROCEDURE sp_add_product
    @pid CHAR(20),
    @pname VARCHAR(20),
    @pworth DECIMAL(10,2),
    @pleast DECIMAL(10,2),
    @prisk INT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM financial_product WHERE pid = @pid)
    BEGIN
        PRINT '产品ID已存在。';
        RETURN;
    END

    IF @prisk < 1 OR @prisk > 5
    BEGIN
        PRINT '风险等级必须在 1-5 之间。';
        RETURN;
    END

    INSERT INTO financial_product (pid, pname, pworth, pleast, prisk, pstatus)
    VALUES (@pid, @pname, @pworth, @pleast, @prisk, 1); -- 默认 1:在售

    PRINT '产品发布成功。';
END
GO

/*==============================================================*/
/* 2.1.11 更新理财产品信息 (sp_update_product)                  */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_update_product')
    DROP PROCEDURE sp_update_product
GO

CREATE PROCEDURE sp_update_product
    @pid CHAR(20),
    @pstatus INT = NULL, -- 可选参数
    @pworth DECIMAL(10,2) = NULL -- 可选参数
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM financial_product WHERE pid = @pid)
    BEGIN
        PRINT '产品不存在。';
        RETURN;
    END

    -- 动态更新
    UPDATE financial_product
    SET pstatus = ISNULL(@pstatus, pstatus),
        pworth = ISNULL(@pworth, pworth)
    WHERE pid = @pid;

    PRINT '产品信息已更新。';
END
GO