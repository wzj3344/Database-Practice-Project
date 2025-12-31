import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import router from './router' // 引入路由
import ElementPlus from 'element-plus' // 引入 UI 库
import 'element-plus/dist/index.css' // 引入 UI 样式

const app = createApp(App)

app.use(router)
app.use(ElementPlus)
app.mount('#app')