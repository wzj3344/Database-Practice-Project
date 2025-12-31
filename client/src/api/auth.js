import request from './request';

// 用户/管理员登录
export function login(data) {
  return request({
    url: '/auth/login',
    method: 'post',
    data // 包含 { user_id, password, role }
  });
}

// 用户注册
export function register(data) {
  return request({
    url: '/auth/register',
    method: 'post',
    data // 包含 { uid, name, id_card, password, phone }
  });
}

// 新增：重置密码
export function resetPassword(data) {
  return request({
    url: '/auth/reset_password',
    method: 'post',
    data // 包含 { uid, new_password }
  });
}

// 发送验证码 (校验手机号)
export function sendVerifyCode(data) {
  return request({
    url: '/auth/send_verify_code',
    method: 'post',
    data // { uid, phone }
  });
}

// 验证并修改密码
export function updatePasswordSecure(data) {
  return request({
    url: '/auth/update_password_secure',
    method: 'post',
    data // { uid, new_password, code }
  });
}

// 新增：修改手机号
export function updatePhone(data) {
  return request({
    url: '/auth/update_phone',
    method: 'post',
    data // { uid, password, new_phone }
  });
}