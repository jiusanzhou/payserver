export type PayType = "wechat" | "alipay"

export const PayTypeLabel: Record<PayType, string> = {
  wechat: "微信支付",
  alipay: "支付宝",
}

export const PayTypeColor: Record<PayType, string> = {
  wechat: "bg-green-100 text-green-800",
  alipay: "bg-blue-100 text-blue-800",
}

export interface PayRecord {
  id: number
  uid: string
  agent_uid: string
  type: PayType
  number: string // platform transaction number
  amount: number // cents
  timestamp: string // agent local time
  account_uid: string
  external: string // JSON object
  create_at: string
  update_at: string
}

export interface PayRecordCreateInput {
  agent_uid: string
  type: PayType
  number: string
  amount: number
  timestamp: string
  account_uid?: string
}

export interface PayRecordListParams {
  page?: number
  limit?: number
  agent_uid?: string
  type?: PayType
  start_time?: string
  end_time?: string
}

export interface PayRecordListResponse {
  records: PayRecord[]
  total: number
  page: number
  limit: number
}
