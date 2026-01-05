<template>
  <div class="dashboard-container">
    <!-- 现有的统计卡片部分保持不变 -->
    <el-row :gutter="20" class="mb-30">
      <!-- ... 现有的4个统计卡片 ... -->
    </el-row>

    <div class="section-header">
      <span class="title-decoration"></span>
      <h3 class="section-title">常用管理功能</h3>
    </div>

    <el-row :gutter="20">
      <!-- 现有的4个功能卡片 -->
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
      
      <!-- ========== 新增：数据同步卡片（保持原有风格）========== -->
      <el-col :span="6">
        <el-card 
          class="menu-card" 
          shadow="hover" 
          @click="handleSyncClick"
          :class="{ 'syncing': isSyncing }"
        >
          <div class="menu-content">
            <div class="icon-bg bg-green">
              <el-icon v-if="!isSyncing"><Refresh /></el-icon>
              <el-icon v-if="isSyncing" class="loading-icon"><Loading /></el-icon>
            </div>
            <div class="menu-text">
              <span class="title">{{ isSyncing ? '同步中...' : '数据同步' }}</span>
              <span class="desc">SQL Server → MySQL/PostgreSQL</span>
            </div>
          </div>
        </el-card>
      </el-col>
      <!-- ========== 数据同步卡片结束 ========== -->
    </el-row>
  </div>
</template>

<script setup>
// 导入现有的图标
import { User, Bell, DataLine, Money, Plus, TrendCharts, CreditCard } from '@element-plus/icons-vue';
// 新增导入
import { Refresh, Loading } from '@element-plus/icons-vue';
import { reactive, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import axios from '@/api/request';
import { ElMessage, ElMessageBox } from 'element-plus';

const router = useRouter();
const stats = reactive({ userCount: 0, auditCount: 0, productCount: 0, fundCount: 0 });

// 同步相关状态
const isSyncing = ref(false);

// 现有的获取统计数据的函数
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

// 新增：处理同步点击
const handleSyncClick = async () => {
  if (isSyncing.value) return;
  
  try {
    // 确认对话框
    const confirm = await ElMessageBox.confirm(
      '确定要同步所有数据吗？',
      '确认数据同步',
      {
        confirmButtonText: '开始同步',
        cancelButtonText: '取消',
        type: 'warning',
        center: true,
      }
    );
    
    if (confirm) {
      await triggerDataSync();
    }
  } catch (error) {
    // 用户点击了取消
    console.log('用户取消了同步操作');
  }
};

// 新增：触发数据同步
const triggerDataSync = async () => {
  isSyncing.value = true;
  
  try {
    // 简单直接的fetch请求
    const res = await fetch('http://localhost:8000/api/sync', {
      method: 'POST'
    });
    
    const data = await res.json();
    
    if (data.success) {
      ElMessage.success('同步任务已开始');
      setTimeout(() => fetchStats(), 1000);
    } else {
      ElMessage.error(data.message || '同步失败');
    }
    
  } catch (err) {
    ElMessage.error('请求失败: ' + err.message);
  } finally {
    isSyncing.value = false;
  }
};

// 页面加载时获取统计数据
onMounted(() => {
  fetchStats();
});
</script>

<style scoped>
/* 现有的样式保持不变 */

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

/* 现有的图标背景颜色 */
.bg-red { background-color: #FEF0F0; color: #C20C0C; }
.bg-gold { background-color: #FDF6EC; color: #E6A23C; }
.bg-purple { background-color: #F2EBFA; color: #8E44AD; }
.bg-gray { background-color: #F5F7FA; color: #909399; }

/* 新增：数据同步图标背景颜色（绿色主题）*/
.bg-green { 
  background-color: #f0f9eb; 
  color: #67c23a;
}

.menu-text { display: flex; flex-direction: column; }
.menu-text .title { font-size: 16px; font-weight: 600; color: #303133; margin-bottom: 4px; }
.menu-text .desc { font-size: 12px; color: #909399; }

/* 同步中状态 */
.menu-card.syncing {
  pointer-events: none;
  opacity: 0.9;
}

.menu-card.syncing .icon-bg.bg-green {
  background-color: #fdf6ec;
  color: #e6a23c;
}

.loading-icon {
  animation: spin 2s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* 响应式调整 */
@media (max-width: 768px) {
  .el-col {
    margin-bottom: 15px;
  }
}
</style>