<template>
  <div class="page-container">
    <el-card class="box-card" shadow="never">
      <div class="toolbar">
        <div class="title">我的交易记录</div>
        <el-input
          v-if="activeTab === 'flow'"
          v-model="searchKeyword"
          placeholder="搜索流水号 / 姓名..."
          prefix-icon="Search"
          clearable
          style="width: 300px"
          @input="handleSearch"
        />
      </div>

      <el-tabs v-model="activeTab" @tab-change="handleTabChange">
        <el-tab-pane label="资金流水明细" name="flow">
            <el-table :data="paginatedHistory" border stripe header-cell-class-name="table-header">
                <el-table-column prop="tid" label="流水号" width="160" />
                <el-table-column prop="ttime" label="交易时间" width="170" sortable />
                <el-table-column prop="ttype" label="类型" width="90">
                    <template #default="{ row }">
                        <el-tag :type="row.ttype===1?'primary':'warning'">{{ row.ttype===1?'转账':'消费' }}</el-tag>
                    </template>
                </el-table-column>
                <el-table-column prop="sender_name" label="发起人" />
                <el-table-column prop="receiver_name" label="接收人/商户" />
                <el-table-column prop="tmoney" label="金额" sortable>
                    <template #default="{ row }">
                        <span style="font-weight:bold">￥{{ row.tmoney }}</span>
                    </template>
                </el-table-column>
                <el-table-column prop="tstatus" label="状态" align="center" width="100">
                  <template #default="{ row }">
                    <el-tag v-if="row.tstatus === 1" type="success">成功</el-tag>
                    <el-tag v-else-if="row.tstatus === 3" type="warning">审核中</el-tag>
                    <el-tag v-else type="danger">失败</el-tag>
                  </template>
                </el-table-column>
            </el-table>
            
            <div class="pagination-container" v-if="filteredHistory.length > 0">
                <el-pagination
                  v-model:current-page="currentPage"
                  v-model:page-size="pageSize"
                  :page-sizes="[10, 20, 50]"
                  layout="total, sizes, prev, pager, next, jumper"
                  :total="filteredHistory.length"
                />
            </div>
        </el-tab-pane>

        <el-tab-pane label="信用卡账单" name="bill">
            <el-table :data="paginatedBills" border stripe header-cell-class-name="table-header">
                <el-table-column prop="card_number" label="信用卡号" width="200" />
                <el-table-column label="账单月份" sortable>
                    <template #default="{ row }">
                        {{ row.bill_year }}年 {{ row.bill_month }}月
                    </template>
                </el-table-column>
                <el-table-column prop="transaction_count" label="消费笔数" align="center" />
                <el-table-column prop="total_expense" label="月度总消费" align="right">
                     <template #default="{ row }">
                        <span style="color: #f56c6c; font-size: 16px; font-weight: bold">￥{{ row.total_expense }}</span>
                    </template>
                </el-table-column>
            </el-table>

            <div class="pagination-container" v-if="bills.length > 0">
                <el-pagination
                  v-model:current-page="billPage"
                  v-model:page-size="billSize"
                  :page-sizes="[10, 20, 50]"
                  layout="total, sizes, prev, pager, next, jumper"
                  :total="bills.length"
                />
            </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { getHistory, getBills } from '@/api/transaction';
import { Search } from '@element-plus/icons-vue';

const userId = localStorage.getItem('user_id');
const activeTab = ref('flow');
const history = ref([]);
const bills = ref([]);

// 资金流水的分页与搜索
const searchKeyword = ref('');
const currentPage = ref(1);
const pageSize = ref(10);

// 修改点4：信用卡账单的分页状态
const billPage = ref(1);
const billSize = ref(10);

// 资金流水过滤与分页
const filteredHistory = computed(() => {
    if (!searchKeyword.value) return history.value;
    const k = searchKeyword.value.toLowerCase();
    return history.value.filter(item => 
        (item.tid && item.tid.toLowerCase().includes(k)) ||
        (item.sender_name && item.sender_name.includes(k)) ||
        (item.receiver_name && item.receiver_name.includes(k))
    );
});

const paginatedHistory = computed(() => {
    const start = (currentPage.value - 1) * pageSize.value;
    return filteredHistory.value.slice(start, start + pageSize.value);
});

// 修改点5：信用卡账单分页计算
const paginatedBills = computed(() => {
    const start = (billPage.value - 1) * billSize.value;
    return bills.value.slice(start, start + billSize.value);
});

const handleSearch = () => {
    currentPage.value = 1;
};

const handleTabChange = () => {
    searchKeyword.value = '';
    currentPage.value = 1;
    billPage.value = 1; // 切换 Tab 时重置分页
};

onMounted(async () => {
  const [resHist, resBill] = await Promise.all([
      getHistory(userId),
      getBills(userId)
  ]);
  history.value = resHist || [];
  bills.value = resBill.data || [];
});
</script>

<style scoped>
.page-container { padding: 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; height: 32px; } /* 固定高度防止抖动 */
.title { font-size: 18px; font-weight: bold; color: #303133; }
.pagination-container { margin-top: 20px; display: flex; justify-content: flex-end; }
:deep(.table-header) { background-color: #f5f7fa !important; font-weight: 600; color: #606266; }
</style>