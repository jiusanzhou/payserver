/**
 * PayServer Utils
 * Mirrors Go server/utils
 */

export function generateUUID(): string {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0
    const v = c === "x" ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}

/**
 * Generate price floats for order scheduling
 * Returns array like [0, 1, -1, 2, -2, ...] within floor/ceil bounds
 */
export function genPriceFloats(floor: number, ceil: number): number[] {
  const floats: number[] = [0]
  const max = Math.max(floor, ceil)
  
  for (let i = 1; i <= max; i++) {
    if (i <= ceil) floats.push(i)
    if (i <= floor) floats.push(-i)
  }
  
  return floats
}

/**
 * Weighted random selection
 */
export function selectByWeight<T>(items: T[], weights: number[]): T | null {
  if (items.length === 0) return null
  if (items.length === 1) return items[0]
  
  const totalWeight = weights.reduce((sum, w) => sum + Math.max(1, w), 0)
  let r = Math.random() * totalWeight
  
  for (let i = 0; i < items.length; i++) {
    const w = Math.max(1, weights[i])
    r -= w
    if (r <= 0) return items[i]
  }
  
  return items[items.length - 1]
}

/**
 * Format price from cents to display string
 */
export function formatPrice(cents: number): string {
  return `¥${(cents / 100).toFixed(2)}`
}
