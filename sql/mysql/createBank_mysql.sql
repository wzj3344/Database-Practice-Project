-- ===============================
-- MySQL 8.x 版本
-- BankDB 从库（仅结构）
-- ===============================

CREATE DATABASE IF NOT EXISTS bankdb
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

USE bankdb;

-- ===============================
-- 表：bank_user
-- ===============================
CREATE TABLE bank_user (
  bank_user_id VARCHAR(20) PRIMARY KEY,
  shen_id CHAR(18) NOT NULL UNIQUE,
  bank_user_name VARCHAR(20) NOT NULL,
  passward VARCHAR(20) NOT NULL,
  phone CHAR(11) NOT NULL,
  reg_time DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===============================
-- 表：admini
-- ===============================
CREATE TABLE admini (
  aid VARCHAR(20) PRIMARY KEY,
  apassword VARCHAR(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
  open_time DATETIME NOT NULL,
  INDEX idx_account_user (bank_user_id),
  CONSTRAINT fk_account_user
    FOREIGN KEY (bank_user_id) REFERENCES bank_user(bank_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===============================
-- 表：deposit
-- ===============================
CREATE TABLE deposit (
  did CHAR(20) PRIMARY KEY,
  cid CHAR(20) NOT NULL,
  dnumber DECIMAL(18,2) NOT NULL,
  drate DECIMAL(5,4) NOT NULL,
  dstart DATETIME NOT NULL,
  dover DATETIME NOT NULL,
  INDEX idx_deposit_account (cid),
  CONSTRAINT fk_deposit_account
    FOREIGN KEY (cid) REFERENCES account(cid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
  ttime DATETIME NOT NULL,
  INDEX idx_tr_send (send_cid),
  INDEX idx_tr_get (get_cid),
  CONSTRAINT fk_tr_send
    FOREIGN KEY (send_cid) REFERENCES account(cid),
  CONSTRAINT fk_tr_get
    FOREIGN KEY (get_cid) REFERENCES account(cid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===============================
-- 表：with_fund
-- ===============================
CREATE TABLE with_fund (
  cid CHAR(20) NOT NULL,
  fid CHAR(20) NOT NULL,
  fnumber DECIMAL(10,2) NOT NULL,
  ftime DATETIME NOT NULL,
  buy_fspend DECIMAL(18,2) NOT NULL,
  sold_fget DECIMAL(18,2) NOT NULL,
  PRIMARY KEY (cid, fid),
  CONSTRAINT fk_withfund_account
    FOREIGN KEY (cid) REFERENCES account(cid),
  CONSTRAINT fk_withfund_fund
    FOREIGN KEY (fid) REFERENCES fund(fid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===============================
-- 表：with_product
-- ===============================
CREATE TABLE with_product (
  cid CHAR(20) NOT NULL,
  pid CHAR(20) NOT NULL,
  pnumber DECIMAL(10,2) NOT NULL,
  ptime DATETIME NOT NULL,
  buy_pspend DECIMAL(18,2) NOT NULL,
  sold_pget DECIMAL(18,2) NOT NULL,
  PRIMARY KEY (cid, pid),
  CONSTRAINT fk_withproduct_account
    FOREIGN KEY (cid) REFERENCES account(cid),
  CONSTRAINT fk_withproduct_product
    FOREIGN KEY (pid) REFERENCES financial_product(pid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 1. 为 account 表添加 credit_limit 列
ALTER TABLE account 
ADD COLUMN credit_limit DECIMAL(18,2) NOT NULL DEFAULT 0.00 
COMMENT '信用额度';

-- 2. 为 deposit 表添加 dstatus 列
ALTER TABLE deposit 
ADD COLUMN dstatus INT NOT NULL DEFAULT 1 
COMMENT '1:正常, 0:异常';

-- 3. 为 transaction_record 表添加 audit_admin 列
ALTER TABLE transaction_record 
ADD COLUMN audit_admin VARCHAR(20) NULL 
COMMENT '审核管理员';