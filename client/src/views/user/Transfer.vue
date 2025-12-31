<template>
  <div class="page-container">
    <el-card class="box-card" shadow="never">
      <div class="form-wrapper">
        <h2 class="form-title">转账 / 消费</h2>
        <el-form :model="form" label-width="100px" size="large">
          <el-form-item label="付款账户">
            <el-select v-model="form.send_cid" placeholder="请选择付款卡" style="width: 100%">
              <el-option 
                v-for="acc in accounts" 
                :key="acc.cid" 
                :label="`${acc.cid} (余额: ${acc.cur_balance})`" 
                :value="acc.cid" 
                :disabled="acc.account_status !== '正常'"
              />
            </el-select>
          </el-form-item>
          
          <el-form-item label="交易类型">
            <el-radio-group v-model="form.trans_type">
              <el-radio :label="1">转账</el-radio>
              <el-radio :label="2">消费支付</el-radio>
            </el-radio-group>
          </el-form-item>

          <el-form-item label="收款卡号">
             <el-input 
               v-model="form.get_cid" 
               :placeholder="form.trans_type === 2 ? '商户号自动填充' : '请输入对方卡号'" 
               :disabled="form.trans_type === 2"
             />
          </el-form-item>

          <el-form-item label="金额">
              <el-input-number 
                  v-model="form.amount" 
                  :min="0" 
                  :precision="2" 
                  :step="100" 
                  placeholder="输入金额"
                  style="width: 100%" 
              />
          </el-form-item>

          <el-form-item>
             <el-button type="primary" @click="onSubmit" style="width: 100%">确认提交</el-button>
          </el-form-item>
        </el-form>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { reactive, ref, onMounted, watch } from 'vue';
import { getMyAccounts } from '@/api/account';
import { transferMoney } from '@/api/transaction';
import { ElMessage } from 'element-plus';

const userId = localStorage.getItem('user_id');
const accounts = ref([]);
const form = reactive({
  send_cid: '',
  get_cid: '',
  amount: 0,
  trans_type: 1
});

watch(() => form.trans_type, (val) => {
    if (val === 2) {
        form.get_cid = '999999';
    } else {
        form.get_cid = '';
    }
});

// 修改点1：封装加载账户的函数
const loadAccounts = async () => {
    try {
        const res = await getMyAccounts(userId);
        // 过滤出正常的卡
        accounts.value = (res.data || []).filter(a => a.account_status === '正常');
    } catch (e) {
        console.error('账户加载失败', e);
    }
};

// 修改点2：初始化时调用
onMounted(() => {
    loadAccounts();
});

const onSubmit = async () => {
    if(!form.send_cid || !form.get_cid || form.amount <= 0) {
        return ElMessage.warning('请填写完整的交易信息');
    }

    try {
        const res = await transferMoney(form);
        
        if(res.status === 'success') {
            ElMessage.success('交易成功');
            // 重置表单
            form.amount = 0; 
            if(form.trans_type === 1) {
                form.get_cid = '';
            }
            
            // 修改点3：交易成功后，刷新账户余额
            loadAccounts();
            
        } else if (res.status === 'pending') {
            ElMessage.warning(res.msg);
            form.amount = 0;
            // 待审核状态虽然钱没扣（或者冻结了），也可以选择刷新一下
            loadAccounts(); 
        } else {
             ElMessage.error(res.msg || '交易失败');
        }
    } catch(err) {
        ElMessage.error(err.response?.data?.detail || '交易失败');
    }
};
</script>

<style scoped>
.page-container { display: flex; justify-content: center; padding-top: 20px; }
.box-card { width: 600px; }
.form-title { text-align: center; margin-bottom: 30px; color: #303133; }
</style>

