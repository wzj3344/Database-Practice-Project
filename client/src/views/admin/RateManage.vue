<template>
  <div class="page-container">
    <el-card class="box-card" shadow="never">
      <div class="toolbar">
        <h3>定期存款利率配置</h3>
        <el-button type="primary" @click="loadData">
            <el-icon style="margin-right:5px"><Refresh /></el-icon> 刷新
        </el-button>
      </div>

      <el-table 
        :data="rates" 
        border 
        stripe 
        style="width: 100%; margin-top: 20px"
        header-cell-class-name="table-header"
      >
        <el-table-column prop="desc" label="存期描述" />
        <el-table-column prop="month" label="月数" width="100" />
        <el-table-column prop="rate" label="当前年利率">
            <template #default="{ row }">
                <span style="font-weight: bold; color: #409EFF">{{ (row.rate * 100).toFixed(2) }}%</span>
            </template>
        </el-table-column>
        <el-table-column label="操作" width="150" align="center">
            <template #default="{ row }">
                <el-button type="primary" size="small" @click="openEdit(row)">调整利率</el-button>
            </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="showDialog" title="调整利率" width="400px">
        <el-form label-width="100px">
            <el-form-item label="存期">
                <el-input v-model="form.desc" disabled />
            </el-form-item>
            <el-form-item label="新利率">
                <el-input-number 
                    v-model="form.rate" 
                    :step="0.0005" 
                    :min="0" 
                    :max="1" 
                    :precision="4" 
                    style="width: 100%" 
                />
                <div style="margin-top: 5px; color: #909399; font-size: 12px">
                    对应百分比: {{ (form.rate * 100).toFixed(2) }}%
                </div>
            </el-form-item>
        </el-form>
        <template #footer>
            <el-button @click="showDialog = false">取消</el-button>
            <el-button type="primary" @click="handleSubmit">确认调整</el-button>
        </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import { getDepositRates } from '@/api/investment'; // 复用获取接口
import { updateDepositRate } from '@/api/admin';
import { ElMessage } from 'element-plus';
import { Refresh } from '@element-plus/icons-vue';

const rates = ref([]);
const showDialog = ref(false);
const form = reactive({ month: 0, rate: 0, desc: '' });

const loadData = async () => {
    try {
        const res = await getDepositRates();
        rates.value = res.data || [];
    } catch(e) {
        ElMessage.error('加载失败');
    }
};

const openEdit = (row) => {
    form.month = row.month;
    form.rate = row.rate;
    form.desc = row.desc;
    showDialog.value = true;
};

const handleSubmit = async () => {
    try {
        await updateDepositRate({ month: form.month, rate: form.rate });
        ElMessage.success('利率更新成功');
        showDialog.value = false;
        loadData();
    } catch(e) {
        ElMessage.error(e.response?.data?.detail || '更新失败');
    }
};

onMounted(loadData);
</script>

<style scoped>
.page-container { padding: 0; }
.box-card { border-radius: 8px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; }
:deep(.table-header) { background-color: #f5f7fa !important; color: #606266; font-weight: 600; }
</style>