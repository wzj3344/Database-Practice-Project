<template>
  <div class="admin-header">
    <div class="left">
      <h3>银行管理系统后台</h3>
    </div>
    <div class="right">
      <el-dropdown @command="handleCommand">
        <span class="el-dropdown-link">
          欢迎, {{ adminId }} <el-icon class="el-icon--right"><arrow-down /></el-icon>
        </span>
        <template #dropdown>
          <el-dropdown-menu>
            <el-dropdown-item command="add_admin">添加管理员</el-dropdown-item>
            <el-dropdown-item command="password">更改密码</el-dropdown-item>
            <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
          </el-dropdown-menu>
        </template>
      </el-dropdown>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { ArrowDown } from '@element-plus/icons-vue';

const router = useRouter();
const adminId = localStorage.getItem('user_id') || 'Admin';

const handleCommand = (command) => {
  if (command === 'logout') {
    localStorage.clear();
    router.push('/login');
  } else if (command === 'password') {
    router.push('/admin/password');
  } else if (command === 'add_admin') {
    // 跳转到添加管理员页面
    router.push('/admin/add_admin');
  }
};
</script>

<style scoped>
.admin-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
  background-color: #fff;
  border-bottom: 1px solid #dcdfe6;
  height: 60px;
  margin-bottom: 20px;
}
.el-dropdown-link {
  cursor: pointer;
  color: #409EFF;
  display: flex;
  align-items: center;
}
</style>