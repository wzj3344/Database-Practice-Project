from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from ..database import execute_proc, get_db_connection
import pandas as pd

router = APIRouter(prefix="/transaction", tags=["资金交易"])

class TransferRequest(BaseModel):
    send_cid: str
    get_cid: str
    amount: float
    trans_type: int 

@router.post("/transfer")
def transfer_money(req: TransferRequest):
    # 调用存储过程
    result = execute_proc(
        "sp_transfer_transaction", 
        (req.send_cid, req.get_cid, req.amount, req.trans_type), 
        commit=True
    )
    
    # 1. 处理数据库抛出的异常 (status="error")
    # 对应情形：余额不足、卡号不存在、账户冻结
    if result["status"] == "error":
        return {"status": "error", "msg": result["msg"]}
    
    # 2. 处理存储过程返回的业务逻辑状态
    if "data" in result and result["data"]:
        row = result["data"][0]
        
        # 对应情形：透额待审核 (status="WARN")
        # 修改点：将 status 改为 'pending' 返回给前端，而不是 'success'
        if "status" in row and row["status"] == "WARN":
             return {"status": "pending", "msg": row["msg"]}
             
        # 对应情形：正常成功 (status="SUCCESS")
        if "status" in row and row["status"] == "SUCCESS":
             return {"status": "success", "msg": row["msg"]}
    
    # 默认兜底
    return {"status": "success", "msg": "交易成功"}

@router.get("/history/{user_id}")
def get_history(user_id: str):
    conn = get_db_connection()
    sql = """
    SELECT * FROM v_transaction_detail 
    WHERE send_cid IN (SELECT cid FROM account WHERE bank_user_id = ?) 
       OR get_cid IN (SELECT cid FROM account WHERE bank_user_id = ?)
    ORDER BY ttime DESC
    """
    df = pd.read_sql(sql, conn, params=(user_id, user_id))
    conn.close()
    return df.to_dict(orient="records")

@router.get("/bills/{user_id}")
def get_credit_bills(user_id: str):
    """查询信用卡账单 (v_credit_card_bill)"""
    conn = get_db_connection()
    try:
        sql = """
        SELECT * FROM v_credit_card_bill 
        WHERE card_number IN (SELECT cid FROM account WHERE bank_user_id = ?)
        ORDER BY bill_year DESC, bill_month DESC
        """
        df = pd.read_sql(sql, conn, params=(user_id,))
        return {"status": "success", "data": df.to_dict(orient="records")}
    finally:
        conn.close()