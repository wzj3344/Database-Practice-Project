<template>
  <div class="page-container">
    <el-card class="box-card" shadow="never">
      <div class="toolbar">
        <h3>我的账户列表</h3>
        <el-button type="primary" @click="showOpenDialog = true">
          <el-icon style="margin-right: 5px"><Plus /></el-icon> 开设新账户
        </el-button>
      </div>

      <el-table :data="accounts" border stripe style="margin-top: 20px" header-cell-class-name="table-header">
        <el-table-column prop="cid" label="卡号" width="180" />
        <el-table-column prop="account_type" label="账户类型" width="100" />
        <el-table-column prop="cur_balance" label="当前余额" sortable>
          <template #default="{ row }">
            <span :style="{ color: row.atype===1 ? '#67c23a' : '#e6a23c', fontWeight: 'bold' }">
                ￥{{ row.cur_balance }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="transaction_limit" label="单日限额" width="120" />
        
        <el-table-column label="透支限额" width="120">
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

        <el-table-column prop="account_status" label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.account_status)">{{ row.account_status }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right" align="center">
          <template #default="{ row }">
            <el-popconfirm v-if="row.account_status === '正常'" title="确定要挂失此卡吗？" @confirm="handleStatus(row.cid, 2)">
                <template #reference><el-button type="danger" size="small" link>挂失</el-button></template>
            </el-popconfirm>
            <el-popconfirm v-if="row.account_status === '挂失'" title="确定激活此卡吗？" @confirm="handleStatus(row.cid, 1)">
                <template #reference><el-button type="success" size="small" link>激活</el-button></template>
            </el-popconfirm>
            <span v-if="row.account_status === '冻结'" style="color: #909399; font-size: 12px">请联系管理员</span>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="showOpenDialog" title="开设新账户" width="400px">
      <el-form :model="form" label-width="80px">
        <el-form-item label="账户类型">
           <el-radio-group v-model="form.atype">
             <el-radio :label="1">储蓄卡</el-radio>
             <el-radio :label="2">信用卡</el-radio>
           </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showOpenDialog = false">取消</el-button>
        <el-button type="primary" @click="handleOpen">立即开设</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import { getMyAccounts, openAccount, changeCardStatus } from '@/api/account';
import { ElMessage } from 'element-plus';
import { Plus } from '@element-plus/icons-vue';

const userId = localStorage.getItem('user_id');
const accounts = ref([]);
const showOpenDialog = ref(false);
const form = reactive({ atype: 1 });

const formatDate = (val) => {
    if(!val) return '';
    return val.toString().replace('T', ' ').substring(0, 19);
};

const loadData = async () => {
  const res = await getMyAccounts(userId);
  accounts.value = res.data || [];
};

const handleOpen = async () => {
  try {
    const res = await openAccount({ user_id: userId, ...form });
    if (res.status === 'success') {
      ElMessage.success(`开户成功！卡号：${res.data[0].card_number}`);
      showOpenDialog.value = false;
      loadData();
    } else {
      ElMessage.error(res.msg);
    }
  } catch(e) { ElMessage.error('开户失败'); }
};

const handleStatus = async (cid, status) => {
    try {
        await changeCardStatus({ cid, status });
        ElMessage.success('状态更新成功');
        loadData();
    } catch(e) { ElMessage.error('操作失败'); }
};

const getStatusType = (s) => (s === '正常' ? 'success' : s === '冻结' ? 'danger' : 'warning');

onMounted(loadData);
</script>

<style scoped>
.page-container { padding: 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; }
.toolbar h3 { margin: 0; color: #303133; }
:deep(.table-header) { background-color: #f5f7fa !important; font-weight: 600; color: #606266; }
</style>