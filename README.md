# multi-db-sync-system

http://localhost:5173 地址


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

# 2. 查看各个容器的日志，看是否有错误
docker-compose logs sqlserver
docker-compose logs mysql
docker-compose logs backend


# 4. 触发同步测试
curl.exe -X POST http://localhost:8000/api/sync
