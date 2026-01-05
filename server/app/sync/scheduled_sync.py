# server/app/sync/scheduled_sync.py

import schedule
import time
import logging
from datetime import datetime
from .full_sync import full_sync_all
import os
# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/sync.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

def sync_job():
    """定时同步任务"""
    start_time = datetime.now()
    logger.info(f"⏰ 开始定时同步任务 {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    
    try:
        full_sync_all()
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        logger.info(f"✅ 同步完成，耗时 {duration:.2f} 秒")
        
    except Exception as e:
        logger.error(f"❌ 同步失败: {e}")
        import traceback
        logger.error(traceback.format_exc())

def run_scheduler(interval_minutes=5):
    """运行定时任务调度器"""
    
    # 设置定时任务
    schedule.every(interval_minutes).minutes.do(sync_job)
    
    # 立即执行一次
    logger.info("🚀 启动定时同步服务")
    logger.info(f"📅 同步间隔: 每 {interval_minutes} 分钟")
    sync_job()
    
    # 保持调度器运行
    while True:
        schedule.run_pending()
        time.sleep(1)

def run_scheduler_with_cron(hour='*', minute='0'):
    """使用 cron 表达式运行定时任务"""
    
    if hour == '*':
        # 每小时执行
        schedule.every().hour.at(f":{minute}").do(sync_job)
        logger.info(f"📅 同步时间: 每小时的第 {minute} 分钟")
    else:
        # 每天特定时间执行
        schedule.every().day.at(f"{hour}:{minute}").do(sync_job)
        logger.info(f"📅 同步时间: 每天 {hour}:{minute}")
    
    logger.info("🚀 启动定时同步服务")
    sync_job()
    
    while True:
        schedule.run_pending()
        time.sleep(1)

if __name__ == "__main__":
    
    logger.info("🌟 scheduled_sync.py 被调用")
    # 使用方法1：每5分钟同步一次
    run_scheduler(interval_minutes=5)
    
    # 使用方法2：每小时的第30分钟同步
    # run_scheduler_with_cron(minute='30')
    
    # 使用方法3：每天凌晨2点同步
    # run_scheduler_with_cron(hour='02', minute='00')