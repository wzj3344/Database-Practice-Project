<template>
  <div class="dashboard-container">
    <el-row :gutter="20" class="mb-30">
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card red-gradient">
          <div class="stat-content">
            <div class="stat-info">
              <div class="label">总账户数</div>
              <div class="value">{{ stats.userCount }}</div>
            </div>
            <el-icon class="stat-icon"><User /></el-icon>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card gold-gradient">
          <div class="stat-content">
            <div class="stat-info">
              <div class="label">待审核交易</div>
              <div class="value">{{ stats.auditCount }}</div>
            </div>
            <el-icon class="stat-icon"><Bell /></el-icon>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card purple-gradient">
          <div class="stat-content">
            <div class="stat-info">
              <div class="label">理财产品</div>
              <div class="value">{{ stats.productCount }}</div>
            </div>
            <el-icon class="stat-icon"><DataLine /></el-icon>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card pink-gradient">
          <div class="stat-content">
            <div class="stat-info">
              <div class="label">基金产品</div>
              <div class="value">{{ stats.fundCount }}</div>
            </div>
            <el-icon class="stat-icon"><TrendCharts /></el-icon>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <div class="section-header">
      <span class="title-decoration"></span>
      <h3 class="section-title">常用管理功能</h3>
    </div>

    <el-row :gutter="20">
      <el-col :span="6">
        <el-card class="menu-card" shadow="hover" @click="router.push('/admin/users')">
          <div class="menu-content">
            <div class="icon-bg bg-red"><el-icon><CreditCard /></el-icon></div>
            <div class="menu-text">
              <span class="title">账户管理</span>
              <span class="desc">冻结/解冻 额度调整</span>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="menu-card" shadow="hover" @click="router.push('/admin/audit')">
          <div class="menu-content">
            <div class="icon-bg bg-gold"><el-icon><Money /></el-icon></div>
             <div class="menu-text">
              <span class="title">交易审核</span>
              <span class="desc">大额转账 风险控制</span>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="menu-card" shadow="hover" @click="router.push('/admin/products')">
          <div class="menu-content">
            <div class="icon-bg bg-purple"><el-icon><DataLine /></el-icon></div>
            <div class="menu-text">
              <span class="title">理财维护</span>
              <span class="desc">产品上架 利率调整</span>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="menu-card" shadow="hover" @click="router.push('/admin/add_admin')">
          <div class="menu-content">
            <div class="icon-bg bg-gray"><el-icon><Plus /></el-icon></div>
            <div class="menu-text">
              <span class="title">添加管理员</span>
              <span class="desc">权限分配 系统设置</span>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
// Script 逻辑保持不变
import { reactive, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { User, Bell, DataLine, Money, Plus, TrendCharts, CreditCard} from '@element-plus/icons-vue';
import axios from '@/api/request';

const router = useRouter();
const stats = reactive({ userCount: 0, auditCount: 0, productCount: 0, fundCount: 0 });

const fetchStats = async () => {
  try {
    const [users, audits, products, funds] = await Promise.all([
      axios.get('/admin/account/list').catch(() => ({ data: [] })),
      axios.get('/admin/audit/list').catch(() => ({ data: [] })),
      axios.get('/admin/product/list').catch(() => ({ data: [] })),
      axios.get('/admin/fund/list').catch(() => ({ data: [] }))
    ]);
    const getLen = (res) => Array.isArray(res) ? res.length : (res.data?.length || 0);
    stats.userCount = getLen(users);
    stats.auditCount = getLen(audits);
    stats.productCount = getLen(products);
    stats.fundCount = getLen(funds);
  } catch (e) { console.error(e); }
};

onMounted(() => fetchStats());
</script>

<style scoped>
.dashboard-container { padding: 0; }
.mb-30 { margin-bottom: 30px; }

/* 统计卡片样式 */
.stat-card { border: none; color: white; border-radius: 8px; overflow: hidden; position: relative; }
.stat-card::after {
  content: ""; position: absolute; top: -50%; right: -20%; width: 150px; height: 150px;
  background: rgba(255,255,255,0.1); border-radius: 50%; pointer-events: none;
}
.red-gradient { background: linear-gradient(135deg, #E60012 0%, #FF6B6B 100%); box-shadow: 0 4px 15px rgba(230, 0, 18, 0.3); }
.gold-gradient { background: linear-gradient(135deg, #D4AF37 0%, #F3D060 100%); box-shadow: 0 4px 15px rgba(212, 175, 55, 0.3); }
.purple-gradient { background: linear-gradient(135deg, #8E44AD 0%, #C0392B 100%); box-shadow: 0 4px 15px rgba(142, 68, 173, 0.3); }
.pink-gradient { background: linear-gradient(135deg, #EC407A 0%, #F48FB1 100%); box-shadow: 0 4px 15px rgba(236, 64, 122, 0.3); }

.stat-content { display: flex; justify-content: space-between; align-items: center; padding: 10px 5px; position: relative; z-index: 2; }
.stat-info .label { font-size: 14px; opacity: 0.9; margin-bottom: 5px; }
.stat-info .value { font-size: 32px; font-weight: 700; font-family: 'DIN Alternate', sans-serif; }
.stat-icon { font-size: 48px; opacity: 0.25; }

/* 标题样式 */
.section-header { display: flex; align-items: center; margin-bottom: 20px; }
.title-decoration { width: 4px; height: 18px; background-color: #C20C0C; border-radius: 2px; margin-right: 10px; }
.section-title { font-size: 18px; color: #303133; margin: 0; font-weight: 600; }

/* 快捷功能卡片样式 */
.menu-card { cursor: pointer; border-radius: 8px; border: none; transition: all 0.3s; }
.menu-card:hover { transform: translateY(-5px); box-shadow: 0 8px 20px rgba(0,0,0,0.05); }

.menu-content { display: flex; align-items: center; padding: 15px 5px; }

.icon-bg {
  width: 52px; height: 52px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 24px; margin-right: 15px; flex-shrink: 0;
  transition: all 0.3s;
}
.menu-card:hover .icon-bg { transform: scale(1.1); }

.bg-red { background-color: #FEF0F0; color: #C20C0C; }
.bg-gold { background-color: #FDF6EC; color: #E6A23C; }
.bg-purple { background-color: #F2EBFA; color: #8E44AD; }
.bg-gray { background-color: #F5F7FA; color: #909399; }

.menu-text { display: flex; flex-direction: column; }
.menu-text .title { font-size: 16px; font-weight: 600; color: #303133; margin-bottom: 4px; }
.menu-text .desc { font-size: 12px; color: #909399; }
</style>