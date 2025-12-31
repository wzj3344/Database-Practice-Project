<template>
  <div class="pwd-container">
    <el-card class="box-card" shadow="never">
      <template #header>
        <div class="card-header">
          <span>修改预留手机号</span>
        </div>
      </template>
      
      <el-form :model="form" label-width="100px" style="max-width: 460px; margin: 0 auto; padding-top: 20px">
        <el-form-item label="用户ID">
           <el-input v-model="form.uid" disabled prefix-icon="User" />
        </el-form-item>
        
        <el-form-item label="登录密码">
          <el-input 
            v-model="form.password" 
            type="password" 
            placeholder="验证身份需要输入登录密码" 
            show-password 
            prefix-icon="Lock" 
          />
        </el-form-item>

        <el-form-item label="新手机号">
          <el-input 
            v-model="form.new_phone" 
            placeholder="请输入新的11位手机号" 
            prefix-icon="Iphone" 
          />
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="onSubmit" style="width: 100%" :loading="loading">确认修改</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { reactive, ref, onMounted } from 'vue';
import { updatePhone } from '@/api/auth'; // 引入刚才写的API
import { ElMessage } from 'element-plus';
import { User, Lock, Iphone } from '@element-plus/icons-vue';

const form = reactive({ uid: '', password: '', new_phone: '' });
const loading = ref(false);

onMounted(() => {
    form.uid = localStorage.getItem('user_id');
});

const onSubmit = async () => {
    if(!form.password || !form.new_phone) return ElMessage.warning('请填写完整信息');
    
    // 前端校验手机号格式
    const phoneRegex = /^\d{11}$/;
    if (!phoneRegex.test(form.new_phone)) {
        return ElMessage.warning('新手机号格式不正确，请输入11位数字');
    }
    
    loading.value = true;
    try {
        const res = await updatePhone(form);
        if(res.status === 'success') {
            ElMessage.success('手机号修改成功');
            // 清空敏感输入
            form.password = '';
            form.new_phone = '';
        } else {
            // 显示后端返回的错误（如密码错误、手机号已存在）
            ElMessage.error(res.msg);
        }
    } catch(e) {
        ElMessage.error('修改请求失败');
    } finally {
        loading.value = false;
    }
};
</script>

<style scoped>
.pwd-container { padding: 0; }
.box-card { border-radius: 8px; min-height: 400px; }
.card-header { font-size: 16px; font-weight: bold; color: #303133; }
</style>