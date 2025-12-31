<template>
  <div>
    <div class="form-container">
      <el-card class="box-card">
        <template #header>
          <div class="card-header">
            <span>添加新的管理员</span>
            <el-button style="float: right; padding: 3px 0" type="text" @click="$router.push('/admin/dashboard')">返回主页</el-button>
          </div>
        </template>
        <el-form :model="form" label-width="100px">
          <el-form-item label="管理员ID">
            <el-input v-model="form.aid" placeholder="请输入新管理员账号" />
          </el-form-item>
          <el-form-item label="登录密码">
            <el-input v-model="form.password" type="password" placeholder="设置初始密码" show-password />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="onSubmit">确认添加</el-button>
          </el-form-item>
        </el-form>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { reactive } from 'vue';
import AdminHeader from '@/components/AdminHeader.vue';
import axios from '@/api/request';
import { ElMessage } from 'element-plus';
import { useRouter } from 'vue-router';

const router = useRouter();
const form = reactive({ aid: '', password: '' });

const onSubmit = async () => {
  if(!form.aid || !form.password) return ElMessage.warning('请填写完整信息');
  
  try {
    const res = await axios.post('/admin/add', form);
    
    // 修改核心：判断 status
    if (res.status === 'success') {
      ElMessage.success('管理员添加成功');
      // 清空表单
      form.aid = '';
      form.password = '';
    } else {
      // 显示后端返回的错误信息（如：管理员ID已存在...）
      ElMessage.error(res.msg || '添加失败');
    }
  } catch (err) {
    // 捕获网络或其他异常
    ElMessage.error('请求异常: ' + (err.response?.data?.detail || err.message));
  }
};
</script>

<style scoped>
.form-container { display: flex; justify-content: center; margin-top: 50px; }
.box-card { width: 500px; }
</style>