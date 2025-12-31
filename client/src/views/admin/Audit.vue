<template>
  <div class="page-container">
    <el-card class="box-card" shadow="never">
      <div class="toolbar">
        <h3>大额交易审核中心</h3>
        <div class="search-box">
          <el-input
            v-model="searchKeyword"
            placeholder="搜索流水号或发起人..."
            prefix-icon="Search"
            clearable
            style="width: 250px"
          />
        </div>
      </div>

      <el-tabs v-model="activeTab" class="audit-tabs" @tab-change="handleTabChange">
        
        <el-tab-pane label="待审核任务" name="pending">
          <el-table 
            :data="paginatedData" 
            border 
            stripe 
            style="width: 100%"
            header-cell-class-name="table-header"
          >
            <el-table-column prop="tid" label="流水号" width="150" />
            <el-table-column prop="ttime" label="提交时间" width="180" sortable />
            <el-table-column prop="sender_name" label="发起人" min-width="120" />
            <el-table-column prop="sender_phone" label="联系电话" width="140" />
            <el-table-column prop="tmoney" label="金额" width="150" sortable>
              <template #default="{ row }">
                <span style="color: #f56c6c; font-weight: bold">￥{{ row.tmoney }}</span>
              </template>
            </el-table-column>
            
            <el-table-column label="操作" width="180" fixed="right" align="center">
              <template #default="{ row }">
                <el-button type="success" size="small" @click="handleAudit(row.tid, 1)">通过</el-button>
                <el-button type="danger" size="small" @click="handleAudit(row.tid, 2)">驳回</el-button>
              </template>
            </el-table-column>
          </el-table>
          
          <el-empty v-if="currentList.length === 0" description="暂无待审核交易" />
        </el-tab-pane>

        <el-tab-pane label="已审核历史" name="audited">
          <el-table 
            :data="paginatedData" 
            border 
            stripe 
            style="width: 100%"
            header-cell-class-name="table-header"
          >
            <el-table-column prop="tid" label="流水号" width="150" />
            <el-table-column prop="sender_name" label="发起人" min-width="120" />
            <el-table-column prop="tmoney" label="金额" width="150">
               <template #default="{ row }">
                <span style="font-weight: bold">￥{{ row.tmoney }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="audit_admin" label="审核员ID" width="120" />
            
            <el-table-column label="审核结果" width="120" align="center">
              <template #default="{ row }">
                <el-tag v-if="row.tstatus === 1" type="success" effect="dark">已通过</el-tag>
                <el-tag v-else type="danger" effect="dark">已驳回</el-tag>
              </template>
            </el-table-column>
            
            <el-table-column label="操作" width="120" fixed="right" align="center">
              <template #default="{ row }">
                <el-popconfirm 
                  title="确定撤回重审吗？"
                  width="200"
                  confirm-button-text="撤回"
                  cancel-button-text="取消"
                  confirm-button-type="warning"
                  @confirm="handleRevoke(row.tid)"
                >
                  <template #reference>
                    <el-button type="warning" size="small">撤回</el-button>
                  </template>
                </el-popconfirm>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>

      <div class="pagination-container" v-if="currentList.length > 0">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next, jumper"
          :total="currentList.length"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>

    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import axios from '@/api/request';
import { ElMessage } from 'element-plus';
import { Search } from '@element-plus/icons-vue';

const activeTab = ref('pending');
const pendingList = ref([]);
const auditedList = ref([]);
const adminId = localStorage.getItem('user_id');
const searchKeyword = ref('');

// 分页状态
const currentPage = ref(1);
const pageSize = ref(10);

const loadPending = async () => {
  const res = await axios.get('/admin/audit/list');
  pendingList.value = res.data || [];
};

const loadAudited = async () => {
  const res = await axios.get('/admin/audit/audited_list');
  auditedList.value = res.data || [];
};

const handleTabChange = (tab) => {
  searchKeyword.value = ''; // 切换 Tab 时清空搜索
  currentPage.value = 1;    // 重置分页
  if (tab === 'pending') loadPending();
  if (tab === 'audited') loadAudited();
};

// 计算当前活动的列表（含搜索逻辑）
const currentList = computed(() => {
  const list = activeTab.value === 'pending' ? pendingList.value : auditedList.value;
  if (!searchKeyword.value) return list;
  
  const k = searchKeyword.value.toLowerCase();
  return list.filter(item => 
    (item.tid && item.tid.toString().includes(k)) || 
    (item.sender_name && item.sender_name.includes(k))
  );
});

// 计算分页数据
const paginatedData = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value;
  return currentList.value.slice(start, start + pageSize.value);
});

const handleSizeChange = (val) => {
  pageSize.value = val;
  currentPage.value = 1;
};

const handleCurrentChange = (val) => {
  currentPage.value = val;
};

const handleAudit = async (tid, result) => {
  try {
    await axios.post('/admin/audit/action', { tid, result, admin_id: adminId });
    ElMessage.success('操作成功');
    loadPending();
  } catch (err) {
    ElMessage.error(err.response?.data?.detail || '操作失败');
  }
};

const handleRevoke = async (tid) => {
  try {
    const res = await axios.post('/admin/audit/revoke', { tid, admin_id: adminId });
    if(res.status === 'success'){
        ElMessage.success('撤回成功');
        loadAudited();
    } else {
        ElMessage.error(res.msg);
    }
  } catch (err) {
    ElMessage.error('撤回失败: ' + (err.response?.data?.detail || '未知错误'));
  }
};

onMounted(() => {
  loadPending();
});
</script>

<style scoped>
.page-container { padding: 0; }
.box-card { border-radius: 8px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
.toolbar h3 { margin: 0; color: #303133; }
.audit-tabs :deep(.el-tabs__nav-wrap::after) { height: 1px; background-color: #ebeef5; }
.pagination-container { margin-top: 20px; display: flex; justify-content: flex-end; }
:deep(.table-header) { background-color: #f5f7fa !important; color: #606266; font-weight: 600; }
</style>