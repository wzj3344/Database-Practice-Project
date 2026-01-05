import pyodbc

try:
    conn = pyodbc.connect(
        'DRIVER={FreeTDS};'
        'SERVER=sqlserver,1433;'
        'DATABASE=BankDB;'
        'UID=sa;'
        'PWD=YourStrong@Passw0rd;'
        'TrustServerCertificate=yes;'
        'TDS_Version=7.4;'
    )
    
    cursor = conn.cursor()
    
    # 1. 检查有哪些表
    print('=== 数据库中的表 ===')
    cursor.execute(\"\"\"
        SELECT TABLE_SCHEMA, TABLE_NAME 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_TYPE = 'BASE TABLE'
        ORDER BY TABLE_SCHEMA, TABLE_NAME
    \"\"\")
    
    tables = cursor.fetchall()
    if tables:
        print(f'共 {len(tables)} 张表:')
        for schema, table in tables:
            print(f'  {schema}.{table}')
    else:
        print('没有表！数据库是空的。')
        conn.close()
        exit(0)
    
    # 2. 特别检查用户相关表
    print('\\n=== 用户相关表 ===')
    user_tables = ['Users', 'Customers', 'Employees', 'User', 'Customer', 'Employee']
    
    for table in user_tables:
        cursor.execute(f\"\"\"
            SELECT CASE WHEN EXISTS (
                SELECT * FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_NAME = '{table}' AND TABLE_TYPE = 'BASE TABLE'
            ) THEN 1 ELSE 0 END
        \"\"\")
        
        exists = cursor.fetchone()[0]
        if exists:
            print(f'{table}: 存在')
            # 查看表结构
            cursor.execute(f\"\"\"
                SELECT COLUMN_NAME, DATA_TYPE
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_NAME = '{table}'
                ORDER BY ORDINAL_POSITION
            \"\"\")
            
            columns = cursor.fetchall()
            print(f'  列: {', '.join([f'{col}({dtype})' for col, dtype in columns])}')
            
            # 查看数据量
            cursor.execute(f'SELECT COUNT(*) FROM [{table}]')
            count = cursor.fetchone()[0]
            print(f'  数据行数: {count}')
            
            if count > 0:
                # 显示前2行
                cursor.execute(f'SELECT TOP 2 * FROM [{table}]')
                cols = [c[0] for c in cursor.description]
                for row in cursor.fetchall():
                    print(f'    样本: {dict(zip(cols, row))}')
        else:
            print(f'{table}: 不存在')
    
    conn.close()
    print('\\n✅ 测试完成')
    
except Exception as e:
    print(f'❌ 错误: {e}')
    import traceback
    traceback.print_exc()
