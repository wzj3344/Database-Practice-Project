USE [BankDB]
GO

-- 1. 插入管理员 (admini)
INSERT INTO admini (aid, apassword) VALUES 
('admin001', 'admin_pass_1');

-- 用户1：张三
INSERT INTO bank_user (bank_user_id, shen_id, bank_user_name, passward, phone, reg_time) VALUES 
('U001', '430103199001010001', '张三', 'pass123', '13800000001', '2023-01-01 09:00:00');
-- 用户2：李四
INSERT INTO bank_user (bank_user_id, shen_id, bank_user_name, passward, phone, reg_time) VALUES 
('U002', '430103199202020002', '李四', 'pass456', '13900000002', '2023-02-01 10:30:00');
-- 用户3：王五
INSERT INTO bank_user (bank_user_id, shen_id, bank_user_name, passward, phone, reg_time) VALUES 
('U003', '430103199505050003', '王五', 'pass789', '13700000003', '2023-03-15 14:20:00');

INSERT INTO bank_user (bank_user_id, shen_id, bank_user_name, passward, phone, reg_time) VALUES 
('SYS_MERCHANT', '000000000000000000', '银行官方商户', 'admin_sys', '00000000000', '2023-01-01 00:00:00');

-- 张三的储蓄卡 (6222001)，状态正常
INSERT INTO account (cid, bank_user_id, cur_balance, transaction_limit, atype, astatus, open_time) VALUES 
('6222001', 'U001', 50000.00, 5000.00, 1, 1, '2023-01-02 09:00:00');
-- 张三的信用卡 (6222002)，状态正常
INSERT INTO account (cid, bank_user_id, cur_balance, transaction_limit, atype, astatus, open_time) VALUES 
('6222002', 'U001', 0.00, 10000.00, 2, 1, '2023-01-05 11:00:00');
-- 李四的储蓄卡 (6222003)，状态冻结 (astatus=3)
INSERT INTO account (cid, bank_user_id, cur_balance, transaction_limit, atype, astatus, open_time) VALUES 
('6222003', 'U002', 12000.00, 2000.00, 1, 3, '2023-02-02 10:00:00');
-- 王五的储蓄卡 (6222004)，状态正常
INSERT INTO account (cid, bank_user_id, cur_balance, transaction_limit, atype, astatus, open_time) VALUES 
('6222004', 'U003', 80000.00, 50000.00, 1, 1, '2023-03-16 09:30:00');

-- 卡号: 999999, 余额: 0, 限额: 很高, 状态: 正常
INSERT INTO account (cid, bank_user_id, cur_balance, transaction_limit, atype, astatus, open_time) VALUES 
('999999', 'SYS_MERCHANT', 0.00, 100000000.00, 1, 1, '2023-01-01 00:00:00');

INSERT INTO financial_product (pid, pname, pworth, pleast, prisk, pstatus) VALUES 
('FP001', '稳健理财A款', 1.02, 1000.00, 2, 1),
('FP002', '高息优选B款', 1.05, 50000.00, 4, 1),
('FP003', '已停售产品C', 1.10, 10000.00, 3, 0); -- pstatus=0 停售

INSERT INTO fund (fid, fname, fworth, fleast, frisk, fstatus) VALUES 
('FD001', '蓝筹成长混合', 2.56, 100.00, 3, 1),
('FD002', '科技先锋股票', 1.88, 100.00, 5, 1);

-- 张三办理了一笔定期存款
INSERT INTO deposit (did, cid, dnumber, drate, dstart, dover) VALUES 
('DEP001', '6222001', 10000.00, 0.0275, '2023-06-01', '2024-06-01');

-- 张三(6222001) 转账给 王五(6222004) 1000元，成功 (tstatus=1)
INSERT INTO transaction_record (tid, send_cid, get_cid, tmoney, tstatus, ttype, ttime) VALUES 
('TXN0001', '6222001', '6222004', 1000.00, 1, 1, '2023-05-20 10:00:00');

-- 张三(6222001) 消费 500元 (ttype=2)，成功
INSERT INTO transaction_record (tid, send_cid, get_cid, tmoney, tstatus, ttype, ttime) VALUES 
('TXN0002', '6222001', '999999', 500.00, 1, 2, '2023-05-21 14:30:00');

-- 王五(6222004) 发起大额转账，待审核 (tstatus=3)
INSERT INTO transaction_record (tid, send_cid, get_cid, tmoney, tstatus, ttype, ttime) VALUES 
('TXN0004', '6222004', '6222001', 60000.00, 3, 1, '2023-05-23 16:00:00');

-- 张三持有 FP001
INSERT INTO with_product (cid, pid, pnumber, ptime, buy_pspend, sold_pget) VALUES 
('6222001', 'FP001', 5000.00, '2023-04-01 10:00:00', 5100.00, 0.00);

-- 张三持有 FD001
INSERT INTO with_fund (cid, fid, fnumber, ftime, buy_fspend, sold_fget) VALUES 
('6222001', 'FD001', 1000.00, '2023-04-05 11:20:00', 2560.00, 0.00);

GO

-- 更新现有信用卡的额度（默认给 20000 额度），防止老数据无法透支
UPDATE account SET credit_limit = 20000 WHERE atype = 2;
GO

INSERT INTO deposit_rate ([month], [rate], [desc]) VALUES 
(3, 0.0150, '3个月'),
(6, 0.0175, '6个月'),
(12, 0.0200, '1年'),
(24, 0.0275, '2年');
GO