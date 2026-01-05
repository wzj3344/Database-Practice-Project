/*==============================================================*/
/* DBMS name:      Microsoft SQL Server 2012                    */
/* Created on:     2025/11/29 0:49:04                           */
/*==============================================================*/

USE master
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'BankDB')
BEGIN
    ALTER DATABASE BankDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE
    DROP DATABASE BankDB
END
GO

CREATE DATABASE BankDB
GO

USE BankDB
GO

-- 如果数据库已存在，修改排序规则
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'BankDB')
BEGIN
    ALTER DATABASE BankDB COLLATE Chinese_PRC_CI_AS;
    PRINT '已修改数据库排序规则为 Chinese_PRC_CI_AS';
END
GO

/*==============================================================*/
/* Table: account                                               */
/*==============================================================*/
create table account (
   cid                  char(20)             not null,
   bank_user_id         varchar(20)          not null,
   cur_balance          decimal(18,2)        not null,
   transaction_limit    decimal(18,2)        not null,
   atype                int                  not null, -- 1储蓄，2信用
   astatus              int                  not null, -- 1正常, 2挂失, 3冻结
   open_time            datetime             not null,
   constraint PK_ACCOUNT primary key nonclustered (cid)
)
go

/*==============================================================*/
/* Index: own_FK                                                */
/*==============================================================*/
create index own_FK on account (
bank_user_id ASC
)
go

/*==============================================================*/
/* Table: admini                                                */
/*==============================================================*/
create table admini (
   aid                  varchar(20)          not null,
   apassword            varchar(20)          not null,
   constraint PK_ADMINI primary key nonclustered (aid)
)
go

/*==============================================================*/
/* Table: bank_user                                             */
/*==============================================================*/
create table bank_user (
   bank_user_id         varchar(20)          not null,
   shen_id              char(18)             not null,
   bank_user_name       varchar(20)          not null,
   passward             varchar(20)          not null,
   phone                char(11)             not null,
   reg_time             datetime             not null,
   constraint PK_BANK_USER primary key nonclustered (bank_user_id),
   constraint AK_KEY_2_BANK_USE unique (shen_id)
)
go

/*==============================================================*/
/* Table: deposit                                               */
/*==============================================================*/
create table deposit (
   did                  char(20)             not null,
   cid                  char(20)             not null,
   dnumber              decimal(18,2)        not null,
   drate                decimal(5,4)         not null,
   dstart               datetime             not null,
   dover                datetime             not null,
   constraint PK_DEPOSIT primary key nonclustered (did)
)
go

/*==============================================================*/
/* Index: own_deposit_FK                                        */
/*==============================================================*/
create index own_deposit_FK on deposit (
cid ASC
)
go

/*==============================================================*/
/* Table: financial_product                                     */
/*==============================================================*/
create table financial_product (
   pid                  char(20)             not null,
   pname                varchar(20)          not null,
   pworth               decimal(10,2)        not null,
   pleast               decimal(10,2)        not null,
   prisk                int                  not null, -- 1~5
   pstatus              int                  not null, -- 1在售，0停售
   constraint PK_FINANCIAL_PRODUCT primary key nonclustered (pid)
)
go

/*==============================================================*/
/* Table: fund                                                  */
/*==============================================================*/
create table fund (
   fid                  char(20)             not null,
   fname                varchar(20)          not null,
   fworth               decimal(10,2)        not null,
   fleast               decimal(10,2)        not null,
   frisk                int                  not null,
   fstatus              int                  not null,
   constraint PK_FUND primary key nonclustered (fid)
)
go

/*==============================================================*/
/* Table: transaction_record                                    */
/*==============================================================*/
create table transaction_record (
   tid                  char(20)             not null,
   send_cid             char(20)             not null,
   get_cid              char(20)             not null,
   tmoney               decimal(18,2)        not null,
   tstatus              int                  not null, -- 1:成功, 2:失败, 3:待审核
   ttype                int                  not null, -- 1:转账, 2:消费
   ttime                datetime             not null,
   constraint PK_TRANSACTION_RECORD primary key nonclustered (tid)
)
go

/*==============================================================*/
/* Index: in_FK                                                 */
/*==============================================================*/
create index in_FK on transaction_record (
send_cid ASC
)
go

/*==============================================================*/
/* Index: out_FK                                                */
/*==============================================================*/
create index out_FK on transaction_record (
get_cid ASC
)
go

/*==============================================================*/
/* Table: with_fund                                             */
/*==============================================================*/
create table with_fund (
   cid                  char(20)             not null,
   fid                  char(20)             not null,
   fnumber              decimal(10,2)        not null,
   ftime                datetime             not null,
   buy_fspend           decimal(18,2)        not null,
   sold_fget            decimal(18,2)        not null,
   constraint PK_WITH_FUND primary key nonclustered (cid, fid)
)
go

/*==============================================================*/
/* Index: with_fund2_FK                                         */
/*==============================================================*/
create index with_fund2_FK on with_fund (
cid ASC
)
go

/*==============================================================*/
/* Index: with_fund_FK                                          */
/*==============================================================*/
create index with_fund_FK on with_fund (
fid ASC
)
go

/*==============================================================*/
/* Table: with_product                                          */
/*==============================================================*/
create table with_product (
   cid                  char(20)             not null,
   pid                  char(20)             not null,
   pnumber              decimal(10,2)        not null,
   ptime                datetime             not null,
   buy_pspend           decimal(18,2)        not null,
   sold_pget            decimal(18,2)        not null,
   constraint PK_WITH_PRODUCT primary key nonclustered (cid, pid)
)
go

/*==============================================================*/
/* Index: with_product2_FK                                      */
/*==============================================================*/
create index with_product2_FK on with_product (
cid ASC
)
go

/*==============================================================*/
/* Index: with_product_FK                                       */
/*==============================================================*/
create index with_product_FK on with_product (
pid ASC
)
go

alter table account
   add constraint FK_ACCOUNT_OWN_BANK_USE foreign key (bank_user_id)
      references bank_user (bank_user_id)
go

alter table deposit
   add constraint FK_DEPOSIT_OWN_DEPOS_ACCOUNT foreign key (cid)
      references account (cid)
go

alter table transaction_record
   add constraint FK_TRANSACT_IN_ACCOUNT foreign key (send_cid)
      references account (cid)
go

alter table transaction_record
   add constraint FK_TRANSACT_OUT_ACCOUNT foreign key (get_cid)
      references account (cid)
go

alter table with_fund
   add constraint FK_WITH_FUN_WITH_FUND_FUND foreign key (fid)
      references fund (fid)
go

alter table with_fund
   add constraint FK_WITH_FUN_WITH_FUND_ACCOUNT foreign key (cid)
      references account (cid)
go

alter table with_product
   add constraint FK_WITH_PRO_WITH_PROD_FINANCIA foreign key (pid)
      references financial_product (pid)
go

alter table with_product
   add constraint FK_WITH_PRO_WITH_PROD_ACCOUNT foreign key (cid)
      references account (cid)
go

INSERT INTO bank_user (bank_user_id, shen_id, bank_user_name, passward, phone, reg_time) VALUES 
('SYS_MERCHANT', '000000000000000000', '银行官方商户', 'admin_sys', '00000000000', '2023-01-01 00:00:00');
INSERT INTO account (cid, bank_user_id, cur_balance, transaction_limit, atype, astatus, open_time) VALUES 
('999999', 'SYS_MERCHANT', 0.00, 100000000.00, 1, 1, '2023-01-01 00:00:00');