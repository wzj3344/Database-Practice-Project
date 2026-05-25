# BankSystem
这是一个多数据库同步协调系统  
实现了多数据库之间同步数据和异常处理等功能  
前端模拟银行系统实现数据库基本架构，具备完整存储过程和触发器  
项目使用docker环境部署  

启动：
docker-compose up -d  

地址：
http://localhost:5173 


其他：

docker-compose down -v

docker-compose stop

docker-compose build --no-cache
docker-compose up -d
docker-compose up -d --build

docker exec -it bank-backend bash  进入后端

docker ps
docker logs bank-backend


python app/sync/full_sync.py 

docker-compose down -v MySQL 重启
docker-compose up -d mysql

docker-compose logs -f backend 查看日志

### 查看各个容器的日志，看是否有错误
docker-compose logs sqlserver
docker-compose logs mysql
docker-compose logs backend


### 触发同步测试
curl.exe -X POST http://localhost:8000/api/sync

### 查询MySQL中的数据

docker-compose exec mysql bash

mysql -uroot -proot

USE bankdb;

SELECT * FROM admini;

EXIT;
