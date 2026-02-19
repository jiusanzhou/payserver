/**
 * PayServer Config
 * Mirrors Go server/config
 */

export interface ServerConfig {
  name: string
  host: string
  version: string
  db: string
  debug: boolean
  
  // Order defaults
  expireIn: number
  priceFloor: number
  priceCeil: number
  maxPendingOrder: number
  maxPendingAgent: number
}

export function getServerConfig(): ServerConfig {
  return {
    name: process.env.PAYSERVER_NAME || "PayServer",
    host: process.env.PAYSERVER_API_URL || "",
    version: process.env.PAYSERVER_VERSION || "1.0.0",
    db: process.env.DATABASE_URL || "",
    debug: process.env.PAYSERVER_DEBUG === "true",
    
    expireIn: parseInt(process.env.PAYSERVER_EXPIRE_IN || "300"),
    priceFloor: parseInt(process.env.PAYSERVER_PRICE_FLOOR || "2"),
    priceCeil: parseInt(process.env.PAYSERVER_PRICE_CEIL || "2"),
    maxPendingOrder: parseInt(process.env.PAYSERVER_MAX_PENDING_ORDER || "10"),
    maxPendingAgent: parseInt(process.env.PAYSERVER_MAX_PENDING_AGENT || "5"),
  }
}
