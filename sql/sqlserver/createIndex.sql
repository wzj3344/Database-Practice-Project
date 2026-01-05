-- 索引定义

USE [BankDB]
GO

/*==============================================================*/
/* 1. bank_user 表索引                                          */
/*==============================================================*/

-- idx_id_card: 身份证号唯一索引
-- 目的：用于快速检索和防止重复注册
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_id_card' AND object_id = OBJECT_ID('bank_user'))
    DROP INDEX idx_id_card ON bank_user;
GO
CREATE UNIQUE INDEX idx_id_card ON bank_user(shen_id);
GO


/*==============================================================*/
/* 2. account 表索引                                            */
/*==============================================================*/

-- idx_user_id: 用户ID索引
-- 目的：加快“查询某用户下所有账户”的速度
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_user_id' AND object_id = OBJECT_ID('account'))
    DROP INDEX idx_user_id ON account;
GO
CREATE INDEX idx_user_id ON account(bank_user_id);
GO


/*==============================================================*/
/* 3. transaction_record 表索引                                 */
/*==============================================================*/

-- idx_source_card_time: 复合索引 (send_cid, ttime)
-- 目的：快速查询某账户(作为发起方)特定时间段内的交易记录（账单查询）
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_source_card_time' AND object_id = OBJECT_ID('transaction_record'))
    DROP INDEX idx_source_card_time ON transaction_record;
GO
CREATE INDEX idx_source_card_time ON transaction_record(send_cid, ttime);
GO

-- idx_target_card_time: 复合索引 (get_cid, ttime)
-- 目的：快速查询某账户(作为接收方)特定时间段内的收入
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_target_card_time' AND object_id = OBJECT_ID('transaction_record'))
    DROP INDEX idx_target_card_time ON transaction_record;
GO
CREATE INDEX idx_target_card_time ON transaction_record(get_cid, ttime);
GO

-- idx_ttime: 时间索引
-- 目的：用于管理员进行全行交易统计
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_ttime' AND object_id = OBJECT_ID('transaction_record'))
    DROP INDEX idx_ttime ON transaction_record;
GO
CREATE INDEX idx_ttime ON transaction_record(ttime);
GO


/*==============================================================*/
/* 4. 理财与基金持有表索引                                      */
/*==============================================================*/

-- idx_account_holdings_prod: 理财持有索引
-- 目的：快速展示账户的理财投资组合
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_account_holdings_prod' AND object_id = OBJECT_ID('with_product'))
    DROP INDEX idx_account_holdings_prod ON with_product;
GO
CREATE INDEX idx_account_holdings_prod ON with_product(cid);
GO

-- idx_account_holdings_fund: 基金持有索引
-- 目的：快速展示账户的基金投资组合
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_account_holdings_fund' AND object_id = OBJECT_ID('with_fund'))
    DROP INDEX idx_account_holdings_fund ON with_fund;
GO
CREATE INDEX idx_account_holdings_fund ON with_fund(cid);
GO