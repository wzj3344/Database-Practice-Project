from fastapi import APIRouter
from pydantic import BaseModel
from ..database import execute_proc, get_db_connection
import pandas as pd

router = APIRouter(prefix="/investment", tags=["理财投资"])

class PurchaseRequest(BaseModel):
    cid: str
    item_id: str
    shares: int  # 变更为整数份额
    type: int    # 1理财 2基金

class DepositRequest(BaseModel):
    cid: str
    money: float
    months: int

class SellRequest(BaseModel):
    cid: str
    item_id: str
    shares: int
    type: int # 1理财 2基金

class WithdrawRequest(BaseModel):
    did: str
    cid: str

@router.get("/products")
def list_products(ptype: str = "financial"): # financial 或 fund
    conn = get_db_connection()
    try:
        if ptype == "financial":
            df = pd.read_sql("SELECT * FROM financial_product WHERE pstatus=1", conn)
        else:
            df = pd.read_sql("SELECT * FROM fund WHERE fstatus=1", conn)
        return {"status": "success", "data": df.to_dict(orient="records")}
    finally:
        conn.close()

@router.post("/purchase")
def purchase_product(req: PurchaseRequest):
    # 修改点2：调用存储过程传参变更
    # 对应 SQL 参数顺序：@cid, @item_id, @shares, @type
    return execute_proc(
        "sp_purchase_investment",
        (req.cid, req.item_id, req.shares, req.type),
        commit=True
    )

@router.get("/holdings/{user_id}")
def get_holdings(user_id: str):
    """查询持仓盈亏 (v_investment_profit)"""
    conn = get_db_connection()
    # 先查出该用户的所有卡号，再查视图
    try:
        sql = f"""
        SELECT * FROM v_investment_profit 
        WHERE cid IN (SELECT cid FROM account WHERE bank_user_id = ?)
        """
        df = pd.read_sql(sql, conn, params=(user_id,))
        return {"status": "success", "data": df.to_dict(orient="records")}
    finally:
        conn.close()

@router.get("/deposits/{user_id}")
def get_my_deposits(user_id: str):
    conn = get_db_connection()
    try:
        # 修改查询语句，增加 dstatus，并按开始时间倒序
        sql = """
        SELECT d.did, d.cid, d.dnumber, d.drate, d.dstart, d.dover, d.dstatus
        FROM deposit d
        JOIN account a ON d.cid = a.cid
        WHERE a.bank_user_id = ?
        ORDER BY d.dstart DESC
        """
        df = pd.read_sql(sql, conn, params=(user_id,))
        return {"status": "success", "data": df.to_dict(orient="records")}
    finally:
        conn.close()

@router.get("/deposit/income/{user_id}")
def get_deposit_income(user_id: str):
    conn = get_db_connection()
    try:
        sql = """
        SELECT * FROM v_deposit_income 
        WHERE cid IN (SELECT cid FROM account WHERE bank_user_id = ?)
        """
        df = pd.read_sql(sql, conn, params=(user_id,))
        return {"status": "success", "data": df.to_dict(orient="records")}
    finally:
        conn.close()

@router.get("/rates")
def get_deposit_rates():
    """获取定期存款利率表"""
    conn = get_db_connection()
    try:
        df = pd.read_sql("SELECT * FROM deposit_rate ORDER BY [month] ASC", conn)
        return {"status": "success", "data": df.to_dict(orient="records")}
    finally:
        conn.close()

@router.post("/deposit")
def create_deposit(req: DepositRequest):
    # 修改点：不再传递 rate，只传 cid, money, months
    result = execute_proc(
        "sp_create_deposit",
        (req.cid, req.money, req.months),
        commit=True
    )
    
    if result["status"] == "error":
        return {"status": "error", "msg": result["msg"]}
        
    return {"status": "success", "msg": "存款办理成功"}

@router.post("/sell")
def sell_product(req: SellRequest):
    return execute_proc(
        "sp_sell_investment",
        (req.cid, req.item_id, req.shares, req.type),
        commit=True
    )

@router.post("/deposit/withdraw")
def withdraw_deposit(req: WithdrawRequest):
    return execute_proc(
        "sp_withdraw_deposit",
        (req.did, req.cid),
        commit=True
    )