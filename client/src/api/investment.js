import request from './request';

export function getProducts(type) {
  return request({ url: '/investment/products', method: 'get', params: { ptype: type } });
}

export function purchase(data) {
  return request({ url: '/investment/purchase', method: 'post', data });
}

export function createDeposit(data) {
  return request({ url: '/investment/deposit', method: 'post', data });
}

export function getHoldings(userId) {
  return request({ url: `/investment/holdings/${userId}`, method: 'get' });
}

export function getDepositIncome(userId) {
  return request({ url: `/investment/deposit/income/${userId}`, method: 'get' });
}

export function getMyDeposits(userId) {
  return request({
    url: `/investment/deposits/${userId}`,
    method: 'get'
  });
}

export function getDepositRates() {
  return request({ url: '/investment/rates', method: 'get' });
}

export function sell(data) {
  return request({ url: '/investment/sell', method: 'post', data });
}

export function withdrawDeposit(data) {
  return request({ url: '/investment/deposit/withdraw', method: 'post', data });
}