/**
 * PayServer Errors
 * Mirrors Go server errors
 */

export class PayServerError extends Error {
  code: number
  
  constructor(message: string, code: number = 500) {
    super(message)
    this.code = code
    this.name = "PayServerError"
  }
}

export const Errors = {
  OrderNumberExists: new PayServerError("order number already exists", 400),
  UnsupportedPayMethod: new PayServerError("unsupported pay method", 400),
  AppNotFound: new PayServerError("unknown app id", 404),
  PendingOrderLimit: new PayServerError("pending order limit reached", 429),
  NoAvailableAgent: new PayServerError("no available agent", 503),
  SchedPriceBusy: new PayServerError("all price slots busy", 503),
  AgentNotFound: new PayServerError("agent not found", 404),
  OrderNotFound: new PayServerError("order not found", 404),
  RecordNotFound: new PayServerError("record not found", 404),
  CallbackNotFound: new PayServerError("callback not found", 404),
  InvalidTicket: new PayServerError("invalid or used ticket", 400),
  LimitPendingAgent: new PayServerError("pending agent count limit", 429),
  MissingObjectID: new PayServerError("missing object id", 400),
}
