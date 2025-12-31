<template>
  <div class="page-container">
    <el-row :gutter="20">
      <el-col :span="8">
        <el-card shadow="hover" class="stat-card red-gradient">
          <div class="stat-content">
            <div>
              <div class="label">总资产估值</div>
              <div class="value">￥{{ totalAssets.toFixed(2) }}</div>
            </div>
            <el-icon class="stat-icon"><Wallet /></el-icon>
          </div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="hover" class="stat-card gold-gradient">
          <div class="stat-content">
            <div>
              <div class="label">活期余额</div>
              <div class="value">￥{{ balance.toFixed(2) }}</div>
            </div>
            <el-icon class="stat-icon"><Money /></el-icon>
          </div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="hover" class="stat-card purple-gradient">
          <div class="stat-content">
            <div>
              <div class="label">累计投资盈亏</div>
              <div class="value">
                <span v-if="totalProfit > 0">+</span>
                ￥{{ totalProfit.toFixed(2) }}
              </div>
            </div>
            <el-icon class="stat-icon"><TrendCharts /></el-icon>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <div class="section-container">
      <div class="section-header">
        <span class="title-decoration"></span>
        <h3 class="section-title">常用功能</h3>
      </div>
      
      <el-row :gutter="20">
        <el-col :span="6">
          <div class="menu-card" @click="$router.push('/user/accounts')">
            <div class="icon-bg bg-gold"><el-icon><CreditCard /></el-icon></div>
            <div class="menu-text">
              <span class="title">开设账户</span>
              <span class="desc">储蓄/信用卡申请</span>
            </div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="menu-card" @click="$router.push('/user/transfer')">
            <div class="icon-bg bg-red"><el-icon><Refresh /></el-icon></div>
            <div class="menu-text">
              <span class="title">转账消费</span>
              <span class="desc">实时转账 0手续费</span>
            </div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="menu-card" @click="$router.push('/user/invest')">
            <div class="icon-bg bg-purple"><el-icon><TrendCharts /></el-icon></div>
            <div class="menu-text">
              <span class="title">理财投资</span>
              <span class="desc">稳健收益 灵活存取</span>
            </div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="menu-card" @click="$router.push('/user/history')">
            <div class="icon-bg bg-blue"><el-icon><Document /></el-icon></div>
            <div class="menu-text">
              <span class="title">交易明细</span>
              <span class="desc">收支记录 一键查询</span>
            </div>
          </div>
        </el-col>
      </el-row>
    </div>

    <div style="margin-top: 20px">
      <el-row :gutter="20">
        <el-col :span="12">
          <el-card shadow="never" class="chart-card">
            <template #header>
              <div class="card-header">
                <span>投资持仓盈亏 (理财/基金)</span>
                <el-tag size="small" type="info" effect="plain">视图: v_investment_profit</el-tag>
              </div>
            </template>
            <div ref="investChartRef" style="height: 300px;"></div>
          </el-card>
        </el-col>
        <el-col :span="12">
          <el-card shadow="never" class="chart-card">
            <template #header>
               <div class="card-header">
                <span>已到期存款收益</span>
                <el-tag size="small" type="info" effect="plain">视图: v_deposit_income</el-tag>
              </div>
            </template>
            <div ref="depositChartRef" style="height: 300px;"></div>
          </el-card>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, onUnmounted, nextTick } from 'vue';
import { getMyAccounts } from '@/api/account';
import { getHoldings, getMyDeposits, getDepositIncome } from '@/api/investment';
// 补充引入了 Document 图标
import { Wallet, Money, TrendCharts, Refresh, CreditCard, Document } from '@element-plus/icons-vue';
import * as echarts from 'echarts';

const userId = localStorage.getItem('user_id');
const accounts = ref([]);
const holdings = ref([]);
const deposits = ref([]);
const depositIncomes = ref([]);

const investChartRef = ref(null);
const depositChartRef = ref(null);
let investChart = null;
let depositChart = null;

const balance = computed(() => {
    return accounts.value.reduce((acc, cur) => {
        if (cur.account_type === '储蓄卡' || cur.account_type === '信用卡') {
            return acc + Number(cur.cur_balance);
        }
        return acc;
    }, 0);
});

const totalProfit = computed(() => {
    return holdings.value.reduce((acc, cur) => {
        return acc + Number(cur.profit_loss);
    }, 0);
});

const totalAssets = computed(() => {
    let total = balance.value;
    const investVal = holdings.value.reduce((acc, cur) => {
        return acc + (Number(cur.current_price) * Number(cur.holding_shares));
    }, 0);
    
    const depositVal = deposits.value.reduce((acc, cur) => {
        if (cur.dstatus === 2) return acc;
        return acc + Number(cur.dnumber);
    }, 0);
    
    return total + investVal + depositVal;
});

const initCharts = () => {
  if (investChart) investChart.dispose();
  if (depositChart) depositChart.dispose();

  if (investChartRef.value) {
    investChart = echarts.init(investChartRef.value);
    const investNames = holdings.value.map(item => item.product_name);
    const investValues = holdings.value.map(item => item.profit_loss);

    investChart.setOption({
      tooltip: { trigger: 'axis' },
      grid: { left: '3%', right: '4%', bottom: '10%', containLabel: true },
      xAxis: { type: 'category', data: investNames, axisLabel: { interval: 0, rotate: 30 } },
      yAxis: { type: 'value', name: '盈亏(元)' },
      series: [{
        data: investValues,
        type: 'bar',
        barWidth: '40%',
        itemStyle: {
          color: (params) => params.value >= 0 ? '#F56C6C' : '#67C23A',
          borderRadius: [4, 4, 0, 0]
        }
      }]
    });
  }

  if (depositChartRef.value) {
    depositChart = echarts.init(depositChartRef.value);
    const depositLabels = depositIncomes.value.map(item => `存单${item.did.slice(-4)}`); 
    const depositValues = depositIncomes.value.map(item => item.interest_income);

    depositChart.setOption({
      tooltip: { trigger: 'axis', formatter: '{b}<br/>收益: ￥{c}' },
      grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
      xAxis: { type: 'category', data: depositLabels },
      yAxis: { type: 'value', name: '收益(元)' },
      series: [{
        data: depositValues,
        type: 'bar',
        barWidth: '40%',
        itemStyle: { 
            color: '#E60012', // 保持品牌红
            borderRadius: [4, 4, 0, 0]
        }
      }]
    });
  }
};

const handleResize = () => {
  investChart && investChart.resize();
  depositChart && depositChart.resize();
};

onMounted(async () => {
    try {
        const res = await getMyAccounts(userId);
        accounts.value = res.data || [];
    } catch (e) { console.error("账户加载失败", e); }

    try {
        const res = await getHoldings(userId);
        holdings.value = res.data || [];
    } catch (e) { console.error("持仓加载失败", e); }

    try {
        const res = await getMyDeposits(userId);
        deposits.value = res.data || [];
    } catch (e) { console.error("存款加载失败", e); }
    
    try {
        const res = await getDepositIncome(userId);
        depositIncomes.value = res.data || [];
    } catch (e) { console.error("收益加载失败", e); }

    nextTick(() => {
        initCharts();
        window.addEventListener('resize', handleResize);
    });
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
  investChart && investChart.dispose();
  depositChart && depositChart.dispose();
});
</script>

<style scoped>
.page-container { padding: 0; }

/* 1. 顶部卡片样式 (保持您现有的) */
.stat-card { color: white; border: none; border-radius: 8px; overflow: hidden; position: relative; }
.stat-card::after {
  content: ""; position: absolute; top: -50%; right: -20%; width: 200px; height: 200px;
  background: rgba(255,255,255,0.1); border-radius: 50%; pointer-events: none;
}
.red-gradient { background: linear-gradient(135deg, #E60012 0%, #FF6B6B 100%); box-shadow: 0 4px 15px rgba(230, 0, 18, 0.3); }
.gold-gradient { background: linear-gradient(135deg, #D4AF37 0%, #F3D060 100%); box-shadow: 0 4px 15px rgba(212, 175, 55, 0.3); }
.purple-gradient { background: linear-gradient(135deg, #8E44AD 0%, #C0392B 100%); box-shadow: 0 4px 15px rgba(142, 68, 173, 0.3); }

.stat-content { display: flex; justify-content: space-between; align-items: center; position: relative; z-index: 2; }
.label { font-size: 14px; opacity: 0.9; margin-bottom: 8px; font-weight: 500; }
.value { font-size: 28px; font-weight: 700; font-family: 'DIN Alternate', sans-serif; }
.stat-icon { font-size: 48px; opacity: 0.25; }

/* 2. 快捷入口优化样式 */
.section-container { margin-top: 25px; margin-bottom: 25px; }

.section-header { display: flex; align-items: center; margin-bottom: 15px; }
.title-decoration { width: 4px; height: 18px; background-color: #C20C0C; border-radius: 2px; margin-right: 10px; }
.section-title { font-size: 18px; color: #303133; margin: 0; font-weight: 600; }

/* 菜单卡片 */
.menu-card {
  background-color: #fff;
  border-radius: 8px;
  padding: 20px;
  display: flex;
  align-items: center;
  cursor: pointer;
  transition: all 0.3s ease;
  border: 1px solid #ebeef5; /* 细微边框 */
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.05);
}

.menu-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 20px rgba(194, 12, 12, 0.08); /* 红色系投影 */
  border-color: #fde2e2;
}

/* 图标背景圆 */
.icon-bg {
  width: 48px; height: 48px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 24px; margin-right: 15px; flex-shrink: 0;
  transition: transform 0.3s;
}
.menu-card:hover .icon-bg { transform: scale(1.1); }

.bg-red { background-color: #FEF0F0; color: #C20C0C; }
.bg-purple { background-color: #F2EBFA; color: #8E44AD; }
.bg-gold { background-color: #FDF6EC; color: #E6A23C; }
.bg-blue { background-color: #ECF5FF; color: #409EFF; }

.menu-text { display: flex; flex-direction: column; }
.menu-text .title { font-size: 16px; font-weight: 600; color: #303133; margin-bottom: 4px; }
.menu-text .desc { font-size: 12px; color: #909399; }

/* 3. 底部图表卡片微调 */
.chart-card { border-radius: 8px; border: none; box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.05) !important; }
.card-header { display: flex; justify-content: space-between; align-items: center; font-weight: 600; color: #303133; }
</style>