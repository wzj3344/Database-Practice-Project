// test-auth.js
const http = require('http');

function testAuthAPI() {
  console.log('测试登录接口...\n');
  
  const postData = JSON.stringify({
    user_id: 'U001',     // 注意字段名是 user_id
    password: 'pass123',
    role: 'user'         // 必须字段
  });
  
  const options = {
    hostname: 'localhost',
    port: 8000,
    path: '/auth/login',  // 注意路径是 /auth/login
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };
  
  const req = http.request(options, (res) => {
    console.log(`状态码: ${res.statusCode}`);
    console.log('响应头:', res.headers);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      console.log('\n响应体:');
      try {
        const jsonData = JSON.parse(data);
        console.log(JSON.stringify(jsonData, null, 2));
      } catch (e) {
        console.log(data);
      }
    });
  });
  
  req.on('error', (err) => {
    console.error('请求错误:', err.message);
  });
  
  req.write(postData);
  req.end();
}

// 测试不同角色
function testDifferentRoles() {
  console.log('\n\n测试不同角色登录...');
  
  const testCases = [
    { user_id: 'U001', password: 'pass123', role: 'user', desc: '普通用户' },
    { user_id: 'U001', password: 'pass123', role: 'admin', desc: '普通用户尝试管理员登录' },
    { user_id: 'admin001', password: 'admin123', role: 'admin', desc: '管理员用户' },
    { user_id: 'U001', password: 'wrong', role: 'user', desc: '错误密码' },
    { user_id: 'U002', password: 'pass123', role: 'user', desc: '不存在的用户' }
  ];
  
  testCases.forEach((testCase, index) => {
    setTimeout(() => {
      console.log(`\n--- 测试 ${index + 1}: ${testCase.desc} ---`);
      
      const postData = JSON.stringify(testCase);
      const req = http.request({
        hostname: 'localhost',
        port: 8000,
        path: '/auth/login',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData)
        }
      }, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          try {
            const result = JSON.parse(data);
            console.log(`结果: ${result.status} - ${result.msg || '成功'}`);
            if (result.user_name) console.log(`用户名: ${result.user_name}`);
          } catch (e) {
            console.log('响应:', data);
          }
        });
      });
      
      req.on('error', (err) => {
        console.error('错误:', err.message);
      });
      
      req.write(postData);
      req.end();
    }, index * 500); // 间隔500ms发送请求
  });
}

// 运行测试
testAuthAPI();

// 3秒后运行多角色测试
setTimeout(testDifferentRoles, 3000);