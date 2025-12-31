/*==============================================================*/
/* DBMS name:      Microsoft SQL Server 2012                    */
/* Created on:     2025/11/29 0:49:04                           */
/*==============================================================*/


if exists (select 1
   from sys.sysreferences r join sys.sysobjects o on (o.id = r.constid and o.type = 'F')
   where r.fkeyid = object_id('account') and o.name = 'FK_ACCOUNT_OWN_BANK_USE')
alter table account
   drop constraint FK_ACCOUNT_OWN_BANK_USE
go

if exists (select 1
   from sys.sysreferences r join sys.sysobjects o on (o.id = r.constid and o.type = 'F')
   where r.fkeyid = object_id('deposit') and o.name = 'FK_DEPOSIT_OWN_DEPOS_ACCOUNT')
alter table deposit
   drop constraint FK_DEPOSIT_OWN_DEPOS_ACCOUNT
go

if exists (select 1
   from sys.sysreferences r join sys.sysobjects o on (o.id = r.constid and o.type = 'F')
   where r.fkeyid = object_id('transaction_record') and o.name = 'FK_TRANSACT_IN_ACCOUNT')
alter table transaction_record
   drop constraint FK_TRANSACT_IN_ACCOUNT
go

if exists (select 1
   from sys.sysreferences r join sys.sysobjects o on (o.id = r.constid and o.type = 'F')
   where r.fkeyid = object_id('transaction_record') and o.name = 'FK_TRANSACT_OUT_ACCOUNT')
alter table transaction_record
   drop constraint FK_TRANSACT_OUT_ACCOUNT
go

if exists (select 1
   from sys.sysreferences r join sys.sysobjects o on (o.id = r.constid and o.type = 'F')
   where r.fkeyid = object_id('with_fund') and o.name = 'FK_WITH_FUN_WITH_FUND_FUND')
alter table with_fund
   drop constraint FK_WITH_FUN_WITH_FUND_FUND
go

if exists (select 1
   from sys.sysreferences r join sys.sysobjects o on (o.id = r.constid and o.type = 'F')
   where r.fkeyid = object_id('with_fund') and o.name = 'FK_WITH_FUN_WITH_FUND_ACCOUNT')
alter table with_fund
   drop constraint FK_WITH_FUN_WITH_FUND_ACCOUNT
go

if exists (select 1
   from sys.sysreferences r join sys.sysobjects o on (o.id = r.constid and o.type = 'F')
   where r.fkeyid = object_id('with_product') and o.name = 'FK_WITH_PRO_WITH_PROD_FINANCIA')
alter table with_product
   drop constraint FK_WITH_PRO_WITH_PROD_FINANCIA
go

if exists (select 1
   from sys.sysreferences r join sys.sysobjects o on (o.id = r.constid and o.type = 'F')
   where r.fkeyid = object_id('with_product') and o.name = 'FK_WITH_PRO_WITH_PROD_ACCOUNT')
alter table with_product
   drop constraint FK_WITH_PRO_WITH_PROD_ACCOUNT
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('account')
            and   name  = 'own_FK'
            and   indid > 0
            and   indid < 255)
   drop index account.own_FK
go

if exists (select 1
            from  sysobjects
           where  id = object_id('account')
            and   type = 'U')
   drop table account
go

if exists (select 1
            from  sysobjects
           where  id = object_id('admini')
            and   type = 'U')
   drop table admini
go

if exists (select 1
            from  sysobjects
           where  id = object_id('bank_user')
            and   type = 'U')
   drop table bank_user
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('deposit')
            and   name  = 'own_deposit_FK'
            and   indid > 0
            and   indid < 255)
   drop index deposit.own_deposit_FK
go

if exists (select 1
            from  sysobjects
           where  id = object_id('deposit')
            and   type = 'U')
   drop table deposit
go

if exists (select 1
            from  sysobjects
           where  id = object_id('financial_product')
            and   type = 'U')
   drop table financial_product
go

if exists (select 1
            from  sysobjects
           where  id = object_id('fund')
            and   type = 'U')
   drop table fund
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('transaction_record')
            and   name  = 'out_FK'
            and   indid > 0
            and   indid < 255)
   drop index transaction_record.out_FK
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('transaction_record')
            and   name  = 'in_FK'
            and   indid > 0
            and   indid < 255)
   drop index transaction_record.in_FK
go

if exists (select 1
            from  sysobjects
           where  id = object_id('transaction_record')
            and   type = 'U')
   drop table transaction_record
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('with_fund')
            and   name  = 'with_fund_FK'
            and   indid > 0
            and   indid < 255)
   drop index with_fund.with_fund_FK
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('with_fund')
            and   name  = 'with_fund2_FK'
            and   indid > 0
            and   indid < 255)
   drop index with_fund.with_fund2_FK
go

if exists (select 1
            from  sysobjects
           where  id = object_id('with_fund')
            and   type = 'U')
   drop table with_fund
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('with_product')
            and   name  = 'with_product_FK'
            and   indid > 0
            and   indid < 255)
   drop index with_product.with_product_FK
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('with_product')
            and   name  = 'with_product2_FK'
            and   indid > 0
            and   indid < 255)
   drop index with_product.with_product2_FK
go

if exists (select 1
            from  sysobjects
           where  id = object_id('with_product')
            and   type = 'U')
   drop table with_product
go

/*==============================================================*/
/* Table: account                                               */
/*==============================================================*/
create table account (
   cid                  char(20)             not null,
   bank_user_id         varchar(20)          not null,
   cur_balance          decimal(18,2)        not null,
   transaction_limit    decimal(18,2)        not null,
   atype                int                  not null,
   astatus              int                  not null,
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
   prisk                int                  not null,
   pstatus              int                  not null,
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
   tstatus              int                  not null,
   ttype                int                  not null,
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
   buy_pspend¡¢          decimal(18,2)        not null,
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

