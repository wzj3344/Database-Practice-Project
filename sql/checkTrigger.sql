USE [BankDB]
GO

-- 尝试强行将张三余额改为 -100
UPDATE account SET cur_balance = -100 WHERE cid = '6222001';
-- 预期结果：报错 "交易失败：账户余额不足，不允许透支。"

-- 尝试让李四（冻结状态）发起一笔转账
INSERT INTO transaction_record (tid, send_cid, get_cid, tmoney, tstatus, ttype, ttime) 
VALUES ('TEST_FAIL', '6222003', '6222001', 10.00, 1, 1, GETDATE());
-- 预期结果：报错 "交易失败：发起方账户处于挂失或冻结状态..."

-- 1. 查看张三理财当前收益 (假设是 0)
SELECT * FROM with_product WHERE cid = '6222001' AND pid = 'FP001';

-- 2. 模拟张三卖出 1000 份理财 (Update pnumber 减少 1000)
-- 注意：理财 FP001 的当前净值是 1.02 (在 insertData.sql 中定义)
-- 预期增加收益：1000 * 1.02 = 1020 元
UPDATE with_product SET pnumber = pnumber - 1000 WHERE cid = '6222001' AND pid = 'FP001';

-- 3. 再次查询，查看 sold_pget 是否自动变成了 1020.00
SELECT * FROM with_product WHERE cid = '6222001' AND pid = 'FP001';