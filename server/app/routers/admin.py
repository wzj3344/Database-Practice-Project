from typing import Optional
from fastapi import APIRouter
from pydantic import BaseModel
from ..database import execute_proc, get_db_connection
import pandas as pd

router = APIRouter(prefix="/admin", tags=["管理员后台"])

class ProductUpdateRequest(BaseModel):
    pid: str
    pname: Optional[str] = None
    pstatus: Optional[int] = None
    pworth: Optional[float] = None
    prisk: Optional[int] = None

class AccountLimitRequest(BaseModel):
    cid: str
    limit: float
    credit_limit: Optional[float] = None # 信用额度

class AddAdminRequest(BaseModel):
    aid: str
    password: str

class RevokeRequest(BaseModel):
    tid: str
    admin_id: str

class AuditRequest(BaseModel):
    tid: str
    result: int # 1通过 2驳回
    admin_id: str

class ProductAddRequest(BaseModel):
    pid: str
    pname: str
    pworth: float
    pleast: float
    prisk: int

class AccountStatusRequest(BaseModel):
    cid: str
    status: int # 2挂失 3冻结 1正常

class ProductDeleteRequest(BaseModel):
    pid: str

class FundAddRequest(BaseModel):
    fid: str
    fname: str
    fworth: float
    fleast: float
    frisk: int

class FundUpdateRequest(BaseModel):
    fid: str
    fname: Optional[str] = None
    fstatus: Optional[int] = None
    fworth: Optional[float] = None
    frisk: Optional[int] = None

class FundDeleteRequest(BaseModel):
    fid: str

class RateUpdateRequest(BaseModel):
    month: int
    rate: float

@router.get("/audit/list")
def get_pending_audits():
    """查询待审核交易"""
    conn = get_db_connection()
    try:
        df = pd.read_sql("SELECT * FROM v_pending_audit", conn)
        return {"status": "success", "data": df.to_dict(orient="records")}
    finally:
        conn.close()

@router.post("/audit/action")
def audit_action(req: AuditRequest):
    return execute_proc("sp_audit_transaction", (req.tid, req.result, req.admin_id), commit=True)

@router.post("/product/add")
def add_product(req: ProductAddRequest):
    return execute_proc("sp_add_product", (req.pid, req.pname, req.pworth, req.pleast, req.prisk), commit=True)

@router.get("/account/list")
def get_all_accounts():
    """查询所有用户账户信息(用于用户管理)"""
    conn = get_db_connection()
    try:
        # 修改：增加了 a.credit_limit 和 a.open_time
        sql = """
        SELECT a.cid, a.cur_balance, a.transaction_limit, a.credit_limit, a.astatus, a.atype, a.open_time,
               b.bank_user_name, b.bank_user_id 
        FROM account a 
        JOIN bank_user b ON a.bank_user_id = b.bank_user_id
        ORDER BY a.open_time DESC
        """
        df = pd.read_sql(sql, conn)
        return {"status": "success", "data": df.to_dict(orient="records")}
    finally:
        conn.close()

@router.post("/account/limit")
def update_account_limit(req: AccountLimitRequest):
    """更新账户额度"""
    # 调用存储过程传递 3 个参数
    return execute_proc(
        "sp_update_account_limit", 
        (req.cid, req.limit, req.credit_limit), 
        commit=True
    )

@router.post("/add")
def add_new_admin(req: AddAdminRequest):
    """添加新的管理员"""
    return execute_proc("sp_add_admin", (req.aid, req.password), commit=True)

@router.post("/account/status")
def update_account_status(req: AccountStatusRequest):
    """冻结/解冻账户"""
    return execute_proc("sp_manage_card_status", (req.cid, req.status), commit=True)

@router.get("/product/list")
def get_all_products():
    """查询所有理财产品(用于基础数据维护)"""
    conn = get_db_connection()
    try:
        df = pd.read_sql("SELECT * FROM financial_product", conn)
        return {"status": "success", "data": df.to_dict(orient="records")}
    finally:
        conn.close()

@router.get("/audit/audited_list")
def get_audited_list():
    """查询已审核的历史记录"""
    conn = get_db_connection()
    try:
        # 查询新创建的视图 v_audited_log
        df = pd.read_sql("SELECT * FROM v_audited_log ORDER BY ttime DESC", conn)
        return {"status": "success", "data": df.to_dict(orient="records")}
    finally:
        conn.close()

@router.post("/audit/revoke")
def revoke_audit(req: RevokeRequest):
    """撤回审核"""
    # 调用 sp_revoke_audit
    return execute_proc("sp_revoke_audit", (req.tid, req.admin_id), commit=True)

@router.post("/product/update")
def update_product(req: ProductUpdateRequest):
    """更新产品信息 (名称、状态、净值、风险)"""
    # 注意：参数顺序必须与 SQL 存储过程完全一致
    # SQL顺序: @pid, @pname, @pstatus, @pworth, @prisk
    return execute_proc(
        "sp_update_product", 
        (req.pid, req.pname, req.pstatus, req.pworth, req.prisk), 
        commit=True
    )

@router.post("/product/delete")
def delete_product(req: ProductDeleteRequest):
    """删除理财产品 (物理删除)"""
    return execute_proc("sp_delete_product", (req.pid,), commit=True)

@router.get("/fund/list")
def get_all_funds_admin():
    """查询所有基金(用于基础数据维护)"""
    conn = get_db_connection()
    try:
        df = pd.read_sql("SELECT * FROM fund", conn)
        return {"status": "success", "data": df.to_dict(orient="records")}
    finally:
        conn.close()

@router.post("/fund/add")
def add_fund(req: FundAddRequest):
    return execute_proc(
        "sp_add_fund", 
        (req.fid, req.fname, req.fworth, req.fleast, req.frisk), 
        commit=True
    )

@router.post("/fund/update")
def update_fund(req: FundUpdateRequest):
    return execute_proc(
        "sp_update_fund", 
        (req.fid, req.fname, req.fstatus, req.fworth, req.frisk), 
        commit=True
    )

@router.post("/fund/delete")
def delete_fund(req: FundDeleteRequest):
    return execute_proc("sp_delete_fund", (req.fid,), commit=True)

@router.post("/rate/update")
def update_deposit_rate(req: RateUpdateRequest):
    """管理员修改利率"""
    return execute_proc(
        "sp_update_deposit_rate", 
        (req.month, req.rate), 
        commit=True
    )