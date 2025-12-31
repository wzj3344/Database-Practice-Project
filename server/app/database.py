import re
import pyodbc

# 数据库配置
DB_CONFIG = {
    'DRIVER': '{ODBC Driver 17 for SQL Server}',
    'SERVER': 'localhost',
    'DATABASE': 'BankDB',
    'Trusted_Connection': 'yes'
}

def get_db_connection():
    try:
        conn_str = f"DRIVER={DB_CONFIG['DRIVER']};SERVER={DB_CONFIG['SERVER']};DATABASE={DB_CONFIG['DATABASE']};Trusted_Connection={DB_CONFIG['Trusted_Connection']};"
        return pyodbc.connect(conn_str)
    except Exception as e:
        print(f"数据库连接错误: {e}")
        raise e

def execute_proc(proc_name: str, params: tuple, commit: bool = False):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # 构造 SQL 语句: EXEC proc_name ?, ?
        placeholders = ",".join(["?"] * len(params))
        sql = f"{{CALL {proc_name} ({placeholders})}}"
        
        cursor.execute(sql, params)
        
        if commit:
            # 这里的逻辑是：如果存储过程有输出（如sp_open_account），fetch它；如果没有，就commit
            # 简单起见，我们尝试 commit
            try:
                # 某些存储过程可能有返回结果集，即使是修改操作
                if cursor.description: 
                    columns = [column[0] for column in cursor.description]
                    results = [dict(zip(columns, row)) for row in cursor.fetchall()]
                    conn.commit()
                    return {"status": "success", "data": results}
            except:
                pass
                
            conn.commit()
            return {"status": "success", "msg": "操作成功"}
        else:
            # 查询模式
            columns = [column[0] for column in cursor.description]
            results = [dict(zip(columns, row)) for row in cursor.fetchall()]
            return {"status": "success", "data": results}
            
    except Exception as e:
        if commit: conn.rollback()
        
        # --- 2. 优化错误信息提取逻辑 ---
        raw_msg = str(e)
        # 目标格式: ('42000', '[42000] [Microsoft]...[SQL Server]错误内容 (50008)...')
        # 我们想提取 [SQL Server] 后面的内容，直到括号前的错误码
        
        # 正则解释：找 [SQL Server] 后面的非换行字符，直到遇到 (数字) 结尾
        match = re.search(r'\[SQL Server\](.*?)(?:\(\d+\))', raw_msg)
        
        if match:
            # 提取成功，只返回核心错误信息
            clean_msg = match.group(1).strip()
        else:
            # 提取失败（可能是连接错误等其他异常），为了不显示太长，只取第一部分或直接返回
            # 这里简单处理：如果包含 ODBC 原始结构，尝试简化，否则原样返回
            clean_msg = raw_msg

        return {"status": "error", "msg": clean_msg}
        
    finally:
        conn.close()