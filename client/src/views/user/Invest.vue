<template>
  <div class="page-container">
    <el-tabs type="border-card" class="invest-tabs">
      
      <el-tab-pane label="理财产品超市">
        <div class="tab-toolbar">
           <el-input v-model="prodSearch" placeholder="搜索理财产品..." prefix-icon="Search" clearable style="width: 250px" />
        </div>

        <el-table :data="paginatedProducts" stripe>
          <el-table-column prop="pname" label="产品名称" />
          <el-table-column prop="pworth" label="净值" width="100" />
          <el-table-column prop="prisk" label="风险等级" width="140">
             <template #default="{ row }">
               <el-rate v-model="row.prisk" disabled text-color="#ff9900" />
             </template>
          </el-table-column>
          <el-table-column prop="pleast" label="起购份额" width="120" />
          <el-table-column label="操作" width="180">
            <template #default="{ row }">
               <el-button type="primary" size="small" @click="openBuyDialog(row, 1)">购买</el-button>
               <el-button type="warning" size="small" @click="openSellDialog(row, 1)">卖出</el-button>
            </template>
          </el-table-column>
        </el-table>

        <div class="pagination-container" v-if="filteredProducts.length > 0">
            <el-pagination 
                v-model:current-page="prodPage" 
                v-model:page-size="prodSize" 
                :total="filteredProducts.length" 
                layout="total, prev, pager, next"
            />
        </div>
      </el-tab-pane>

      <el-tab-pane label="精选基金">
        <div class="tab-toolbar">
           <el-input v-model="fundSearch" placeholder="搜索基金名称..." prefix-icon="Search" clearable style="width: 250px" />
        </div>

        <el-table :data="paginatedFunds" stripe>
          <el-table-column prop="fname" label="基金名称" />
          <el-table-column prop="fworth" label="净值" width="100" />
           <el-table-column prop="frisk" label="风险等级" width="140">
             <template #default="{ row }">
               <el-rate v-model="row.frisk" disabled text-color="#ff9900" />
             </template>
          </el-table-column>
          <el-table-column prop="fleast" label="起购份额" width="120" />
          <el-table-column label="操作" width="180">
            <template #default="{ row }">
               <el-button type="success" size="small" @click="openBuyDialog(row, 2)">申购</el-button>
               <el-button type="warning" size="small" @click="openSellDialog(row, 2)">赎回</el-button>
            </template>
          </el-table-column>
        </el-table>

        <div class="pagination-container" v-if="filteredFunds.length > 0">
            <el-pagination 
                v-model:current-page="fundPage" 
                v-model:page-size="fundSize" 
                :total="filteredFunds.length" 
                layout="total, prev, pager, next"
            />
        </div>
      </el-tab-pane>
      
      <el-tab-pane label="定期存款办理">
        <div style="padding: 20px; max-width: 500px">
           <el-form label-width="100px">
             <el-form-item label="付款账户">
                <el-select v-model="depositForm.cid" placeholder="选择储蓄卡" style="width:100%">
                    <el-option 
                        v-for="acc in savingsAccounts" 
                        :key="acc.cid" 
                        :label="`${acc.cid} (余额: ${acc.cur_balance})`" 
                        :value="acc.cid" 
                    />
                </el-select>
             </el-form-item>
             
             <el-form-item label="存款金额">
                <el-input-number 
                  v-model="depositForm.money" 
                  :min="1000" 
                  :step="1000" 
                  :controls="false" 
                  placeholder="请输入金额 (最低1000)"
                  style="width: 100%" 
                />
             </el-form-item>

             <el-form-item label="存期">
                <el-radio-group v-model="depositForm.months">
                   <el-radio-button :label="3">3个月</el-radio-button>
                   <el-radio-button :label="6">6个月</el-radio-button>
                   <el-radio-button :label="12">1年</el-radio-button>
                   <el-radio-button :label="24">2年</el-radio-button>
                </el-radio-group>
             </el-form-item>
             <el-form-item label="预计年化">
                <span style="color: #f56c6c; font-weight: bold">{{ currentRateDisplay }}</span>
             </el-form-item>
             <el-form-item>
                <el-button type="primary" @click="handleDeposit">立即存入</el-button>
             </el-form-item>
           </el-form>
        </div>
        
        <el-divider content-position="left">我的存单列表</el-divider>
        
        <el-table :data="paginatedDeposits" border size="small" stripe>
             <el-table-column prop="did" label="存单号" width="150" />
             <el-table-column prop="dnumber" label="本金">
                <template #default="{ row }">
                    ￥{{ row.dnumber }}
                </template>
             </el-table-column>
             <el-table-column prop="drate" label="年利率" width="100">
                <template #default="{ row }">
                    {{ (row.drate * 100).toFixed(2) }}%
                </template>
             </el-table-column>
             <el-table-column prop="dstart" label="起息日" width="120">
                <template #default="{ row }">
                    {{ formatDate(row.dstart) }}
                </template>
             </el-table-column>
             <el-table-column prop="dover" label="到期日" width="120">
                <template #default="{ row }">
                    {{ formatDate(row.dover) }}
                </template>
             </el-table-column>
             <el-table-column label="状态" align="center" width="100">
                <template #default="{ row }">
                    <el-tag v-if="row.dstatus === 2" type="info" effect="dark">已取回</el-tag>
                    <el-tag v-else-if="isExpired(row.dover)" type="success" effect="plain">已到期</el-tag>
                    <el-tag v-else type="primary" effect="plain">持有中</el-tag>
                </template>
             </el-table-column>           
             <el-table-column label="操作" width="100" align="center">
                <template #default="{ row }">
                   <el-popconfirm 
                      v-if="row.dstatus !== 2"
                      :title="isExpired(row.dover) ? '确认到期支取吗？' : '未到期取回将损失利息，确定继续？'"
                      width="220"
                      confirm-button-text="确定"
                      cancel-button-text="取消"
                      @confirm="handleWithdraw(row)"
                   >
                      <template #reference>
                         <el-button type="danger" size="small" link>取回</el-button>
                      </template>
                   </el-popconfirm>
                   
                   <el-button v-else type="info" size="small" link disabled>已结清</el-button>
                </template>
             </el-table-column>
        </el-table>
        <div class="pagination-container" v-if="myDeposits.length > 0">
            <el-pagination 
                v-model:current-page="depositPage" 
                v-model:page-size="depositSize" 
                :total="myDeposits.length" 
                layout="total, prev, pager, next"
            />
        </div>
      </el-tab-pane>

      <el-tab-pane label="投资收益">
         <div style="margin-bottom: 20px; display: flex; justify-content: flex-end;">
            <el-radio-group v-model="viewMode" @change="handleViewChange">
               <el-radio-button label="list">列表详情</el-radio-button>
               <el-radio-button label="pie">资产分布</el-radio-button>
               <el-radio-button label="bar">盈亏分析</el-radio-button>
            </el-radio-group>
         </div>

         <div v-if="viewMode === 'list'">
             <el-table :data="paginatedProfitList" border stripe header-cell-class-name="table-header">
                <el-table-column prop="product_name" label="产品名称" />
                <el-table-column prop="investment_type" label="类型" width="100">
                   <template #default="{ row }">
                      <el-tag :type="row.investment_type==='理财产品'?'':'success'">{{ row.investment_type }}</el-tag>
                   </template>
                </el-table-column>
                <el-table-column prop="holding_shares" label="持有份额" />
                <el-table-column prop="current_price" label="当前净值" />
                <el-table-column prop="total_cost" label="总成本" />

               <el-table-column prop="realized_profit" label="已卖出金额" width="120">
                  <template #default="{ row }">
                     <span style="color: #67c23a">￥{{ row.realized_profit }}</span>
                  </template>
               </el-table-column>

                <el-table-column prop="profit_loss" label="浮动盈亏" sortable>
                   <template #default="{ row }">
                      <span :style="{ color: row.profit_loss >= 0 ? '#f56c6c' : '#67c23a', fontWeight: 'bold' }">
                         {{ row.profit_loss > 0 ? '+' : '' }}{{ row.profit_loss }}
                      </span>
                   </template>
                </el-table-column>
             </el-table>
             <div class="pagination-container" v-if="holdings.length > 0">
                <el-pagination 
                    v-model:current-page="profitPage" 
                    v-model:page-size="profitSize" 
                    :total="holdings.length" 
                    layout="total, prev, pager, next"
                />
             </div>
         </div>

         <div v-else class="chart-wrapper">
            <div ref="chartContainer" style="width: 100%; height: 400px;"></div>
         </div>
      </el-tab-pane>
    </el-tabs>

    <el-dialog v-model="showBuyDialog" :title="buyType===1?'购买理财':'申购基金'" width="400px">
       <el-form label-width="100px">
          <el-form-item label="产品名称">
             <el-input v-model="buyForm.itemName" disabled />
          </el-form-item>
          <el-form-item label="当前净值">
             <span style="font-weight: bold; color: #409EFF">{{ buyForm.unitPrice }}</span>
          </el-form-item>
          <el-form-item label="付款账户">
            <el-select v-model="buyForm.cid" placeholder="请选择储蓄卡" style="width:100%">
                <el-option 
                    v-for="acc in savingsAccounts" 
                    :key="acc.cid" 
                    :label="`${acc.cid} (余额: ${acc.cur_balance})`" 
                    :value="acc.cid" 
                />
            </el-select>
           </el-form-item>
          <el-form-item label="购买份额">
             <el-input-number 
               v-model="buyForm.shares" 
               :min="1" 
               :step="100" 
               :precision="0"
               placeholder="输入份额"
               style="width: 100%" 
             />
          </el-form-item>
          <el-form-item label="预计支付">
             <span style="color: #f56c6c; font-size: 16px; font-weight: bold">
               ￥{{ (buyForm.shares * buyForm.unitPrice).toFixed(2) }}
             </span>
          </el-form-item>
       </el-form>
       <template #footer>
          <el-button @click="showBuyDialog=false">取消</el-button>
          <el-button type="primary" @click="handlePurchase">确认支付</el-button>
       </template>

    </el-dialog>
    <el-dialog v-model="showSellDialog" :title="sellType===1?'卖出理财':'赎回基金'" width="400px">
       <el-form label-width="100px">
          <el-form-item label="产品名称">
             <el-input v-model="sellForm.itemName" disabled />
          </el-form-item>
          <el-form-item label="当前净值">
             <span style="font-weight: bold; color: #409EFF">{{ sellForm.unitPrice }}</span>
          </el-form-item>
          
          <el-form-item label="收款账户">
             <el-select 
                v-model="sellForm.cid" 
                placeholder="请选择持有该产品的卡" 
                style="width:100%"
                @change="checkHolding"
             >
                 <el-option 
                   v-for="acc in savingsAccounts" 
                   :key="acc.cid" 
                   :label="acc.cid" 
                   :value="acc.cid" 
                 />
             </el-select>
          </el-form-item>

          <el-form-item label="当前持有">
             <span style="color: #909399">{{ currentHoldingShares }} 份</span>
          </el-form-item>

          <el-form-item label="卖出份额">
             <el-input-number 
               v-model="sellForm.shares" 
               :min="0" 
               :max="currentHoldingShares" 
               :step="100" 
               :precision="0"
               :controls="false"
               style="width: 100%" 
             />
          </el-form-item>
          <el-form-item label="预计回款">
             <span style="color: #67c23a; font-size: 16px; font-weight: bold">
               ￥{{ (sellForm.shares * sellForm.unitPrice).toFixed(2) }}
             </span>
          </el-form-item>
       </el-form>
       <template #footer>
          <el-button @click="showSellDialog=false">取消</el-button>
          <el-button type="warning" @click="handleSell">确认卖出</el-button>
       </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed, nextTick, onUnmounted } from 'vue';
import { getProducts, purchase, sell, createDeposit, getHoldings, getDepositIncome, getMyDeposits, getDepositRates, withdrawDeposit} from '@/api/investment';
import { getMyAccounts } from '@/api/account';
import { ElMessage } from 'element-plus';
import * as echarts from 'echarts';
import { Search } from '@element-plus/icons-vue'

const userId = localStorage.getItem('user_id');
const products = ref([]);
const funds = ref([]);
const holdings = ref([]);
const myDeposits = ref([]);
const accounts = ref([]);
const ratesList = ref([]);
const sellType = ref(1);
const sellForm = reactive({ cid: '', item_id: '', itemName: '', shares: 0, unitPrice: 1.0 });
const currentHoldingShares = ref(0); // 用于在弹窗中显示当前选中卡持有多少

// 理财产品搜索与分页
const prodSearch = ref('');
const prodPage = ref(1);
const prodSize = ref(10);

const filteredProducts = computed(() => {
    if (!prodSearch.value) return products.value;
    return products.value.filter(p => p.pname.toLowerCase().includes(prodSearch.value.toLowerCase()));
});
const paginatedProducts = computed(() => {
    const start = (prodPage.value - 1) * prodSize.value;
    return filteredProducts.value.slice(start, start + prodSize.value);
});

// 基金搜索与分页
const fundSearch = ref('');
const fundPage = ref(1);
const fundSize = ref(10);

const filteredFunds = computed(() => {
    if (!fundSearch.value) return funds.value;
    return funds.value.filter(f => f.fname.toLowerCase().includes(fundSearch.value.toLowerCase()));
});
const paginatedFunds = computed(() => {
    const start = (fundPage.value - 1) * fundSize.value;
    return filteredFunds.value.slice(start, start + fundSize.value);
});

const depositPage = ref(1);
const depositSize = ref(5); // 存单比较高，每页少显示点
const profitPage = ref(1);
const profitSize = ref(10);

// 修改点：视图控制
const viewMode = ref('list');
const chartContainer = ref(null);
let myChart = null;
const savingsAccounts = computed(() => accounts.value.filter(a => a.atype === 1 && a.account_status === '正常'));
const showBuyDialog = ref(false);
const showSellDialog = ref(false);


const buyType = ref(1);
const buyForm = reactive({ 
    cid: '', 
    item_id: '', 
    itemName: '', 
    shares: 1000, 
    unitPrice: 1.0 
});
const depositForm = reactive({ cid: '', money: 10000, months: 6 });

const formatDate = (val) => {
    if(!val) return '';
    return val.toString().split('T')[0];
};

const isExpired = (dover) => {
    if(!dover) return false;
    return new Date(dover) <= new Date();
};

const loadData = async () => {
    const [pRes, fRes, hRes, aRes, depRes, rateRes] = await Promise.all([
        getProducts('financial'),
        getProducts('fund'),
        getHoldings(userId),
        getMyAccounts(userId),
        getMyDeposits(userId),
        getDepositRates()
    ]);
    
    products.value = pRes.data || [];
    funds.value = fRes.data || [];
    holdings.value = hRes.data || [];
    accounts.value = aRes.data || [];
    myDeposits.value = depRes.data || [];
    ratesList.value = rateRes?.data || [];
    
    // 如果当前在图表模式下刷新数据，需要重绘
    if (viewMode.value !== 'list') {
        renderChart();
    }
};

// 修改点：渲染图表逻辑
const renderChart = () => {
    if (!chartContainer.value) return;
    
    // 销毁旧实例
    if (myChart) myChart.dispose();
    myChart = echarts.init(chartContainer.value);
    
    const data = holdings.value;
    let option = {};

    if (viewMode.value === 'pie') {
        // 资产分布图 (按市值)
        const pieData = data.map(item => ({
            name: item.product_name,
            value: (Number(item.holding_shares) * Number(item.current_price)).toFixed(2)
        }));
        
        option = {
            title: { text: '持有资产分布', left: 'center' },
            tooltip: { trigger: 'item', formatter: '{b}: ￥{c} ({d}%)' },
            legend: { bottom: '0%' },
            series: [{
                type: 'pie',
                radius: ['40%', '70%'], // 环形图
                data: pieData,
                emphasis: { itemStyle: { shadowBlur: 10, shadowOffsetX: 0, shadowColor: 'rgba(0, 0, 0, 0.5)' } }
            }]
        };
    } else if (viewMode.value === 'bar') {
        // 盈亏分析图
        const names = data.map(i => i.product_name);
        const values = data.map(i => Number(i.profit_loss));
        
        option = {
            title: { text: '各产品持仓盈亏', left: 'center' },
            tooltip: { trigger: 'axis' },
            grid: { left: '3%', right: '4%', bottom: '10%', containLabel: true },
            xAxis: { type: 'category', data: names, axisLabel: { interval: 0, rotate: 30 } },
            yAxis: { type: 'value', name: '盈亏(元)' },
            series: [{
                data: values,
                type: 'bar',
                barWidth: '40%',
                label: { show: true, position: 'top' },
                itemStyle: {
                    color: (params) => params.value >= 0 ? '#f56c6c' : '#67c23a'
                }
            }]
        };
    }
    
    myChart.setOption(option);
};

// 修改点：切换视图处理
const handleViewChange = async () => {
    if (viewMode.value !== 'list') {
        await nextTick(); // 等待 DOM 渲染
        renderChart();
    }
};

const paginatedDeposits = computed(() => {
    const start = (depositPage.value - 1) * depositSize.value;
    return myDeposits.value.slice(start, start + depositSize.value);
});

// 修改点7：新增 投资收益列表 分页计算
const paginatedProfitList = computed(() => {
    const start = (profitPage.value - 1) * profitSize.value;
    return holdings.value.slice(start, start + profitSize.value);
});

const openBuyDialog = (row, type) => {
    buyType.value = type;
    buyForm.item_id = type === 1 ? row.pid : row.fid;
    buyForm.itemName = type === 1 ? row.pname : row.fname;
    const leastShares = type === 1 ? row.pleast : row.fleast;
    buyForm.shares = leastShares;
    buyForm.unitPrice = type === 1 ? row.pworth : row.fworth;
    showBuyDialog.value = true;
};

const handlePurchase = async () => {
    if(!buyForm.cid) return ElMessage.warning('请选择付款账户');
    try {
        const res = await purchase({ 
            cid: buyForm.cid, 
            item_id: buyForm.item_id, 
            shares: buyForm.shares, 
            type: buyType.value 
        });

        if (res.status === 'success') {
            ElMessage.success('交易成功');
            showBuyDialog.value = false;
            loadData();
        } else {
            ElMessage.error(res.msg || '购买失败');
        }
    } catch(e) { 
        ElMessage.error(e.response?.data?.detail || '请求发生异常'); 
    }
};

const handleDeposit = async () => {
    if(!depositForm.cid) return ElMessage.warning('请选择账户');
    if(depositForm.money <= 0) return ElMessage.warning('请输入有效的存款金额');
    try {
        const res = await createDeposit(depositForm);
        if (res.status === 'success') {
            ElMessage.success('存款办理成功');
            loadData(); 
        } else {
            ElMessage.error(res.msg || '办理失败');
        }
    } catch(e) { ElMessage.error(e.response?.data?.detail || '办理失败'); }
};

const currentRateDisplay = computed(() => {
    if (!ratesList.value || ratesList.value.length === 0) return '--';
    const item = ratesList.value.find(r => Number(r.month) === Number(depositForm.months));
    return item ? (Number(item.rate) * 100).toFixed(2) + '%' : '--';
});

const openSellDialog = (row, type) => {
    sellType.value = type;
    sellForm.item_id = type === 1 ? row.pid : row.fid;
    sellForm.itemName = type === 1 ? row.pname : row.fname;
    sellForm.unitPrice = type === 1 ? row.pworth : row.fworth;
    sellForm.shares = 0;
    sellForm.cid = '';
    currentHoldingShares.value = 0;
    showSellDialog.value = true;
};

// 辅助功能：当用户在卖出弹窗选择卡号时，自动去 holdings 数据里找他持有多少份
const checkHolding = () => {
    if (!sellForm.cid || !sellForm.item_id) return;
    
    // 从已加载的 holdings 数组中查找 (注意：holdings 包含了所有卡的所有持仓)
    // 需要后端 getHoldings 返回的数据里包含 item_id (pid/fid) 才能精确匹配
    // 假设 v_investment_profit 视图里没有直接返回 pid/fid，可能只有 product_name
    // 如果视图里没有 ID，这里可能只能靠名称匹配，或者修改视图增加 ID 字段
    // 为了稳健，我们这里简单通过 product_name 匹配（假设名称唯一），最好是改视图加ID
    
    const holdingItem = holdings.value.find(h => 
        h.cid === sellForm.cid && h.product_name === sellForm.itemName
    );
    
    if (holdingItem) {
        currentHoldingShares.value = Number(holdingItem.holding_shares);
        // 自动填入最大值方便用户
        sellForm.shares = currentHoldingShares.value; 
    } else {
        currentHoldingShares.value = 0;
        sellForm.shares = 0;
        ElMessage.info('该卡未持有此产品');
    }
};

// 执行卖出
const handleSell = async () => {
    if(!sellForm.cid) return ElMessage.warning('请选择收款账户');
    if(sellForm.shares <= 0) return ElMessage.warning('请输入有效的卖出份额');
    if(sellForm.shares > currentHoldingShares.value) return ElMessage.warning('卖出份额超过持有上限');

    try {
        const res = await sell({
            cid: sellForm.cid,
            item_id: sellForm.item_id,
            shares: sellForm.shares,
            type: sellType.value
        });

        if (res.status === 'success') {
            ElMessage.success('卖出成功，资金已到账');
            showSellDialog.value = false;
            loadData(); // 刷新数据，更新持仓和余额
        } else {
            ElMessage.error(res.msg || '卖出失败');
        }
    } catch(e) {
        ElMessage.error(e.response?.data?.detail || '请求发生异常');
    }
};

const handleWithdraw = async (row) => {
    try {
        const res = await withdrawDeposit({ did: row.did, cid: row.cid });
        
        if (res.status === 'success') {
            ElMessage.success(res.msg); // 后端会返回具体的本金和利息数额
            loadData(); // 刷新列表和余额
        } else {
            ElMessage.error(res.msg || '取回失败');
        }
    } catch(e) {
        ElMessage.error(e.response?.data?.detail || '操作异常');
    }
};

// 修改点：监听窗口大小变化
const resizeHandler = () => {
    if (myChart) myChart.resize();
};

onMounted(() => {
    loadData();
    window.addEventListener('resize', resizeHandler);
});

onUnmounted(() => {
    window.removeEventListener('resize', resizeHandler);
    if (myChart) myChart.dispose();
});

</script>

<style scoped>
.page-container { padding: 0; }
.pagination-container { margin-top: 15px; display: flex; justify-content: flex-end; }
:deep(.table-header) { background-color: #f5f7fa !important; font-weight: 600; color: #606266; }
</style>