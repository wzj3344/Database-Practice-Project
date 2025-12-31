from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import auth, account, transaction, investment, admin

app = FastAPI(title="Bank System API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册所有路由
app.include_router(auth.router)
app.include_router(account.router)
app.include_router(transaction.router)
app.include_router(investment.router)
app.include_router(admin.router)

@app.get("/")
def root():
    return {"message": "Bank System API is running..."}