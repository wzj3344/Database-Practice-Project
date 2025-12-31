import request from './request';

export function transferMoney(data) {
  return request({ url: '/transaction/transfer', method: 'post', data });
}

export function getHistory(userId) {
  return request({ url: `/transaction/history/${userId}`, method: 'get' });
}

export function getBills(userId) {
  return request({ url: `/transaction/bills/${userId}`, method: 'get' });
}