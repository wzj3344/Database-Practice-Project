# server/app/sync/full_sync.py

import pyodbc
import pymysql
from datetime import datetime
import logging

try:
    from ..email_service import email_service
    EMAIL_SERVICE_AVAILABLE = True
except ImportError:
    EMAIL_SERVICE_AVAILABLE = False
    print("⚠️  邮件服务不可用")

logger = logging.getLogger(__name__)

# ========= SQL Server 连接 =========
def get_sqlserver_conn():
    conn_str = (
        "DRIVER={FreeTDS};"
        "SERVER=sqlserver;"
        "DATABASE=BankDB;"
        "PORT=1433;"
        "UID=sa;"
        "PWD=YourStrong@Passw0rd;"
        "TDS_Version=8.0;"
        "TrustServerCertificate=yes;"
    )
    return pyodbc.connect(conn_str)


# ========= MySQL 连接 =========
def get_mysql_conn():
    return pymysql.connect(
        host="mysql",
        user="root",
        password="root",
        database="bankdb",
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor
    )

# ========= 全量同步  =========
def convert_value(value):
    """
    转换特殊类型的值以便插入MySQL
    """
    if value is None:
        return None
    
    # 如果是 datetime 类型
    if hasattr(value, 'strftime'):
        return value.strftime('%Y-%m-%d %H:%M:%S')
    
    # 如果是 bytes 类型（如图像、二进制数据）
    if isinstance(value, bytes):
        # 对于二进制数据，可以转换为十六进制字符串或 base64
        # 或者直接返回 None，取决于你的需求
        try:
            return value.decode('utf-8')
        except:
            # 如果不能解码为文本，返回十六进制字符串
            return value.hex()
    
    # 如果是 decimal 类型
    if hasattr(value, 'quantize'):
        return float(value)
    
    # 如果是 UUID 或其他需要转换的类型
    if hasattr(value, 'hex'):
        return str(value)
    
    # 其他类型保持不变
    return value


def sync_table_safe(table_name):
    print(f"🚀 开始同步 {table_name} 表")
    
    sql_conn = get_sqlserver_conn()
    mysql_conn = get_mysql_conn()
    
    try:
        sql_cursor = sql_conn.cursor()
        
        # 获取列名
        sql_cursor.execute(f"""
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME = '{table_name}'
            ORDER BY ORDINAL_POSITION
        """)
        columns = [row[0] for row in sql_cursor.fetchall()]
        
        if not columns:
            print(f"❌ 无法获取表结构")
            return
        
        print(f"   列: {columns}")
        
        # 读取数据
        columns_str = ', '.join(columns)
        sql_cursor.execute(f"SELECT {columns_str} FROM {table_name}")
        rows = sql_cursor.fetchall()
        
        print(f"📦 行数：{len(rows)}")
        
        if not rows:
            print("   无数据")
            return
        
        # 准备插入
        mysql_cursor = mysql_conn.cursor()
        placeholders = ', '.join(['%s'] * len(columns))
        insert_sql = f"INSERT IGNORE INTO {table_name} ({columns_str}) VALUES ({placeholders})"
        
        inserted = 0
        for row in rows:
            # 转换所有值
            converted_row = [convert_value(val) for val in row]
            
            try:
                mysql_cursor.execute(insert_sql, converted_row)
                inserted += mysql_cursor.rowcount
            except Exception as e:
                print(f"   插入失败: {e}")
                print(f"   原始数据: {row}")
                print(f"   转换后: {converted_row}")
                raise
        
        mysql_conn.commit()
        print(f"✅ 完成: {inserted}/{len(rows)} 行")
        success_count += 1
        total_rows += len(rows)
    except Exception as e:
        mysql_conn.rollback()
        print(f"❌ 失败: {e}")
        
    finally:
        sql_conn.close()
        mysql_conn.close()

def full_sync_all():

    # 同步统计信息
    sync_result = {
        "success": True,
        "message": "",
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "tables": {},
        "total_rows": 0,
        "failed_tables": []
    }
    success_count = 0
    total_rows = 0

    sync_table_safe('bank_user')
    sync_table_safe('account')
    sync_table_safe('transaction_record')
    sync_table_safe('financial_product')
    sync_table_safe('fund')
    sync_table_safe('deposit')
    sync_table_safe('with_fund')
    sync_table_safe('admini')
   
   
    sync_result["message"] = f"同步完成"
    # ========== 发送邮件通知 ==========
    if EMAIL_SERVICE_AVAILABLE:
        try:
            send_sync_notification_email(sync_result)
            print("📧 邮件通知已发送")
        except Exception as e:
            print(f"⚠️  邮件发送失败（但不影响同步）: {e}")
    else:
        print("ℹ️  邮件服务未启用")


# ========= 手动测试入口 =========
if __name__ == "__main__":
    print("🔥🔥🔥 THIS IS NEW FULL_SYNC VERSION 🔥🔥🔥")
    full_sync_all()



def send_sync_notification_email(sync_result):
    """发送同步完成通知邮件"""
    if not EMAIL_SERVICE_AVAILABLE:
        return
    
    subject = "银行系统数据同步完成通知"
    
    # 构建邮件内容
    success_status = "✅ 成功" if sync_result["success"] else "❌ 失败"
    
    content = f"""
银行系统数据同步已完成

📊 同步概览：
- 状态: {success_status}
- 时间: {sync_result["timestamp"]}
- 消息: {sync_result["message"]}

"""
    
    
    content += f"""
🔗 操作链接：
登录系统：http://localhost:5173/admin
查看日志：docker-compose logs backend --tail 50

---
银行系统自动通知
此邮件由系统自动发送，请勿回复。
"""
    
    # 发送邮件
    email_service.send_email(
        subject=subject,
        content=content,
        content_type="plain"
    )

def send_error_notification_email(error_message):
    """发送错误通知邮件"""
    if not EMAIL_SERVICE_AVAILABLE:
        return
    
    subject = "银行系统数据同步失败通知"
    
    content = f"""
银行系统数据同步发生错误

❌ 错误详情：
{error_message}

⏰ 发生时间：{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

🚨 需要立即处理：
1. 检查数据库连接是否正常
2. 查看服务器日志
3. 确保网络连接正常

🔗 操作链接：
登录系统：http://localhost:5173/admin
查看日志：docker-compose logs backend

---
银行系统自动通知
此邮件由系统自动发送，请勿回复。
"""
    
    email_service.send_email(
        subject=subject,
        content=content,
        content_type="plain"
    )