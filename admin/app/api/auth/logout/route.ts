import { NextResponse } from 'next/server'
import { createServerSupabaseClient } from '@/lib/db/supabase'

export async function POST() {
  const supabase = await createServerSupabaseClient()
  
  const { error } = await supabase.auth.signOut()

  if (error) {
    return NextResponse.json(
      { error: 'Failed to sign out' },
      { status: 500 }
    )
  }

  return NextResponse.json({ success: true })
}
