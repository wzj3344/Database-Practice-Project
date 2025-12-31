USE [BankDB]
GO

/*==============================================================*/
/* 1. 触发器：账户余额非负检查                                  */
/* 对应需求：2.2.1 账户余额非负检查                             */
/* 逻辑：当 account 表更新时，如果 cur_balance < 0，回滚并报错  */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_check_balance_negative')
    DROP TRIGGER trg_check_balance_negative
GO

CREATE TRIGGER trg_check_balance_negative
ON account
AFTER UPDATE
AS
BEGIN
    -- 设置不返回计数，提高性能
    SET NOCOUNT ON;

    -- 检查是否有更新后的余额小于0的记录
    IF EXISTS (SELECT 1 FROM inserted WHERE cur_balance < 0)
    BEGIN
        -- 回滚事务，取消刚才的操作
        ROLLBACK TRANSACTION;
        -- 抛出错误信息给应用程序 (Severity 16, State 1)
        RAISERROR ('交易失败：账户余额不足，不允许透支。', 16, 1);
        RETURN;
    END
END
GO

/*==============================================================*/
/* 2. 触发器：账户状态交易拦截                                  */
/* 对应需求：2.2.2 账户状态交易拦截                             */
/* 逻辑：当插入 transaction_record 时，检查 send_cid 的状态     */
/* 如果状态为 2(挂失) 或 3(冻结)，回滚并报错                    */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_prevent_frozen_transaction')
    DROP TRIGGER trg_prevent_frozen_transaction
GO

CREATE TRIGGER trg_prevent_frozen_transaction
ON transaction_record
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- 检查发起方账户状态
    -- 关联 inserted 表（新插入的交易）和 account 表
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN account a ON i.send_cid = a.cid
        WHERE a.astatus IN (2, 3) -- 2:挂失, 3:冻结
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR ('交易失败：发起方账户处于挂失或冻结状态，无法进行资金流出。', 16, 1);
        RETURN;
    END
END
GO

/*==============================================================*/
/* 3. 触发器：更新理财持有收益 (针对理财产品)                   */
/* 对应需求：2.2.3 更新理财持有收益                             */
/* 逻辑：当 with_product 表的 pnumber (持有份额) 减少时，       */
/* 自动计算收益：(旧份额 - 新份额) * 当前单位净值               */
/* 并将收益累加到 sold_pget 字段                                */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_update_product_profit')
    DROP TRIGGER trg_update_product_profit
GO

CREATE TRIGGER trg_update_product_profit
ON with_product
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 只有当持有份额 (pnumber) 发生变化时才执行逻辑
    IF UPDATE(pnumber)
    BEGIN
        -- 使用 CTE 或直接连接更新
        -- 逻辑：新的收益 = 原有收益 + (卖出的份额 * 当前最新净值)
        -- 注意：我们需要连接 deleted(更新前) 和 inserted(更新后) 表来计算差值
        
        UPDATE wp
        SET sold_pget = i.sold_pget + ((d.pnumber - i.pnumber) * fp.pworth)
        FROM with_product wp
        JOIN inserted i ON wp.cid = i.cid AND wp.pid = i.pid
        JOIN deleted d ON wp.cid = d.cid AND wp.pid = d.pid
        JOIN financial_product fp ON wp.pid = fp.pid
        WHERE d.pnumber > i.pnumber; -- 仅当份额减少（即卖出）时触发
    END
END
GO

/*==============================================================*/
/* 4. 触发器：更新基金持有收益 (针对基金，逻辑同上)             */
/* 对应需求：2.2.3 (补充基金部分)                               */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_update_fund_profit')
    DROP TRIGGER trg_update_fund_profit
GO

CREATE TRIGGER trg_update_fund_profit
ON with_fund
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(fnumber)
    BEGIN
        UPDATE wf
        SET sold_fget = i.sold_fget + ((d.fnumber - i.fnumber) * f.fworth)
        FROM with_fund wf
        JOIN inserted i ON wf.cid = i.cid AND wf.fid = i.fid
        JOIN deleted d ON wf.cid = d.cid AND wf.fid = d.fid
        JOIN fund f ON wf.fid = f.fid
        WHERE d.fnumber > i.fnumber; -- 仅当份额减少时触发
    END
END
GO