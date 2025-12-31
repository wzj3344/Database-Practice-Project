<template>
  <div class="page-container">
    <el-card class="box-card" shadow="never">
      <div class="toolbar">
        <h3>基金信息维护</h3>
        <div class="actions">
          <el-input
            v-model="searchKeyword"
            placeholder="搜索基金名称..."
            prefix-icon="Search"
            clearable
            style="width: 200px; margin-right: 15px"
          />
          <el-button type="primary" @click="showAddDialog = true">
            <el-icon style="margin-right: 5px"><Plus /></el-icon>发布新基金
          </el-button>
        </div>
      </div>

      <el-table 
        :data="paginatedData" 
        style="width: 100%; margin-top: 20px" 
        border 
        stripe
        header-cell-class-name="table-header"
      >
        <el-table-column prop="fid" label="基金ID" width="120" sortable />
        <el-table-column prop="fname" label="基金名称" min-width="150" />
        
        <el-table-column prop="fworth" label="单位净值" width="120" sortable>
          <template #default="{ row }">
            <span style="color: #409EFF; font-weight: bold">{{ row.fworth }}</span>
          </template>
        </el-table-column>

        <el-table-column prop="frisk" label="风险等级" width="160" sortable>
          <template #default="{ row }">
            <el-rate v-model="row.frisk" disabled text-color="#ff9900" score-template="{value}" />
          </template>
        </el-table-column>

        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.fstatus === 1 ? 'success' : 'info'" effect="dark">
              {{ row.fstatus === 1 ? '在售' : '停售' }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="操作" width="220" fixed="right" align="center">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="openEditDialog(row)">修改</el-button>
            
            <el-button 
              v-if="row.fstatus === 1" 
              type="warning" 
              size="small" 
              @click="toggleStatus(row, 0)"
            >
              下架
            </el-button>
            <el-button 
              v-else 
              type="success" 
              size="small" 
              @click="toggleStatus(row, 1)"
            >
              上架
            </el-button>

            <el-popconfirm 
              title="确定要物理删除吗？" 
              confirm-button-text="删除"
              cancel-button-text="取消"
              confirm-button-type="danger"
              @confirm="handleDelete(row)"
            >
              <template #reference>
                <el-button type="danger" size="small">删除</el-button>
              </template>
            </el-popconfirm>
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

    <el-dialog v-model="showAddDialog" title="发布新基金" width="500px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="基金ID">
          <el-input v-model="form.fid" placeholder="如 FD008" />
        </el-form-item>
        <el-form-item label="名称">
          <el-input v-model="form.fname" />
        </el-form-item>
        <el-form-item label="净值">
          <el-input-number v-model="form.fworth" :step="0.01" style="width: 100%" />
        </el-form-item>
        <el-form-item label="起购金额">
          <el-input-number v-model="form.fleast" :step="100" style="width: 100%" />
        </el-form-item>
        <el-form-item label="风险等级">
          <el-slider v-model="form.frisk" :min="1" :max="5" show-stops />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showAddDialog = false">取消</el-button>
        <el-button type="primary" @click="handleAdd">确认发布</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="showEditDialog" title="修改基金信息" width="450px">
      <el-form :model="editForm" label-width="100px">
        <el-form-item label="基金ID">
           <el-input v-model="editForm.fid" disabled />
        </el-form-item>
        <el-form-item label="基金名称">
          <el-input v-model="editForm.fname" />
        </el-form-item>
        <el-form-item label="最新净值">
          <el-input-number v-model="editForm.fworth" :min="0" :precision="2" :step="0.01" style="width: 100%" />
        </el-form-item>
        <el-form-item label="风险等级">
           <el-slider v-model="editForm.frisk" :min="1" :max="5" show-stops />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showEditDialog = false">取消</el-button>
        <el-button type="primary" @click="handleUpdate">确认修改</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue';
import { getFunds, addFund, updateFund, deleteFund } from '@/api/admin';
import { ElMessage } from 'element-plus';
import { Search, Plus } from '@element-plus/icons-vue';

const funds = ref([]);
const showAddDialog = ref(false);
const showEditDialog = ref(false);
const searchKeyword = ref('');
const currentPage = ref(1);
const pageSize = ref(10);

const form = reactive({ fid: '', fname: '', fworth: 1.0, fleast: 100, frisk: 3 });
const editForm = reactive({ fid: '', fname: '', fworth: 0, frisk: 1 });

const loadData = async () => {
  try {
    const res = await getFunds();
    funds.value = res.data || [];
  } catch (err) { ElMessage.error('加载失败'); }
};

const filteredData = computed(() => {
  if (!searchKeyword.value) return funds.value;
  return funds.value.filter(f => f.fname.toLowerCase().includes(searchKeyword.value.toLowerCase()));
});

const paginatedData = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value;
  return filteredData.value.slice(start, start + pageSize.value);
});

const handleSizeChange = (val) => { pageSize.value = val; currentPage.value = 1; };
const handleCurrentChange = (val) => { currentPage.value = val; };

const toggleStatus = async (row, status) => {
  try {
    await updateFund({ fid: row.fid, fstatus: status });
    ElMessage.success('状态已更新');
    loadData();
  } catch (e) { ElMessage.error('操作失败'); }
};

const handleAdd = async () => {
  try {
    const res = await addFund(form);
    if (res.status === 'success') {
      ElMessage.success('发布成功');
      showAddDialog.value = false;
      form.fid = ''; form.fname = ''; form.fworth = 1.0; 
      loadData();
    } else { ElMessage.error(res.msg); }
  } catch (e) { ElMessage.error('请求异常: ' + e.message); }
};

const openEditDialog = (row) => {
  Object.assign(editForm, { fid: row.fid, fname: row.fname, fworth: row.fworth, frisk: row.frisk });
  showEditDialog.value = true;
};

const handleUpdate = async () => {
  try {
    const res = await updateFund(editForm);
    if (res.status === 'success') {
        ElMessage.success('修改成功');
        showEditDialog.value = false;
        loadData();
    } else { ElMessage.error(res.msg); }
  } catch (e) { ElMessage.error('修改失败'); }
};

const handleDelete = async (row) => {
  try {
    const res = await deleteFund({ fid: row.fid });
    if (res.status === 'success') {
      ElMessage.success('已删除');
      loadData();
    } else { ElMessage.error(res.msg); }
  } catch (e) { ElMessage.error('删除失败'); }
};

onMounted(loadData);
</script>

<style scoped>
.page-container { padding: 0; }
.box-card { border-radius: 8px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; }
.toolbar h3 { margin: 0; color: #303133; }
.actions { display: flex; align-items: center; }
.pagination-container { margin-top: 20px; display: flex; justify-content: flex-end; }
:deep(.table-header) { background-color: #f5f7fa !important; color: #606266; font-weight: 600; }
</style>