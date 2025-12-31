<template>
  <div class="page-container">
    <el-card class="box-card" shadow="never">
      <div class="toolbar">
        <h3>账户管理</h3>
        <div class="search-box">
          <el-input v-model="searchKeyword" placeholder="搜索姓名或卡号..." prefix-icon="Search" clearable style="width: 250px" />
        </div>
      </div>

      <el-table :data="paginatedData" style="width: 100%; margin-top: 20px" border stripe header-cell-class-name="table-header">
        <el-table-column prop="bank_user_id" label="用户ID" min-width="100" sortable />
        <el-table-column prop="bank_user_name" label="姓名" min-width="100" />
        <el-table-column prop="cid" label="卡号" width="180" />
        
        <el-table-column label="类型" width="90" align="center">
           <template #default="{ row }">
              <el-tag :type="row.atype === 1 ? '' : 'warning'" effect="plain">
                {{ row.atype === 1 ? '储蓄卡' : '信用卡' }}
              </el-tag>
           </template>
        </el-table-column>

        <el-table-column prop="cur_balance" label="余额" width="130" sortable>
          <template #default="{ row }">
            <span class="money-text">￥{{ row.cur_balance }}</span>
          </template>
        </el-table-column>
        
        <el-table-column prop="transaction_limit" label="日限额" width="110" />

        <el-table-column label="透支限额" width="110">
          <template #default="{ row }">
             <span v-if="row.atype === 2" style="color: #e6a23c">￥{{ row.credit_limit }}</span>
             <span v-else>-</span>
          </template>
        </el-table-column>

        <el-table-column label="开卡时间" width="170" sortable>
           <template #default="{ row }">
              {{ formatDate(row.open_time) }}
           </template>
        </el-table-column>
        
        <el-table-column label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.astatus)" effect="dark" size="small">
              {{ getStatusText(row.astatus) }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="操作" width="180" fixed="right" align="center">
          <template #default="{ row }">
            <el-button v-if="row.astatus === 1" type="danger" size="small" @click="changeStatus(row.cid, 3)">冻结</el-button>
            <el-button v-else type="success" size="small" @click="changeStatus(row.cid, 1)">激活</el-button>
            <el-button type="primary" size="small" @click="openLimitDialog(row)">调额</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-container">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next, jumper"
          :total="filteredData.length"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <el-dialog v-model="showLimitDialog" title="账户额度调整" width="400px">
      <el-form :model="limitForm" label-width="100px">
        <el-form-item label="卡号">
           <el-input v-model="limitForm.cid" disabled />
        </el-form-item>
        <el-form-item label="单日限额">
           <el-input-number v-model="limitForm.limit" :min="0" :step="1000" style="width: 100%" />
           <div class="tip-text">控制每日转账/消费总额</div>
        </el-form-item>
        <el-form-item label="信用额度" v-if="limitForm.atype === 2">
           <el-input-number v-model="limitForm.credit_limit" :min="0" :step="1000" style="width: 100%" />
           <div class="tip-text">控制最大透支金额</div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showLimitDialog = false">取消</el-button>
        <el-button type="primary" @click="submitLimitChange">确认修改</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue';
import axios from '@/api/request';
import { ElMessage } from 'element-plus';
import { Search } from '@element-plus/icons-vue';

const accounts = ref([]);
const showLimitDialog = ref(false);
const limitForm = reactive({ cid: '', limit: 0, credit_limit: 0, atype: 1 });
const searchKeyword = ref('');
const currentPage = ref(1);
const pageSize = ref(10);

// 简单的时间格式化工具
const formatDate = (val) => {
    if(!val) return '';
    return val.toString().replace('T', ' ').substring(0, 19);
};

const loadData = async () => {
  try {
    const res = await axios.get('/admin/account/list');
    accounts.value = res.data || [];
  } catch (error) {
    ElMessage.error('数据加载失败');
  }
};

const filteredData = computed(() => {
  if (!searchKeyword.value) return accounts.value;
  const keyword = searchKeyword.value.toLowerCase();
  return accounts.value.filter(item => 
    (item.bank_user_name && item.bank_user_name.toLowerCase().includes(keyword)) ||
    (item.cid && item.cid.toString().includes(keyword))
  );
});

const paginatedData = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value;
  return filteredData.value.slice(start, start + pageSize.value);
});

const handleSizeChange = (val) => { pageSize.value = val; currentPage.value = 1; };
const handleCurrentChange = (val) => { currentPage.value = val; };

const changeStatus = async (cid, status) => {
  await axios.post('/admin/account/status', { cid, status });
  ElMessage.success('状态更新成功');
  loadData();
};

const openLimitDialog = (row) => {
    limitForm.cid = row.cid;
    limitForm.limit = row.transaction_limit;
    limitForm.atype = row.atype;
    limitForm.credit_limit = row.credit_limit || 0; 
    showLimitDialog.value = true;
};

const submitLimitChange = async () => {
    try {
        await axios.post('/admin/account/limit', limitForm);
        ElMessage.success('额度修改成功');
        showLimitDialog.value = false;
        loadData();
    } catch(e) { ElMessage.error('修改失败'); }
};

const getStatusType = (s) => (s === 1 ? 'success' : s === 3 ? 'danger' : 'warning');
const getStatusText = (s) => (s === 1 ? '正常' : s === 3 ? '冻结' : '挂失');

onMounted(loadData);
</script>

<style scoped>
.page-container { padding: 0; }
.box-card { border-radius: 8px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; }
.toolbar h3 { margin: 0; color: #303133; }
.money-text { font-weight: bold; color: #67c23a; }
.pagination-container { margin-top: 20px; display: flex; justify-content: flex-end; }
.tip-text { font-size: 12px; color: #909399; line-height: 1.2; margin-top: 5px; }
:deep(.table-header) { background-color: #f5f7fa !important; color: #606266; font-weight: 600; }
</style>