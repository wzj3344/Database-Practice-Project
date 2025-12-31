import request from './request';

export function getMyAccounts(userId) {
  return request({ url: `/account/list/${userId}`, method: 'get' });
}

export function openAccount(data) {
  return request({ url: '/account/open', method: 'post', data });
}

// 新增：改变卡状态
export function changeCardStatus(data) {
  return request({ url: '/account/change_status', method: 'post', data });
}