<template>
  <div class="pwd-container">
    <el-card class="box-card" shadow="never">
      <template #header>
        <div class="card-header">
          <span>修改登录密码</span>
        </div>
      </template>
      
      <el-form :model="form" label-width="100px" style="max-width: 460px; margin: 0 auto; padding-top: 20px">
        <el-form-item label="用户ID">
           <el-input v-model="form.uid" disabled prefix-icon="User" />
        </el-form-item>
        
        <el-form-item label="预留手机号">
          <el-input v-model="form.phone" placeholder="请输入开户时预留的手机号" prefix-icon="Iphone" />
        </el-form-item>

        <el-form-item label="验证码">
          <div style="display: flex; width: 100%">
            <el-input v-model="form.code" placeholder="4位验证码" prefix-icon="Key" style="flex: 1; margin-right: 10px" />
            <el-button type="primary" :disabled="isCounting" @click="handleSendCode">
              {{ isCounting ? `${count}s后重发` : '发送验证码' }}
            </el-button>
          </div>
        </el-form-item>

        <el-form-item label="新密码">
          <el-input v-model="form.new_password" type="password" placeholder="设置新密码" show-password prefix-icon="Lock" />
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
import { sendVerifyCode, updatePasswordSecure } from '@/api/auth';
import { ElMessage } from 'element-plus';
import { useRouter } from 'vue-router';
import { User, Iphone, Key, Lock } from '@element-plus/icons-vue';

const router = useRouter();
const form = reactive({ uid: '', phone: '', code: '', new_password: '' });
const loading = ref(false);

// 倒计时逻辑
const isCounting = ref(false);
const count = ref(60);
let timer = null;

onMounted(() => {
    form.uid = localStorage.getItem('user_id');
});

const startCountDown = () => {
    isCounting.value = true;
    count.value = 60;
    timer = setInterval(() => {
        if (count.value > 0) {
            count.value--;
        } else {
            clearInterval(timer);
            isCounting.value = false;
        }
    }, 1000);
};

const handleSendCode = async () => {
    if (!form.phone) return ElMessage.warning('请输入预留手机号');
    if (form.phone.length !== 11) return ElMessage.warning('手机号格式不正确');

    try {
        const res = await sendVerifyCode({ uid: form.uid, phone: form.phone });
        if (res.status === 'success') {
            ElMessage.success('验证码已发送，请留意服务器终端');
            startCountDown();
        } else {
            ElMessage.error(res.msg || '手机号验证失败');
        }
    } catch (e) {
        ElMessage.error('发送请求失败');
    }
};

const onSubmit = async () => {
    if(!form.code || !form.new_password) return ElMessage.warning('请填写完整信息');
    
    loading.value = true;
    try {
        const res = await updatePasswordSecure(form);
        if(res.status === 'success') {
            ElMessage.success('密码修改成功，请重新登录');
            localStorage.clear();
            router.push('/login');
        } else {
            ElMessage.error(res.msg || '验证码错误');
        }
    } catch(e) {
        ElMessage.error('修改失败');
    } finally {
        loading.value = false;
    }
};
</script>

<style scoped>
.pwd-container { padding: 0; }
.box-card { border-radius: 8px; min-height: 500px; }
.card-header { font-size: 16px; font-weight: bold; color: #303133; }
</style>