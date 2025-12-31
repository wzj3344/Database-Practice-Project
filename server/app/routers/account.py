from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from ..database import execute_proc

router = APIRouter(prefix="/account", tags=["账户管理"])

class OpenAccountRequest(BaseModel):
    user_id: str
    atype: int  # 1储蓄，2信用

class CardStatusRequest(BaseModel):
    cid: str
    status: int # 1正常 2挂失 (用户只能操作这两个)

@router.get("/list/{user_id}")
def get_my_accounts(user_id: str):
    """查询名下账户"""
    return execute_proc("sp_query_account", (user_id,))

@router.post("/open")
def open_account(req: OpenAccountRequest):
    """开设新账户"""
    return execute_proc(
        "sp_open_account",
        (req.user_id, req.atype),
        commit=True
    )

@router.post("/change_status")
def change_card_status(req: CardStatusRequest):
    """用户自行挂失(2)或激活(1)"""
    if req.status not in [1, 2]:
         return {"status": "error", "msg": "用户权限不足，只能进行挂失或激活操作"}
    return execute_proc("sp_manage_card_status", (req.cid, req.status), commit=True)