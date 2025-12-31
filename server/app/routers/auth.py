from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from ..database import get_db_connection, execute_proc
import random

OTP_STORE = {}

router = APIRouter(prefix="/auth", tags=["用户认证"])

class LoginRequest(BaseModel):
    user_id: str
    password: str
    role: str  # "user" 或 "admin"

class RegisterRequest(BaseModel):
    uid: str
    name: str
    id_card: str
    password: str
    phone: str

# 重置密码请求模型
class ResetPasswordRequest(BaseModel):
    uid: str
    new_password: str

class SendCodeRequest(BaseModel):
    uid: str
    phone: str

class UpdatePasswordWithCodeRequest(BaseModel):
    uid: str
    new_password: str
    code: str

class UpdatePhoneRequest(BaseModel):
    uid: str
    password: str
    new_phone: str

@router.post("/login")
def login(req: LoginRequest):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        if req.role == "user":
            sql = "SELECT bank_user_name FROM bank_user WHERE bank_user_id=? AND passward=?"
            cursor.execute(sql, (req.user_id, req.password))
            row = cursor.fetchone()
            if row:
                return {"status": "success", "user_name": row[0], "role": "user", "user_id": req.user_id}
        elif req.role == "admin":
            sql = "SELECT aid FROM admini WHERE aid=? AND apassword=?"
            cursor.execute(sql, (req.user_id, req.password))
            row = cursor.fetchone()
            if row:
                return {"status": "success", "user_name": "管理员", "role": "admin", "user_id": req.user_id}
        
        return {"status": "error", "msg": "用户名或密码错误"}
    finally:
        conn.close()

@router.post("/register")
def register(req: RegisterRequest):
    # 调用存储过程: sp_user_register
    result = execute_proc(
        "sp_user_register",
        (req.uid, req.name, req.id_card, req.password, req.phone),
        commit=True
    )
    if result.get("status") == "error": # 增加简单的错误处理返回
         return result
    return {"status": "success", "msg": "注册成功"}

# 新增：重置密码接口
@router.post("/reset_password")
def reset_password(req: ResetPasswordRequest):
    # 调用存储过程: sp_reset_password
    # 对应需求 3.1.1 密码管理
    result = execute_proc(
        "sp_reset_password",
        (req.uid, req.new_password),
        commit=True
    )
    if result.get("status") == "error":
         return result
    return {"status": "success", "msg": "密码重置成功"}

@router.post("/send_verify_code")
def send_verify_code(req: SendCodeRequest):
    """
    1. 校验用户ID和手机号是否匹配
    2. 生成4位随机验证码并在终端打印
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # 查询数据库中该用户的手机号
        sql = "SELECT phone FROM bank_user WHERE bank_user_id = ?"
        cursor.execute(sql, (req.uid,))
        row = cursor.fetchone()
        
        if not row:
            return {"status": "error", "msg": "用户ID不存在"}
        
        db_phone = row[0].strip() # 去除可能的空格
        
        if db_phone != req.phone:
            return {"status": "error", "msg": "手机号与预留信息不一致"}
        
        # 生成验证码
        code = str(random.randint(1000, 9999))
        OTP_STORE[req.uid] = code
        
        # 模拟发送到终端
        print(f"\n[模拟短信网关] 用户 {req.uid} 的验证码是: {code}\n")
        
        return {"status": "success", "msg": "验证码已发送"}
    finally:
        conn.close()

@router.post("/update_password_secure")
def update_password_secure(req: UpdatePasswordWithCodeRequest):
    """
    校验验证码并修改密码
    """
    # 1. 校验验证码
    stored_code = OTP_STORE.get(req.uid)
    if not stored_code or stored_code != req.code:
        return {"status": "error", "msg": "验证码错误或已失效"}
    
    # 2. 验证通过，调用存储过程修改密码
    # 复用已有的存储过程 sp_reset_password
    result = execute_proc(
        "sp_reset_password",
        (req.uid, req.new_password),
        commit=True
    )
    
    if result.get("status") == "success":
        # 修改成功后清除验证码
        OTP_STORE.pop(req.uid, None)
        
    return result

@router.post("/update_phone")
def update_user_phone(req: UpdatePhoneRequest):
    """
    用户修改预留手机号 (需验证密码)
    """
    return execute_proc(
        "sp_update_phone",
        (req.uid, req.password, req.new_phone),
        commit=True
    )