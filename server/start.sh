#!/bin/bash

# 先启动 FastAPI（后台运行）
echo "🚀 启动 FastAPI 服务..."
uvicorn server.app.main:app --host 0.0.0.0 --port 8000 &

# 等待更长的时间确保FastAPI和数据库都就绪
echo "⏳ 等待服务启动（15秒）..."
sleep 15

# 再启动定时同步服务
echo "🚀 启动定时同步服务..."
exec python -m server.app.sync.scheduled_sync --interval 30