<template>
  <el-container class="layout-container">
    <el-aside width="240px" class="aside">
      <div class="logo">
        <el-icon class="logo-icon"><OfficeBuilding /></el-icon>
        <span v-if="!isCollapse" class="logo-text">银行管理系统</span>
      </div>
      
      <el-menu
        :default-active="activeMenu"
        class="el-menu-vertical"
        background-color="#ffffff"
        text-color="#606266"
        active-text-color="#C20C0C"
        router
        :collapse="isCollapse"
      >
        <el-menu-item index="/admin/dashboard">
          <el-icon><Odometer /></el-icon>
          <span>首页</span>
        </el-menu-item>
        
        <el-menu-item index="/admin/users">
          <el-icon><CreditCard /></el-icon>
          <span>账户管理</span>
        </el-menu-item>

        <el-menu-item index="/admin/audit">
          <el-icon><Money /></el-icon>
          <span>业务审核</span>
        </el-menu-item>

        <el-menu-item index="/admin/products">
          <el-icon><DataLine /></el-icon>
          <span>理财产品</span>
        </el-menu-item>

        <el-menu-item index="/admin/funds">
          <el-icon><TrendCharts /></el-icon>
          <span>基金管理</span>
        </el-menu-item>

        <el-menu-item index="/admin/rates">
          <el-icon><DataAnalysis /></el-icon> <span>利率管理</span>
        </el-menu-item>
        
        <el-sub-menu index="system">
          <template #title>
            <el-icon><Setting /></el-icon>
            <span>系统设置</span>
          </template>
          <el-menu-item index="/admin/add_admin">添加管理员</el-menu-item>
          <el-menu-item index="/admin/password">修改密码</el-menu-item>
        </el-sub-menu>
      </el-menu>
    </el-aside>

    <el-container>
      <el-header class="header">
        <div class="header-left">
          <el-breadcrumb separator="/">
            <el-breadcrumb-item :to="{ path: '/admin/dashboard' }">首页</el-breadcrumb-item>
            <el-breadcrumb-item v-if="currentRouteName && currentRouteName !== '首页'">
              {{ currentRouteName }}
            </el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        <div class="header-right">
          <el-dropdown @command="handleCommand">
            <span class="user-info">
              <span class="welcome-text">管理员</span>
              <span class="username">{{ adminId }}</span>
              <el-avatar :size="32" class="avatar">A</el-avatar>
              <el-icon><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="logout" style="color: #f56c6c">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <el-main class="main-content">
        <router-view v-slot="{ Component }">
          <transition name="el-fade-in-linear" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { ref, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { 
  OfficeBuilding, Odometer, Money, DataLine, Setting, ArrowDown, TrendCharts, CreditCard, DataAnalysis
} from '@element-plus/icons-vue';

const route = useRoute();
const router = useRouter();
const adminId = localStorage.getItem('user_id') || 'Admin';
const isCollapse = ref(false);

const activeMenu = computed(() => route.path);
const currentRouteName = computed(() => route.meta.title);

const handleCommand = (command) => {
  if (command === 'logout') {
    localStorage.clear();
    router.push('/login');
  }
};
</script>

<style scoped>
.layout-container { height: 100vh; }

/* 侧边栏：改为白底 + 阴影 */
.aside {
  background-color: #ffffff;
  border-right: 1px solid #e6e6e6;
  box-shadow: 2px 0 8px rgba(0,0,0,0.02);
  z-index: 10;
  display: flex;
  flex-direction: column;
}

/* Logo：使用品牌红渐变 */
.logo {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  background: linear-gradient(135deg, #C20C0C 0%, #E60012 100%);
  color: #fff;
  font-size: 18px;
  font-weight: 600;
  box-shadow: 0 2px 4px rgba(194, 12, 12, 0.2);
}
.logo-icon { font-size: 24px; }

.el-menu-vertical { border-right: none; margin-top: 10px; }

/* 菜单项样式优化 */
:deep(.el-menu-item) {
  margin: 4px 10px;
  border-radius: 6px;
  height: 50px;
}
:deep(.el-menu-item.is-active) {
  background-color: #FEF0F0 !important; /* 浅红背景 */
  font-weight: 600;
  position: relative;
}
/* 选中时的左侧红条 */
:deep(.el-menu-item.is-active::before) {
  content: "";
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  width: 4px;
  height: 20px;
  background-color: #C20C0C;
  border-radius: 0 4px 4px 0;
}

.header {
  background-color: #fff;
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  box-shadow: 0 1px 4px rgba(0,21,41,0.05);
  z-index: 9;
}

.user-info {
  display: flex;
  align-items: center;
  cursor: pointer;
  padding: 5px 10px;
  border-radius: 20px;
  transition: background 0.3s;
}
.user-info:hover { background-color: #f5f7fa; }
.welcome-text { font-size: 12px; color: #909399; margin-right: 5px; }
.username { font-weight: 600; color: #303133; margin-right: 10px; }
.avatar { background-color: #C20C0C; color: #fff; font-size: 14px; font-weight: bold; }

.main-content {
  background-color: #f5f7fa;
  padding: 24px;
}
</style>