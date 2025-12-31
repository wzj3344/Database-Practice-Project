import { createRouter, createWebHistory } from 'vue-router'
import Login from '../views/Login.vue'

// 布局
import AdminLayout from '../layout/AdminLayout.vue'
import UserLayout from '../layout/UserLayout.vue'

// 管理员页面
import AdminDashboard from '../views/admin/AdminDashboard.vue'
import AdminUsers from '../views/admin/UserManage.vue'
import AdminAudit from '../views/admin/Audit.vue'
import AdminProducts from '../views/admin/ProductManage.vue'
import AdminPassword from '../views/admin/ChangePassword.vue'
import AdminAdd from '../views/admin/AddAdmin.vue'
import AdminFunds from '../views/admin/FundManage.vue'
import AdminRates from '../views/admin/RateManage.vue'

// 用户页面
import UserDashboard from '../views/user/UserDashboard.vue'
import UserAccounts from '../views/user/MyAccounts.vue'
import UserTransfer from '../views/user/Transfer.vue'
import UserInvest from '../views/user/Invest.vue'
import UserHistory from '../views/user/History.vue'
import UserChangePassword from '../views/user/ChangePassword.vue'
import UserChangePhone from '../views/user/ChangePhone.vue'

const routes = [
  { path: '/', redirect: '/login' },
  { path: '/login', component: Login },
  
  // 普通用户路由
  {
    path: '/user',
    component: UserLayout,
    redirect: '/user/dashboard',
    children: [
        { path: 'dashboard', component: UserDashboard, meta: { title: '首页' } },
        { path: 'accounts', component: UserAccounts, meta: { title: '账户管理' } },
        { path: 'transfer', component: UserTransfer, meta: { title: '转账消费' } },
        { path: 'invest', component: UserInvest, meta: { title: '理财投资' } },
        { path: 'history', component: UserHistory, meta: { title: '交易查询' } },
        { path: 'password', component: UserChangePassword, meta: { title: '修改密码' } },
        { path: 'phone', component: UserChangePhone, meta: { title: '修改电话' } }
    ]
  },

  // 管理员路由
  { 
    path: '/admin', 
    component: AdminLayout,
    redirect: '/admin/dashboard',
    children: [
      { path: 'dashboard', component: AdminDashboard, meta: { title: '首页' } },
      { path: 'users', component: AdminUsers, meta: { title: '账户管理' } },
      { path: 'audit', component: AdminAudit, meta: { title: '业务审核' } },
      { path: 'products', component: AdminProducts, meta: { title: '理财产品' } },
      { path: 'funds', component: AdminFunds, meta: { title: '基金管理' } },
      { path: 'rates', component: AdminRates, meta: { title: '利率管理' } },
      { path: 'password', component: AdminPassword, meta: { title: '修改密码' } },
      { path: 'add_admin', component: AdminAdd, meta: { title: '添加管理员' } },
    ]
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router