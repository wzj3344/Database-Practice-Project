FROM python:3.10-slim-bookworm
# ===== 1. 基础系统依赖（添加 freetds） =====
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    gnupg \
    unixodbc \
    unixodbc-dev \
    tdsodbc \
    freetds-dev \
    freetds-bin \
    && rm -rf /var/lib/apt/lists/*

# ===== 2. 配置 FreeTDS =====
RUN echo "[FreeTDS]\n\
    Description = FreeTDS Driver\n\
    Driver = /usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\n\
    Setup = /usr/lib/x86_64-linux-gnu/odbc/libtdsS.so" >> /etc/odbcinst.ini


# ===== 3. Python =====
WORKDIR /app
ENV PYTHONPATH=/app

RUN mkdir -p /app/logs

COPY server/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# ===== 4. 项目代码 =====
COPY server/app ./app

COPY . .

# CMD ["uvicorn", "server.app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# ===== 6. 复制启动脚本 =====
COPY server/start.sh /app/start.sh
RUN chmod +x /app/start.sh

# ===== 7. 修改启动命令 =====
CMD ["/app/start.sh"]
