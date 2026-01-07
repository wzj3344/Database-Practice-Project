import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.header import Header
import logging
from typing import List, Optional

logger = logging.getLogger(__name__)

class EmailService:
    def __init__(self):
        # QQ邮箱SMTP配置
        self.smtp_server = "smtp.qq.com"
        self.smtp_port = 465  # SSL端口
        self.smtp_port_tls = 587  # TLS端口
        
        # 发件人邮箱配置（使用你的QQ邮箱）
        self.sender_email = "2803464361@qq.com"
        self.sender_password = "atasuteuyndndeia"  # ⚠️ 使用授权码，不是密码！
        
        # 收件人（管理员邮箱）
        self.admin_email = "2803464361@qq.com"
    
    def send_email(
        self,
        subject: str,
        content: str,
        to_emails: Optional[List[str]] = None,
        content_type: str = "plain"  # plain 或 html
    ) -> bool:
        """
        发送邮件
        
        Args:
            subject: 邮件主题
            content: 邮件内容
            to_emails: 收件人列表，默认发送给管理员
            content_type: 内容类型，plain 或 html
        
        Returns:
            发送成功返回True，失败返回False
        """
        try:
            if to_emails is None:
                to_emails = [self.admin_email]
            
            # 创建邮件对象
            msg = MIMEMultipart()
            msg['From'] = self.sender_email
            msg['To'] = ', '.join(to_emails)
            msg['Subject'] = Header(subject, 'utf-8')
            
            # 添加邮件正文
            if content_type == "html":
                msg.attach(MIMEText(content, 'html', 'utf-8'))
            else:
                msg.attach(MIMEText(content, 'plain', 'utf-8'))
            
            # 连接SMTP服务器并发送
            with smtplib.SMTP_SSL(self.smtp_server, self.smtp_port) as server:
                server.login(self.sender_email, self.sender_password)
                server.send_message(msg)
            
            logger.info(f"邮件发送成功: {subject}")
            return True
            
        except Exception as e:
            logger.error(f"邮件发送失败: {e}")
            return False
    
    def send_sync_notification(self, sync_result: dict) -> bool:
        """发送同步完成通知邮件"""
        subject = "银行系统数据同步完成通知"
        
        # 构建邮件内容
        content = f"""
银行系统数据同步已完成

同步详情：
- 状态: {"成功" if sync_result.get("success") else "失败"}
- 时间: {sync_result.get("timestamp", "")}
- 消息: {sync_result.get("message", "")}
        
同步统计：
"""
        
        if "tables" in sync_result:
            for table, info in sync_result["tables"].items():
                content += f"- {table}: {info.get('rows', 0)} 行数据\n"
        
        content += f"""
请登录系统查看详情：
http://localhost:5173/admin

银行系统自动通知
"""
        
        return self.send_email(subject, content)
    
    def send_error_notification(self, error_message: str) -> bool:
        """发送错误通知邮件"""
        subject = "银行系统异常通知"
        
        content = f"""
银行系统发生异常

错误详情：
{error_message}

发生时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

请及时登录系统处理：
http://localhost:5173/admin

银行系统自动通知
"""
        
        return self.send_email(subject, content)

# 创建全局实例
email_service = EmailService()