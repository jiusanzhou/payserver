import { createServerSupabaseClient } from '@/lib/db/supabase'
import { NextResponse } from 'next/server'
import type { User } from '@supabase/supabase-js'

export type AuthResult = 
  | { authenticated: true; user: User }
  | { authenticated: false; response: NextResponse }

export async function requireAuth(): Promise<AuthResult> {
  const supabase = await createServerSupabaseClient()
  const { data: { user }, error } = await supabase.auth.getUser()

  if (error || !user) {
    return {
      authenticated: false,
      response: NextResponse.json(
        { error: 'Unauthorized', message: 'Authentication required' },
        { status: 401 }
      )
    }
  }

  return { authenticated: true, user }
}

export function unauthorized(message = 'Authentication required') {
  return NextResponse.json(
    { error: 'Unauthorized', message },
    { status: 401 }
  )
}

export function forbidden(message = 'Insufficient permissions') {
  return NextResponse.json(
    { error: 'Forbidden', message },
    { status: 403 }
  )
}

export function badRequest(message: string) {
  return NextResponse.json(
    { error: 'Bad Request', message },
    { status: 400 }
  )
}

export function notFound(message = 'Resource not found') {
  return NextResponse.json(
    { error: 'Not Found', message },
    { status: 404 }
  )
}

export function serverError(message = 'Internal server error') {
  return NextResponse.json(
    { error: 'Internal Server Error', message },
    { status: 500 }
  )
}
