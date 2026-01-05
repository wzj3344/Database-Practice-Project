FROM node:20-bookworm

# 设置工作目录
WORKDIR /app

# 复制依赖描述文件
COPY package*.json ./

# 安装依赖
RUN npm install

# 复制源代码
COPY . .

# Vite 默认端口
EXPOSE 5173

# 启动 Vite 开发服务器
CMD ["npm", "run", "dev", "--", "--host"]
