import request from './request';

// 获取待审核交易列表
export function getPendingAudits() {
  return request({
    url: '/admin/audit/list',
    method: 'get'
  });
}

// 审核操作（通过/驳回）
export function auditAction(data) {
  return request({
    url: '/admin/audit/action',
    method: 'post',
    data // 包含 { tid, result, admin_id }
  });
}

// 发布理财产品
export function addProduct(data) {
  return request({
    url: '/admin/product/add',
    method: 'post',
    data // 包含 { pid, pname, pworth, pleast, prisk }
  });
}

export function getFunds() {
  return request({
    url: '/admin/fund/list',
    method: 'get'
  });
}

export function addFund(data) {
  return request({
    url: '/admin/fund/add',
    method: 'post',
    data // { fid, fname, fworth, fleast, frisk }
  });
}

export function updateFund(data) {
  return request({
    url: '/admin/fund/update',
    method: 'post',
    data // { fid, fname, fstatus, fworth, frisk }
  });
}

export function deleteFund(data) {
  return request({
    url: '/admin/fund/delete',
    method: 'post',
    data // { fid }
  });
}

export function updateDepositRate(data) {
  return request({ url: '/admin/rate/update', method: 'post', data });
}