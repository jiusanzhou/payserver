export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      orders: {
        Row: {
          id: number
          uid: string
          app_id: string
          o_number: string
          o_name: string
          o_price: number
          o_redirect_url: string
          o_external: string
          expires_in: number
          qr_data: string
          qr_image_url: string
          sched_agent_uid: string
          sched_pay_type: string
          sched_price: number
          pay_record_uid: string | null
          status: number
          create_at: string
          update_at: string
          deleted_at: string | null
        }
        Insert: {
          app_id: string
          o_number: string
          o_name: string
          o_price: number
          o_redirect_url: string
          o_external: string
          expires_in: number
          qr_data: string
          qr_image_url: string
          sched_agent_uid: string
          sched_pay_type: string
          sched_price: number
          pay_record_uid?: string | null
          status: number
          deleted_at?: string | null
        }
        Update: {
          app_id?: string
          o_number?: string
          o_name?: string
          o_price?: number
          o_redirect_url?: string
          o_external?: string
          expires_in?: number
          qr_data?: string
          qr_image_url?: string
          sched_agent_uid?: string
          sched_pay_type?: string
          sched_price?: number
          pay_record_uid?: string | null
          status?: number
          deleted_at?: string | null
        }
      }
      agents: {
        Row: {
          id: number
          uid: string
          device_id: string
          pay_types: string
          heartbeat_at: string
          status: number
          ticket: string
          device_info: string
          external: string
          create_at: string
          update_at: string
          deleted_at: string | null
        }
        Insert: {
          device_id: string
          pay_types: string
          heartbeat_at: string
          status: number
          ticket: string
          device_info: string
          external: string
          deleted_at?: string | null
        }
        Update: {
          device_id?: string
          pay_types?: string
          heartbeat_at?: string
          status?: number
          ticket?: string
          device_info?: string
          external?: string
          deleted_at?: string | null
        }
      }
      apps: {
        Row: {
          id: number
          uid: string
          name: string
          description: string
          callback_url: string
          secret: string
          aes_key: string
          price_floor: number
          price_ceil: number
          expire_in: number
          max_pendding_order: number
          user_uid: string
          create_at: string
          update_at: string
          deleted_at: string | null
        }
        Insert: {
          name: string
          description: string
          callback_url: string
          secret: string
          aes_key: string
          price_floor: number
          price_ceil: number
          expire_in: number
          max_pendding_order: number
          user_uid: string
          deleted_at?: string | null
        }
        Update: {
          name?: string
          description?: string
          callback_url?: string
          secret?: string
          aes_key?: string
          price_floor?: number
          price_ceil?: number
          expire_in?: number
          max_pendding_order?: number
          user_uid?: string
          deleted_at?: string | null
        }
      }
      pay_records: {
        Row: {
          id: number
          uid: string
          agent_uid: string
          type: string
          number: string
          amount: number
          timestamp: string
          account_uid: string
          external: string
          create_at: string
          update_at: string
          deleted_at: string | null
        }
        Insert: {
          agent_uid: string
          type: string
          number: string
          amount: number
          timestamp: string
          account_uid: string
          external: string
          deleted_at?: string | null
        }
        Update: {
          agent_uid?: string
          type?: string
          number?: string
          amount?: number
          timestamp?: string
          account_uid?: string
          external?: string
          deleted_at?: string | null
        }
      }
      users: {
        Row: {
          id: number
          uid: string
          username: string
          email: string
          role: string
          create_at: string
          update_at: string
          deleted_at: string | null
        }
        Insert: {
          username: string
          email: string
          role: string
          deleted_at?: string | null
        }
        Update: {
          username?: string
          email?: string
          role?: string
          deleted_at?: string | null
        }
      }
      app_agents: {
        Row: {
          id: number
          app_uid: string
          agent_uid: string
          weight: number
          created_at: string
          deleted_at: string | null
        }
        Insert: {
          app_uid: string
          agent_uid: string
          weight: number
          deleted_at?: string | null
        }
        Update: {
          app_uid?: string
          agent_uid?: string
          weight?: number
          deleted_at?: string | null
        }
      }
    }
    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: Record<string, never>
  }
}
