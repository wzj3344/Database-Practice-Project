-- ===============================
-- PostgreSQL 15 版本
-- BankDB 从库（仅结构）
-- ===============================

-- 创建数据库（需要在连接后执行）
-- 在 psql 中执行: CREATE DATABASE bankdb;

-- 切换到 bankdb 数据库
-- \c bankdb;

-- ===============================
-- 表：bank_user
-- ===============================
CREATE TABLE bank_user (
  bank_user_id VARCHAR(20) PRIMARY KEY,
  shen_id CHAR(18) NOT NULL UNIQUE,
  bank_user_name VARCHAR(20) NOT NULL,
  passward VARCHAR(20) NOT NULL,
  phone CHAR(11) NOT NULL,
  reg_time TIMESTAMP NOT NULL
);

CREATE INDEX idx_bank_user_shen_id ON bank_user(shen_id);

-- ===============================
-- 表：admini
-- ===============================
CREATE TABLE admini (
  aid VARCHAR(20) PRIMARY KEY,
  apassword VARCHAR(20) NOT NULL
);

-- ===============================
-- 表：account
-- ===============================
CREATE TABLE account (
  cid CHAR(20) PRIMARY KEY,
  bank_user_id VARCHAR(20) NOT NULL,
  cur_balance DECIMAL(18,2) NOT NULL,
  transaction_limit DECIMAL(18,2) NOT NULL,
  atype INT NOT NULL,
  astatus INT NOT NULL,
  open_time TIMESTAMP NOT NULL,
  credit_limit DECIMAL(18,2) NOT NULL DEFAULT 0.00
);

CREATE INDEX idx_account_user ON account(bank_user_id);

ALTER TABLE account
ADD CONSTRAINT fk_account_user
FOREIGN KEY (bank_user_id) REFERENCES bank_user(bank_user_id);

-- ===============================
-- 表：deposit
-- ===============================
CREATE TABLE deposit (
  did CHAR(20) PRIMARY KEY,
  cid CHAR(20) NOT NULL,
  dnumber DECIMAL(18,2) NOT NULL,
  drate DECIMAL(5,4) NOT NULL,
  dstart TIMESTAMP NOT NULL,
  dover TIMESTAMP NOT NULL,
  dstatus INT NOT NULL DEFAULT 1
);

CREATE INDEX idx_deposit_account ON deposit(cid);

ALTER TABLE deposit
ADD CONSTRAINT fk_deposit_account
FOREIGN KEY (cid) REFERENCES account(cid);

-- ===============================
-- 表：financial_product
-- ===============================
CREATE TABLE financial_product (
  pid CHAR(20) PRIMARY KEY,
  pname VARCHAR(20) NOT NULL,
  pworth DECIMAL(10,2) NOT NULL,
  pleast DECIMAL(10,2) NOT NULL,
  prisk INT NOT NULL,
  pstatus INT NOT NULL
);

-- ===============================
-- 表：fund
-- ===============================
CREATE TABLE fund (
  fid CHAR(20) PRIMARY KEY,
  fname VARCHAR(20) NOT NULL,
  fworth DECIMAL(10,2) NOT NULL,
  fleast DECIMAL(10,2) NOT NULL,
  frisk INT NOT NULL,
  fstatus INT NOT NULL
);

-- ===============================
-- 表：transaction_record
-- ===============================
CREATE TABLE transaction_record (
  tid CHAR(20) PRIMARY KEY,
  send_cid CHAR(20) NOT NULL,
  get_cid CHAR(20) NOT NULL,
  tmoney DECIMAL(18,2) NOT NULL,
  tstatus INT NOT NULL,
  ttype INT NOT NULL,
  ttime TIMESTAMP NOT NULL,
  audit_admin VARCHAR(20)
);

CREATE INDEX idx_tr_send ON transaction_record(send_cid);
CREATE INDEX idx_tr_get ON transaction_record(get_cid);

ALTER TABLE transaction_record
ADD CONSTRAINT fk_tr_send
FOREIGN KEY (send_cid) REFERENCES account(cid);

ALTER TABLE transaction_record
ADD CONSTRAINT fk_tr_get
FOREIGN KEY (get_cid) REFERENCES account(cid);

-- ===============================
-- 表：with_fund
-- ===============================
CREATE TABLE with_fund (
  cid CHAR(20) NOT NULL,
  fid CHAR(20) NOT NULL,
  fnumber DECIMAL(10,2) NOT NULL,
  ftime TIMESTAMP NOT NULL,
  buy_fspend DECIMAL(18,2) NOT NULL,
  sold_fget DECIMAL(18,2) NOT NULL,
  PRIMARY KEY (cid, fid)
);

ALTER TABLE with_fund
ADD CONSTRAINT fk_withfund_account
FOREIGN KEY (cid) REFERENCES account(cid);

ALTER TABLE with_fund
ADD CONSTRAINT fk_withfund_fund
FOREIGN KEY (fid) REFERENCES fund(fid);

-- ===============================
-- 表：with_product
-- ===============================
CREATE TABLE with_product (
  cid CHAR(20) NOT NULL,
  pid CHAR(20) NOT NULL,
  pnumber DECIMAL(10,2) NOT NULL,
  ptime TIMESTAMP NOT NULL,
  buy_pspend DECIMAL(18,2) NOT NULL,
  sold_pget DECIMAL(18,2) NOT NULL,
  PRIMARY KEY (cid, pid)
);

ALTER TABLE with_product
ADD CONSTRAINT fk_withproduct_account
FOREIGN KEY (cid) REFERENCES account(cid);

ALTER TABLE with_product
ADD CONSTRAINT fk_withproduct_product
FOREIGN KEY (pid) REFERENCES financial_product(pid);

-- ===============================
-- 添加注释（可选）
-- ===============================
COMMENT ON COLUMN account.credit_limit IS '信用额度';
COMMENT ON COLUMN deposit.dstatus IS '1:正常, 0:异常';
COMMENT ON COLUMN transaction_record.audit_admin IS '审核管理员';

COMMENT ON TABLE bank_user IS '银行用户表';
COMMENT ON TABLE admini IS '管理员表';
COMMENT ON TABLE account IS '账户表';
COMMENT ON TABLE deposit IS '存款表';
COMMENT ON TABLE financial_product IS '理财产品表';
COMMENT ON TABLE fund IS '基金表';
COMMENT ON TABLE transaction_record IS '交易记录表';
COMMENT ON TABLE with_fund IS '持有基金表';
COMMENT ON TABLE with_product IS '持有理财产品表';