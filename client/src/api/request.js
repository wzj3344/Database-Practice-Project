import axios from 'axios';

const service = axios.create({
  baseURL: 'http://127.0.0.1:8000', 
  timeout: 5000
});

// 响应拦截器 (保持不变)
service.interceptors.response.use(
  response => response.data,
  error => {
    // 增加可选链防止 response 为空时报错
    console.error('API Error:', error.response?.data?.detail || error.message);
    return Promise.reject(error);
  }
);

export default service;