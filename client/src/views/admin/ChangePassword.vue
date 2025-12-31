<template>
  <div>
    <div class="pwd-container">
      <el-card class="box-card">
        <template #header>
          <div class="card-header">
            <span>修改管理员密码</span>
            <el-button style="float: right; padding: 3px 0" type="text" @click="$router.push('/admin/dashboard')">返回主页</el-button>
          </div>
        </template>
        <el-form :model="form" label-width="100px">
          <el-form-item label="管理员ID">
             <el-input v-model="form.uid" disabled />
          </el-form-item>
          <el-form-item label="新密码">
            <el-input v-model="form.new_password" type="password" show-password />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="onSubmit">确认修改</el-button>
          </el-form-item>
        </el-form>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { reactive, onMounted } from 'vue';
import AdminHeader from '@/components/AdminHeader.vue';
import { resetPassword } from '@/api/auth';
import { ElMessage } from 'element-plus';
import { useRouter } from 'vue-router';

const router = useRouter();
const form = reactive({ uid: '', new_password: '' });

onMounted(() => {
    form.uid = localStorage.getItem('user_id');
});

const onSubmit = async () => {
    if(!form.new_password) return ElMessage.warning('请输入新密码');
    try {
        const res = await resetPassword(form);
        if(res.status === 'success') {
            ElMessage.success('密码修改成功，请重新登录');
            localStorage.clear();
            router.push('/login');
        } else {
            ElMessage.error(res.msg);
        }
    } catch(e) {
        ElMessage.error('修改失败');
    }
};
</script>

<style scoped>
.pwd-container { display: flex; justify-content: center; margin-top: 50px; }
.box-card { width: 500px; }
</style>