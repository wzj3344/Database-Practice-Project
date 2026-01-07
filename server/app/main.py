from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import auth, account, transaction, investment, admin
from .database import test_db
import threading  # 新增导入
from datetime import datetime
from .email_service import email_service
import os
app = FastAPI(title="Bank System API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册所有路由
app.include_router(auth.router)
app.include_router(account.router)
app.include_router(transaction.router)
app.include_router(investment.router)
app.include_router(admin.router)

@app.get("/")
def root():
    return {"message": "Bank System API is running..."}

# ========== 新增：同步API ==========

@app.post("/api/email/test")
async def test_email():
    """测试邮件发送功能"""
    try:
        subject = "银行系统邮件服务测试"
        content = f"""
银行系统邮件服务测试

这是一封测试邮件，用于验证邮件服务是否正常工作。

测试时间：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
服务器：{os.getenv('HOSTNAME', 'localhost')}

如果收到此邮件，说明邮件服务配置正确。
"""
        
        success = email_service.send_email(
            subject=subject,
            content=content,
            content_type="plain"
        )
        
        if success:
            return {
                "success": True,
                "message": "测试邮件已发送，请检查邮箱",
                "timestamp": datetime.now().isoformat()
            }
        
            
    except Exception as e:
        return {
            "success": False,
            "message": f"发送测试邮件时出错: {str(e)}",
            "timestamp": datetime.now().isoformat()
        }
    


@app.post("/api/sync")
def trigger_sync():
    """
    手动触发数据同步
    调用后立即返回，同步在后台运行
    """
    # 导入同步函数
    try:
        from .sync.full_sync import full_sync_all
    except ImportError:
        import sys
        sys.path.append('/app')
        from server.app.sync.full_sync import full_sync_all
    
    def run_sync():
        """在后台线程中运行同步"""
        print("🔄 手动同步开始...")
        try:
            full_sync_all()
            print("✅ 手动同步完成")
        except Exception as e:
            print(f"❌ 手动同步失败: {e}")
    
    # 在新线程中运行同步
    thread = threading.Thread(target=run_sync)

    thread.start()
    
    return {
        "success": True,
        "message": "数据同步任务已开始",
        "note": "同步在后台运行，请查看服务器日志了解进度"
    }

@app.get("/api/sync/test")
def test_sync_api():
    """测试同步API是否可用"""
    return {
        "success": True,
        "message": "同步API工作正常",
        "endpoints": {
            "POST /api/sync": "触发数据同步"
        }
    }
# ========== 同步API结束 ==========

test_db()

@app.on_event("startup")
def startup_event():
    print("🚀 后端启动，开始测试数据库连接...")
    test_db()
    print("✅ 同步API已就绪: POST /api/sync")