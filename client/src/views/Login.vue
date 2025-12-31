<template>
  <div class="login-container">
    <div class="bg-circle circle-1"></div>
    <div class="bg-circle circle-2"></div>

    <div class="login-content">
      <div class="brand-section">
        <h1 class="system-title">BANK SYSTEM</h1>
        <p class="system-subtitle">安全 · 便捷 · 智能 · 财富</p>
      </div>

      <el-card class="login-card">
        <h2 class="form-title">欢迎登录</h2>
        <el-tabs v-model="activeTab" class="custom-tabs">
          <el-tab-pane label="个人用户" name="user">
            <el-form :model="form" size="large" @keyup.enter="handleLogin('user')">
              <el-form-item>
                <el-input v-model="form.user_id" placeholder="请输入用户ID" :prefix-icon="User" />
              </el-form-item>
              <el-form-item>
                <el-input v-model="form.password" type="password" placeholder="请输入密码" :prefix-icon="Lock" show-password />
              </el-form-item>
              <el-button type="primary" class="login-btn" @click="handleLogin('user')" :loading="loading">立即登录</el-button>
              
              <div class="login-tools">
                <span class="register-link" @click="showRegister = true">注册新账户</span>
                <span class="forget-link" @click="openResetDialog">忘记密码?</span>
              </div>
            </el-form>
          </el-tab-pane>

          <el-tab-pane label="管理员" name="admin">
            <el-form :model="form" size="large" @keyup.enter="handleLogin('admin')">
              <el-form-item>
                <el-input v-model="form.user_id" placeholder="管理员账号" :prefix-icon="User" />
              </el-form-item>
              <el-form-item>
                <el-input v-model="form.password" type="password" placeholder="管理密码" :prefix-icon="Lock" show-password />
              </el-form-item>
              <el-button type="danger" class="login-btn" @click="handleLogin('admin')" :loading="loading">管理员登录</el-button>
            </el-form>
          </el-tab-pane>
        </el-tabs>
      </el-card>
    </div>

    <el-dialog v-model="showRegister" title="用户注册" width="400px" align-center>
        <el-form :model="regForm" label-width="80px">
            <el-form-item label="用户ID"><el-input v-model="regForm.uid" placeholder="自定义ID (如: U001)" /></el-form-item>
            <el-form-item label="姓名"><el-input v-model="regForm.name" placeholder="真实姓名" /></el-form-item>
            <el-form-item label="身份证"><el-input v-model="regForm.id_card" placeholder="18位身份证号" /></el-form-item>
            <el-form-item label="密码"><el-input v-model="regForm.password" type="password" show-password /></el-form-item>
            <el-form-item label="手机号"><el-input v-model="regForm.phone" placeholder="11位手机号" /></el-form-item>
        </el-form>
        <template #footer>
            <el-button @click="showRegister = false">取消</el-button>
            <el-button type="primary" @click="handleRegister">确认注册</el-button>
        </template>
    </el-dialog>

    <el-dialog v-model="showReset" title="安全重置密码" width="420px" align-center>
        <el-form :model="resetForm" label-width="80px">
            <el-form-item label="用户ID"><el-input v-model="resetForm.uid" :prefix-icon="User" /></el-form-item>
            <el-form-item label="手机号"><el-input v-model="resetForm.phone" :prefix-icon="Iphone" /></el-form-item>
            <el-form-item label="验证码">
                <div style="display: flex; width: 100%">
                    <el-input v-model="resetForm.code" :prefix-icon="Key" style="flex: 1; margin-right: 10px" />
                    <el-button type="primary" :disabled="isCounting" @click="handleSendCode">
                        {{ isCounting ? `${count}s` : '发送' }}
                    </el-button>
                </div>
            </el-form-item>
            <el-form-item label="新密码"><el-input v-model="resetForm.new_password" type="password" show-password :prefix-icon="Lock" /></el-form-item>
        </el-form>
        <template #footer>
            <el-button @click="showReset = false">取消</el-button>
            <el-button type="warning" @click="handleReset" :loading="resetLoading">重置</el-button>
        </template>
    </el-dialog>
  </div>
</template>

<script setup>
// Script 逻辑完全保持不变，直接复用原文件中的 import 和 logic
import { reactive, ref } from 'vue';
import { useRouter } from 'vue-router';
import { login, register, sendVerifyCode, updatePasswordSecure } from '@/api/auth';
import { ElMessage } from 'element-plus';
import { User, Lock, Iphone, Key } from '@element-plus/icons-vue';

const router = useRouter();
const activeTab = ref('user');
const loading = ref(false);
const resetLoading = ref(false);
const form = reactive({ user_id: '', password: '' });
const showRegister = ref(false);
const regForm = reactive({ uid: '', name: '', id_card: '', password: '', phone: '' });
const showReset = ref(false);
const resetForm = reactive({ uid: '', phone: '', code: '', new_password: '' });
const isCounting = ref(false);
const count = ref(60);
let timer = null;

const openResetDialog = () => {
    resetForm.uid = ''; resetForm.phone = ''; resetForm.code = ''; resetForm.new_password = '';
    isCounting.value = false; count.value = 60;
    if(timer) clearInterval(timer);
    showReset.value = true;
};

const handleLogin = async (role) => {
  if(!form.user_id || !form.password) return ElMessage.warning('请输入账号和密码');
  loading.value = true;
  try {
    const res = await login({ ...form, role });
    if (res.status === 'success') {
      localStorage.setItem('user_id', res.user_id);
      localStorage.setItem('role', res.role);
      localStorage.setItem('user_name', res.user_name); 
      ElMessage.success('登录成功');
      role === 'admin' ? router.push('/admin/dashboard') : router.push('/user/dashboard');
    } else {
      ElMessage.error(res.msg || '登录失败');
    }
  } catch (e) { ElMessage.error('登录请求异常'); } 
  finally { loading.value = false; }
};

const handleRegister = async () => {
  if(!regForm.uid || !regForm.name || !regForm.id_card || !regForm.password || !regForm.phone) return ElMessage.warning('请补全注册信息');
  try {
    const res = await register(regForm);
    if (res.status === 'success') {
      ElMessage.success('注册成功，请登录');
      showRegister.value = false;
      regForm.uid = ''; regForm.name = ''; regForm.id_card = ''; regForm.password = ''; regForm.phone = '';
    } else { ElMessage.error(res.msg || '注册失败'); }
  } catch (e) { ElMessage.error('注册异常'); }
};

const handleSendCode = async () => {
    if (!resetForm.uid || !resetForm.phone) return ElMessage.warning('请填写ID和手机号');
    try {
        const res = await sendVerifyCode({ uid: resetForm.uid, phone: resetForm.phone });
        if (res.status === 'success') {
            ElMessage.success('验证码已发送');
            isCounting.value = true; count.value = 60;
            timer = setInterval(() => { count.value > 0 ? count.value-- : (clearInterval(timer), isCounting.value = false) }, 1000);
        } else { ElMessage.error(res.msg); }
    } catch (e) { ElMessage.error('请求失败'); }
};

const handleReset = async () => {
  if(!resetForm.code || !resetForm.new_password) return ElMessage.warning('请填写完整');
  resetLoading.value = true;
  try {
    const res = await updatePasswordSecure(resetForm);
    res.status === 'success' ? (ElMessage.success('重置成功'), showReset.value = false) : ElMessage.error(res.msg);
  } catch (e) { ElMessage.error('异常'); } 
  finally { resetLoading.value = false; }
};
</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  /* 红色渐变背景 */
  background: linear-gradient(135deg, #f5f7fa 0%, #ffe6e6 100%);
  position: relative;
  overflow: hidden;
}

/* 装饰性背景圆 */
.bg-circle {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.6;
}
.circle-1 {
  width: 400px;
  height: 400px;
  background: #C20C0C;
  top: -100px;
  right: -100px;
}
.circle-2 {
  width: 300px;
  height: 300px;
  background: #ff9999;
  bottom: -50px;
  left: -50px;
}

.login-content {
  display: flex;
  align-items: center;
  gap: 80px;
  z-index: 1;
}

.brand-section {
  color: #303133;
}
.system-title {
  font-size: 48px;
  font-weight: 800;
  color: #C20C0C;
  margin-bottom: 10px;
  letter-spacing: 2px;
}
.system-subtitle {
  font-size: 20px;
  color: #606266;
  letter-spacing: 5px;
}

.login-card {
  width: 400px;
  border-radius: 12px;
  /* 玻璃拟态 */
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.5);
  box-shadow: 0 10px 30px rgba(194, 12, 12, 0.1) !important;
  padding: 10px;
}

.form-title {
  text-align: center;
  margin-bottom: 25px;
  color: #303133;
  font-weight: 600;
}

.login-btn {
  width: 100%;
  font-size: 16px;
  padding: 20px 0;
  margin-top: 10px;
  letter-spacing: 2px;
  background: linear-gradient(90deg, #C20C0C, #ff4d4d);
  border: none;
}
.login-btn:hover {
  background: linear-gradient(90deg, #b30000, #e60000);
  opacity: 0.9;
}

.login-tools {
  margin-top: 15px;
  display: flex;
  justify-content: space-between;
  font-size: 14px;
}
.register-link {
  color: #C20C0C;
  cursor: pointer;
  font-weight: 500;
}
.forget-link {
  color: #909399;
  cursor: pointer;
}
.register-link:hover, .forget-link:hover { text-decoration: underline; }

/* 调整 Tabs 样式 */
:deep(.el-tabs__item.is-active) { color: #C20C0C !important; }
:deep(.el-tabs__active-bar) { background-color: #C20C0C !important; }
:deep(.el-input__wrapper.is-focus) { box-shadow: 0 0 0 1px #C20C0C inset !important; }
</style>