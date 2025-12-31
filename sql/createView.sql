-- 视图定义

USE [BankDB]
GO

/*==============================================================*/
/* 3.1 交易流水明细视图 (v_transaction_detail)                  */
/* 对应需求：3.1.5 交易记录查询                                 */
/* 功能：整合交易记录与用户表，显示发起人和收款人的真实姓名     */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'v_transaction_detail')
    DROP VIEW v_transaction_detail
GO

CREATE VIEW v_transaction_detail AS
SELECT 
    tr.tid,
    tr.ttime,
    tr.ttype,   -- 1:转账, 2:消费
    tr.tmoney,
    tr.tstatus, -- 1:成功, 2:失败, 3:待审核
    -- 发起方信息
    tr.send_cid,
    u1.bank_user_name AS sender_name,
    -- 收款方信息
    tr.get_cid,
    u2.bank_user_name AS receiver_name
FROM 
    transaction_record tr
    -- 关联发起方账户及用户
    JOIN account a1 ON tr.send_cid = a1.cid
    JOIN bank_user u1 ON a1.bank_user_id = u1.bank_user_id
    -- 关联收款方账户及用户
    JOIN account a2 ON tr.get_cid = a2.cid
    JOIN bank_user u2 ON a2.bank_user_id = u2.bank_user_id;
GO

/*==============================================================*/
/* 3.2 信用卡月度账单视图 (v_credit_card_bill)                  */
/* 对应需求：3.1.5 信用卡账单                                   */
/* 功能：统计信用卡账户每月的消费总额                           */
/* 逻辑：筛选 atype=2(信用) 且 ttype=2(消费) 的记录             */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'v_credit_card_bill')
    DROP VIEW v_credit_card_bill
GO

CREATE VIEW v_credit_card_bill AS
SELECT 
    tr.send_cid AS card_number,
    YEAR(tr.ttime) AS bill_year,
    MONTH(tr.ttime) AS bill_month,
    SUM(tr.tmoney) AS total_expense,
    COUNT(tr.tid) AS transaction_count
FROM 
    transaction_record tr
    JOIN account a ON tr.send_cid = a.cid
WHERE 
    a.atype = 2       -- 信用卡
    AND tr.ttype = 2  -- 消费交易
    AND tr.tstatus = 1 -- 交易成功
GROUP BY 
    tr.send_cid, YEAR(tr.ttime), MONTH(tr.ttime);
GO

/*==============================================================*/
/* 3.3 待审核交易视图 (v_pending_audit)                         */
/* 对应需求：3.2 管理员功能 - 业务审核                          */
/* 功能：列出所有待审核的大额转账，带上用户信息以便联系         */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'v_pending_audit')
    DROP VIEW v_pending_audit
GO

CREATE VIEW v_pending_audit AS
SELECT 
    tr.tid,
    tr.ttime,
    tr.tmoney,
    tr.send_cid,
    u.bank_user_name AS sender_name,
    u.phone AS sender_phone, -- 方便管理员联系核实
    tr.get_cid
FROM 
    transaction_record tr
    JOIN account a ON tr.send_cid = a.cid
    JOIN bank_user u ON a.bank_user_id = u.bank_user_id
WHERE 
    tr.tstatus = 3; -- 待审核状态
GO

/*==============================================================*/
/* 3.4 存款收入视图 (v_deposit_income)                          */
/* 对应需求：3.1.5 投资收益 (存款部分)                          */
/* 功能：统计已到期存款产生的利息收益                           */
/* 计算公式：本金 * 利率 * (存款天数/365)                       */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'v_deposit_income')
    DROP VIEW v_deposit_income
GO

CREATE VIEW v_deposit_income AS
SELECT 
    d.cid,
    d.did,
    d.dnumber AS principal,   -- 本金
    d.drate,                  -- 利率
    d.dstart,
    d.dover,
    -- 计算预估收益：DATEDIFF算出天数，除以365得到年数
    CAST(d.dnumber * d.drate * (DATEDIFF(DAY, d.dstart, d.dover) / 365.0) AS DECIMAL(18,2)) AS interest_income
FROM 
    deposit d
WHERE 
    d.dover <= GETDATE(); -- 仅统计已到期的
GO

/*==============================================================*/
/* 3.5 投资持仓盈亏视图 (v_investment_profit)                   */
/* 对应需求：3.1.5 可视化统计                                   */
/* 功能：计算当前持有的理财和基金的浮动盈亏                     */
/* 公式：(当前净值 * 持有份额) + 已落袋收益 - 总投入成本        */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'v_investment_profit')
    DROP VIEW v_investment_profit
GO

CREATE VIEW v_investment_profit AS
-- 第一部分：理财产品盈亏
SELECT 
    wp.cid,
    '理财产品' AS investment_type,
    fp.pname AS product_name,
    wp.pnumber AS holding_shares,
    fp.pworth AS current_price,
    wp.buy_pspend AS total_cost,
    wp.sold_pget AS realized_profit, -- 已落袋收益
    -- 浮动盈亏计算
    CAST(
        (wp.pnumber * fp.pworth) + wp.sold_pget - wp.buy_pspend 
    AS DECIMAL(18,2)) AS profit_loss
FROM 
    with_product wp
    JOIN financial_product fp ON wp.pid = fp.pid

UNION ALL

-- 第二部分：基金盈亏
SELECT 
    wf.cid,
    '基金' AS investment_type,
    f.fname AS product_name,
    wf.fnumber AS holding_shares,
    f.fworth AS current_price,
    wf.buy_fspend AS total_cost,
    wf.sold_fget AS realized_profit,
    -- 浮动盈亏计算
    CAST(
        (wf.fnumber * f.fworth) + wf.sold_fget - wf.buy_fspend 
    AS DECIMAL(18,2)) AS profit_loss
FROM 
    with_fund wf
    JOIN fund f ON wf.fid = f.fid;
GO